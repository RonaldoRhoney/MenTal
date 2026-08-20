# MENTAL — Guia de provisionamento do Supabase real

Status: projeto criado por Rhoney (`daogwiqwqplcvehdhksf`), migration
rodada, backend testado de ponta a ponta contra o Postgres real e a
autenticação real do Supabase em 2026-08-19. Itens §3 e §4 (antes
"pendentes") **resolvidos e verificados nesta sessão** — ver §7.

## 1. O que foi feito no painel do Supabase

1. Projeto criado (organização "Rhoney", plano Free).
2. Migration `backend/migrations/001_initial_schema.sql` rodada com
   sucesso — schema `mental` com as 11 tabelas + seed dos 4 territórios,
   confirmado visualmente no Schema Visualizer.
2A. Migration `backend/migrations/002_admin_role.sql` rodada com sucesso
    (padrão admin RhoneyInc — `rhoneyinc@gmail.com` promovido
    automaticamente a `role = 'admin'` em `profiles`, ver `DATA_MODEL.md`
    §1 e `SECURITY.md` §9A). **Verificado via query de conferência**
    (não só "rodou sem erro"): coluna `role` existe em `mental.profiles`,
    trigger `on_auth_user_created_mental` existe em `auth.users`, função
    `mental.handle_new_mental_user()` existe — os 3 confirmados no SQL
    Editor em 2026-08-20.
2B. **Pendente de execução**: `backend/migrations/003_i18n_language_code.sql`
    (`ARCHITECTURE_UPDATE_I18N_READY.md` — adiciona `language_code` a
    `mental.challenges`, default `'pt-BR'`). Mesmo processo das anteriores,
    ainda não rodada nesta sessão.
3. **Descoberta importante**: o projeto usa assinatura de token
   **assimétrica ES256 (ECC P-256)** como chave atual (Settings → API →
   JWT Keys), não o modelo legado de segredo compartilhado HS256 — esse
   aparece só como "Legacy key", já superado. Isso muda a forma de
   validação do lado do backend (ver §2).
4. **Método de login — decidido em 2026-08-20**: ordem de apresentação
   1) Google, 2) email/senha, 3) Facebook (registrado em
   `FAMILY_SAFETY.md` §3.1, com a ressalva de acessibilidade para
   criança sem conta Google própria). O provider Google inicialmente
   reaproveitava o Client ID OAuth do MeuPet — **corrigido**: criado um
   Client ID dedicado ao MENTAL no Google Cloud Console (mesmo projeto
   GCP compartilhado da RhoneyInc, credencial própria), configurado no
   provider Google do Supabase, e **verificado de verdade**: o endpoint
   `GET /auth/v1/authorize?provider=google` redireciona para
   `accounts.google.com` com `client_id=900389713407-...` (o novo, não
   mais o "MeuPet") e `scope=email+profile` (mínimo, sem dado estendido).
   Facebook OAuth ainda não configurado — mesma regra de credencial
   própria por produto se aplica quando for a vez dele.
5. **"Confirm email" — religado**: foi desligado temporariamente durante
   o teste de autenticação (§ anterior desta sessão) para conseguir um
   usuário confirmado sem acesso a caixa de entrada; religado e
   verificado depois (toggle visualmente confirmado ligado, e um novo
   signup de teste retornou `429 email_send_rate_limit` — evidência de
   que o fluxo de confirmação está ativo, já que esse erro só ocorre
   quando o Supabase tenta enviar o e-mail de confirmação).

## 2. Autenticação real — como ficou (JWKS, não HS256)

`backend/app/auth.py` agora tenta, em ordem:

1. `SUPABASE_URL` configurado → valida o JWT buscando a chave pública via
   JWKS em `{SUPABASE_URL}/auth/v1/.well-known/jwks.json` (chave pública,
   não é segredo — pode ficar em variável de ambiente comum). **Este é o
   modo usado pelo projeto MENTAL, testado e funcionando.**
2. `SUPABASE_JWT_SECRET` configurado (sem `SUPABASE_URL`) → HS256 legado,
   fallback para projeto Supabase mais antigo que ainda use esse modelo.
3. Nenhum dos dois → `DEV_INSECURE` (token = user_id em texto puro),
   nunca para produção.

Variável necessária em produção:
```bash
export SUPABASE_URL="https://daogwiqwqplcvehdhksf.supabase.co"
export MENTAL_DATABASE_URL="postgresql+psycopg://postgres:<senha>@db.daogwiqwqplcvehdhksf.supabase.co:5432/postgres?options=-csearch_path%3Dmental,public"
```
O parâmetro `options=-csearch_path=mental,public` na connection string é
o que faz o SQLAlchemy encontrar as tabelas sem precisar qualificar
`mental.` em cada query — evita duplicar `__table_args__={"schema": ...}`
em todo model (o que quebraria a compatibilidade com SQLite local).

## 3. Ajuste de tipo — RESOLVIDO e testado contra Postgres real

O gap estava correto: `backend/app/models.py` declarava `user_id` (e
todo outro campo de UUID: `Challenge.id`, `Attempt.attempt_id`,
`Invite.id`, etc.) como `String` genérico. Rodando contra o Postgres real
pela primeira vez, isso gerou exatamente o erro previsto:
```
psycopg.errors.UndefinedFunction: operator does not exist: uuid = character varying
```
Corrigido trocando esses campos para `sqlalchemy.Uuid(as_uuid=False)` —
tipo agnóstico de banco (uuid nativo no Postgres, `CHAR(32)` no SQLite),
mantendo o valor Python como `str` em todo o resto do código, sem precisar
mudar nada além dos models. **Testado contra o Postgres real**: age-gate,
`GET /challenges/next`, `POST /challenges/{id}/answer` (com XP calculado e
persistido) e reenvio idempotente do mesmo `attempt_id` — todos
funcionando com um token JWT real gerado pelo Supabase Auth do projeto.

Efeito colateral descoberto durante o teste: os testes automatizados
usavam ids como `"user-loop-<uuid>"` (prefixo + uuid), que eram aceitos
pelo modo `DEV_INSECURE` antigo mas violam o tipo `Uuid` de verdade —
corrigido para usar `str(uuid.uuid4())` puro em todos os testes, mais
fiel ao formato real de `user_id` do Supabase Auth.

## 4. `Base.metadata.create_all()` — RESOLVIDO

`backend/app/main.py` agora só roda `create_all()` e o seed de
desenvolvimento quando `MENTAL_DATABASE_URL` começa com `sqlite` — contra
qualquer outro banco (Postgres real), o schema é controlado exclusivamente
pela migration versionada, e o seed de desafios de exemplo nunca roda
(mantém a política de `RISKS_AND_OPEN_DECISIONS.md` §2: conteúdo curado
manualmente, nunca o seed de dev em produção).

## 5. O que muda no cliente Flutter

Ainda **não implementado** neste slice — sem Flutter SDK disponível para
validar (mesma limitação de `client/README.md`). Plano, para quando
alguém for integrar:

1. Adicionar `supabase_flutter` ao `pubspec.yaml`.
2. Inicializar `Supabase.initialize(url: ..., anonKey: <publishable key>)`
   em `main.dart`.
3. Trocar `SessionStore` (UUID local) por login real (tela a definir por
   §1.4) e usar `Supabase.instance.client.auth.currentSession?.accessToken`
   como o token Bearer em `ApiClient`.
4. Remover a geração local de `user_id`.

## 6. Limpeza pós-teste

Os dados usados para validar o fluxo (1 desafio de teste marcado
`[TESTE VS01 - APAGAR]`, e o profile/streak/progress/attempt do usuário de
teste) foram apagados do banco real ao final da sessão — confirmado via
query (`select count(*) from mental.challenges` retornou 0). **Não
apagados**: os dois usuários de teste no Supabase Auth
(`mental.vs01.teste@gmail.com`, não confirmado, e
`mental.vs01.teste2@gmail.com`, confirmado) — não têm mais nenhum dado
associado no schema `mental`, mas continuam existindo em
Authentication → Users. Baixo risco, mas Rhoney pode removê-los ali se
quiser o projeto "limpo" antes de qualquer usuário real.

## 7. Pendências reais restantes

1. ~~Religar "Confirm email"~~ — **resolvido** (§1.5).
2. ~~Método de login / Client ID reaproveitado~~ — **resolvido** (§1.4):
   ordem decidida, Client ID dedicado do Google criado e verificado.
   Facebook OAuth (3º método) ainda não configurado — próxima vez que for
   priorizado, mesma regra de credencial própria.
3. **Integração Flutter real** (§5) — não iniciada, depende de Flutter SDK
   disponível em algum ambiente para validar. Único item realmente em
   aberto deste guia.
4. **Usuários de teste no Supabase Auth** (§6) — `mental.vs01.teste@gmail.com`
   e `mental.vs01.teste2@gmail.com` continuam cadastrados, sem dado
   associado no schema `mental`. Baixo risco, remover quando conveniente.
