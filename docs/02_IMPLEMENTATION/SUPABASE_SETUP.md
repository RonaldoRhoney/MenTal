# MENTAL — Guia de provisionamento do Supabase real

Status: preparado por Claude Code, execução manual por Rhoney (conta
externa — fora do que o Claude Code pode fazer sozinho). Objetivo: sair do
modo `DEV_INSECURE` (`backend/app/auth.py`) para autenticação real,
conforme `ARCHITECTURE.md` §4 e autorizado por Rhoney em 2026-08-19.

## 1. O que Rhoney precisa fazer no painel do Supabase

1. Criar conta/projeto em [supabase.com](https://supabase.com) — decidir
   se usa a conta pessoal já usada por outros produtos RhoneyInc (auth
   compartilhada, `MENTAL_KICKOFF.md` §2) ou uma organização própria.
   **Confirmar antes**: o tier free do Supabase não exige cartão para
   começar, mas registre aqui se algum limite (tamanho de banco, MAUs de
   auth) puder empurrar para um plano pago — mesmo rigor da regra
   Zero-Cost API já aplicado ao Render em `ARCHITECTURE.md` §3.
2. Anotar, do painel do projeto (Settings → API):
   - `Project URL` (ex.: `https://xxxx.supabase.co`)
   - `anon public key` (para o cliente Flutter)
   - `service_role key` (**nunca** vai para o cliente Flutter — só backend,
     se algum dia for necessário chamar a API admin do Supabase)
3. Anotar, de Settings → API → JWT Settings:
   - `JWT Secret` — vira a variável `SUPABASE_JWT_SECRET` do backend
     (já implementado e testado em `backend/app/auth.py`, só precisa do
     valor real).
4. Rodar `backend/migrations/001_initial_schema.sql` no SQL Editor do
   projeto — cria o schema `mental` com as 11 tabelas e faz seed dos 4
   territórios (sem desafios ainda — conteúdo é etapa separada,
   `RISKS_AND_OPEN_DECISIONS.md` §2, curadoria manual antes de produção).
5. Método de login: **decisão ainda em aberto**, não travada em nenhum
   documento de Foundation. Opções padrão do Supabase Auth: email/senha,
   magic link, OAuth (Google, Apple). Dado o público misto incluindo
   criança (`FAMILY_SAFETY.md`), OAuth de terceiro tem implicação de
   coleta de dado a avaliar — não decidir isso sozinho no código, esperar
   orientação de Rhoney antes de configurar providers no painel.

## 2. O que muda no backend quando as credenciais existirem

Nenhuma mudança de código é necessária para o caminho feliz — já está
pronto e coberto por `auth.py`:

```bash
export SUPABASE_JWT_SECRET="<JWT Secret do painel>"
export MENTAL_DATABASE_URL="<connection string do Supabase Postgres>"
```

Com `SUPABASE_JWT_SECRET` definido, `get_current_user_id` (`auth.py`) para
de aceitar token como `user_id` em texto puro e passa a validar o JWT real
via `pyjwt`, extraindo `sub` (o `user_id` do Supabase Auth).

## 3. Ajuste de tipo pendente — bloqueante antes de apontar para Postgres real

**Gap identificado ao escrever este guia, não resolvido ainda**: os
modelos SQLAlchemy (`backend/app/models.py`) declaram `user_id` como
`String` genérico, porque o desenvolvimento local usa SQLite (sem tipo
`UUID` nativo). O `migrations/001_initial_schema.sql` já declara `user_id`
corretamente como `uuid references auth.users(id)` no Postgres real. Essa
divergência de tipo entre o schema real (uuid) e o que o SQLAlchemy espera
(string genérica) pode causar comparação incorreta entre o `sub` do JWT
(string) e o valor lido do banco (objeto `UUID` do driver `psycopg`).

Antes de apontar `MENTAL_DATABASE_URL` para o Supabase de verdade, alguém
precisa: trocar as colunas `user_id` de `String` para
`sqlalchemy.dialects.postgresql.UUID` nos models, ou forçar
`str(row.user_id)` em todo ponto de comparação — e testar contra um banco
Postgres real (não só SQLite) antes de confiar. Não fiz essa mudança agora
porque não há projeto Postgres real disponível para testar contra — mudar
o tipo sem poder validar seria pior do que deixar documentado.

## 4. `Base.metadata.create_all()` precisa ser desligado em produção

`backend/app/main.py` chama `Base.metadata.create_all(bind=engine)` no
startup — conveniente para SQLite local, mas **não deve rodar contra o
Supabase real**: o schema já é criado pela migration SQL (§1.4), e deixar
o `create_all` ativo arrisca o SQLAlchemy tentar recriar/alterar tabelas
por fora do controle da migration. Antes de apontar para produção,
condicionar essa chamada a um flag de ambiente (ex.: só roda se
`MENTAL_DATABASE_URL` começa com `sqlite`).

## 5. O que muda no cliente Flutter

Ainda **não implementado** neste slice (aguardando as credenciais reais
antes de escrever o código de integração final, e sem Flutter SDK neste
ambiente para validar de qualquer forma — mesma limitação já registrada em
`client/README.md`). Plano, para quando as credenciais existirem:

1. Adicionar `supabase_flutter` ao `pubspec.yaml`.
2. Inicializar `Supabase.initialize(url: ..., anonKey: ...)` em `main.dart`.
3. Trocar `SessionStore` (UUID local) por login real (tela de
   email/magic-link/OAuth, a definir por §1.5) e usar
   `Supabase.instance.client.auth.currentSession?.accessToken` como o
   token Bearer em `ApiClient`.
4. Remover a geração local de `user_id` — o `user_id` passa a vir do
   Supabase Auth de verdade.

## 6. Ordem recomendada de execução

1. Rhoney cria o projeto e roda a migration (§1).
2. Claude Code ajusta os tipos de `user_id` (§3) e testa contra o Postgres
   real (não só SQLite) — só isso já é suficiente para eliminar o
   `DEV_INSECURE` do lado do backend com `SUPABASE_JWT_SECRET` configurado.
3. Claude Code condiciona `create_all` (§4).
4. Decisão de método de login (§1.5) — Rhoney decide.
5. Integração real no Flutter (§5) — só depois de alguém validar o client
   num ambiente com Flutter SDK (bloqueio já registrado no relatório do
   Vertical Slice 01).
