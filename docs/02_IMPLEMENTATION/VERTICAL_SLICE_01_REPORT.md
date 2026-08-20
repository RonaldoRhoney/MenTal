# MENTAL — Relatório do Vertical Slice 01

Status: implementado, para revisão de Rhoney. **Não avancei além disso** —
sem próxima etapa iniciada.

## 1. Escopo coberto (conforme travado)

Os 4 tipos de desafio (Palavras, Números, Lógica, Conhecimentos gerais) e
o fluxo completo: abrir → autenticar → home → escolher território →
responder desafio → backend valida → calcula XP → registra tentativa →
exibe resultado + explicação → atualiza progresso → próximo desafio. Sem
IA, sem batalha em tempo real, sem Web, sem billing real (endpoint existe
como stub explícito, não integra o Google Play de verdade).

## 2. Arquivos criados

```
MenTal/backend/
├── app/
│   ├── main.py            — app FastAPI, handler de erro no formato do contrato, seed no startup
│   ├── config.py           — DAILY_FREE_CHALLENGE_LIMIT=8, HINT_PENALTY_FACTOR=0.25
│   ├── db.py                — engine/session SQLAlchemy
│   ├── models.py           — as 11 tabelas de DATA_MODEL.md + 1 campo novo (ver §5)
│   ├── schemas.py          — request/response Pydantic espelhando API_CONTRACT.md
│   ├── auth.py               — resolução de user_id (ver gap em §5)
│   ├── scoring.py           — fórmula de penalidade de dica, XP base por dificuldade, nível
│   ├── services.py          — streak/freeze, limite diário, desbloqueio de território, XP
│   ├── nickname.py         — geração de nickname anônimo para child_safe_mode
│   ├── seed.py                — 4 territórios + 6 desafios de exemplo (curados à mão)
│   └── routers/
│       ├── age_gate.py, challenges.py, progress.py, subscription.py, ranking.py, social.py
├── tests/ (6 arquivos, 16 testes)
├── requirements.txt, README.md
└── .venv/ (ambiente local, não versionado)

MenTal/client/  (Flutter — ver ressalva de teste em §6)
├── pubspec.yaml
├── lib/main.dart, lib/api/api_client.dart, lib/api/session_store.dart
├── lib/screens/age_gate_screen.dart, home_screen.dart, challenge_screen.dart
└── README.md
```

## 3. Endpoints implementados (todos de `API_CONTRACT.md`)

`POST /age-gate`, `GET /challenges/next`, `POST /challenges/{id}/hint`,
`POST /challenges/{id}/answer`, `GET /progress`, `GET /subscription/status`,
`POST /subscription/validate-receipt` (stub, ver §5),
`POST /subscription/parental-gate` (endpoint novo, ver §5), `GET /ranking`,
`GET /social/invite-code`, `POST /social/invite-conversions`,
`POST /social/achievement-card` (stub, geração de imagem não implementada).

## 4. Tabelas (schema `mental`, SQLite local / Postgres via `MENTAL_DATABASE_URL`)

As 11 de `DATA_MODEL.md`: `profiles`, `territories`,
`user_territory_progress`, `challenges`, `challenge_hints`, `attempts`,
`streaks`, `subscriptions`, `daily_challenge_usage`, `invites`,
`invite_conversions`. `attempts.attempt_id` é `PRIMARY KEY` (constraint
`UNIQUE` real, não checagem de aplicação) com `INSERT ... ON CONFLICT
DO NOTHING`, confirmado na sessão anterior.

## 5. Decisões e gaps encontrados durante a implementação (não estavam fechados na Foundation, documentados aqui em vez de decididos em silêncio)

1. **Sem projeto Supabase real provisionado.** `ARCHITECTURE.md` definiu
   Supabase Auth como fonte de identidade, mas nenhum projeto existe ainda.
   Implementei um modo `DEV_INSECURE` (`backend/app/auth.py`): sem
   `SUPABASE_JWT_SECRET` configurado, o token Bearer é tratado como o
   próprio `user_id`. O cliente Flutter espelha isso gerando um UUID local
   persistido. **Isso não pode ir para produção assim** — antes do build
   de release, alguém precisa provisionar o projeto Supabase e trocar os
   dois lados para login real. Marcado em `backend/README.md` e
   `client/README.md`.
2. **Endpoint `POST /subscription/parental-gate` criado, não previsto no
   `API_CONTRACT.md` original.** O contrato dizia "backend registra
   `parental_gate_passed_at` na sessão", mas o V1 é stateless (auth via
   token, sem sessão de servidor). Persisti o campo em `profiles`
   (`Profile.parental_gate_passed_at`) e criei este endpoint simples para
   marcá-lo. Baixo risco, mas é uma mudança de schema em relação ao que foi
   aprovado — sinalizando aqui em vez de deixar passar sem registro.
3. **`POST /subscription/validate-receipt` é stub.** Só aceita um
   `purchase_token` fixo de teste (`TEST_TOKEN_VALID`) — não chama a API
   real do Google Play. Consistente com o escopo travado ("sem billing
   real ainda"), mas registrado explicitamente para não ser confundido com
   integração real na próxima leitura do código.
4. **Limiar de conquista de território fixado em 200 XP**
   (`TERRITORIES.md` §3 deixava esse valor em aberto). Decisão de
   implementação, não validada com dado real de jogo — candidato a ajuste
   quando houver uso real.
5. **Fórmula de dificuldade adaptativa** implementada de forma simples
   (janela dos últimos 5 desafios respondidos no território; ≥80% de
   acerto sobe 1 nível, <40% desce 1 nível) — `ADAPTIVE_DIFFICULTY.md`
   §6 deixava a fórmula em aberto. Funcional, mas não validada com jogador
   real.
6. **Nível a partir de XP**: fórmula linear simples (100 XP por nível),
   `GAMIFICATION.md` §4 deixava em aberto.
7. **Ranking "de amigos" não implementado neste slice** — não existe
   modelagem de conexão de amigo em `DATA_MODEL.md`; o endpoint `GET
   /ranking?scope=friends` hoje se comporta igual a `scope=global`. Isso é
   uma redução de escopo real dentro do V1 (RANKING.md previa "amigos
   sempre visíveis" no free), não coberta explicitamente pela autorização
   do Vertical Slice 01 — **peço confirmação explícita** se isso pode
   ficar para uma etapa dedicada ou se precisa entrar ainda no V1.

## 6. Testes executados — resultado real

**Backend: 16/16 passando.** Rodei de verdade (`pytest`), não apenas
escrevi os testes:

```
tests/test_age_gate.py .... (4)
tests/test_core_loop.py ... (3)
tests/test_daily_limit_and_security.py .... (4)
tests/test_idempotency.py ... (3)
tests/test_scoring.py .. (2)
16 passed
```

Cobrem: `child_safe_mode` nasce `true` por padrão; nickname anônimo para
`child`/`unknown`; core loop completo com XP correto; território pago com
amostra grátis (2 tentativas passam, 3ª bloqueia sem assinatura);
**idempotência de `attempt_id`** (reenvio não duplica XP, nem mesmo
tentando mudar a resposta enviada no reenvio); fórmula de penalidade de
dica batendo com a tabela travada em `API_CONTRACT.md` §4; limite diário
de 8 bloqueando no 9º, e assinatura ativa contornando o limite; parental
gate bloqueando `validate-receipt` sem confirmação prévia; ranking nunca
expõe `user_id`/email.

Também subi o servidor de verdade (`uvicorn`) e testei com `curl` real:
`/health`, `/age-gate`, `/challenges/next`, `/progress` — todos
responderam como esperado, sem depender do `TestClient` do FastAPI.

**Client Flutter: NÃO testado.** Sem Flutter SDK disponível neste
ambiente — não rodei `flutter pub get`, `flutter analyze` nem em
emulador. O código foi revisado manualmente, mas isso não é validação
real. Detalhado em `client/README.md` §Status, com checklist do que falta
rodar antes de considerar o lado do cliente pronto.

## 7. Riscos

- **Client Flutter sem execução real** (§6) é o maior risco deste slice —
  pode ter erro de sintaxe/tipo que só aparece com o SDK real.
- **Modo DEV_INSECURE** (§5.1) precisa ser eliminado antes de qualquer
  build de release — checklist de segurança de `SECURITY.md` §11 já cobre
  isso indiretamente ("nenhum input de cliente aceito para
  score/XP/desbloqueio"), mas vale registrar aqui como item de bloqueio
  explícito de release, não só teórico.
- **Banco de desafios com apenas 6 itens** (2 por território de amostra,
  1 em lógica/conhecimento) — suficiente para demonstrar o slice, longe do
  volume mínimo de produção definido como critério de auditoria em
  `RISKS_AND_OPEN_DECISIONS.md` §2.

## 8. Decisões pendentes para Rhoney

1. Confirmar se o gap de ranking de amigos (§5.7) fica para depois do V1
   ou precisa entrar ainda.
2. Validar o limiar de conquista de 200 XP (§5.4) e a fórmula de nível
   (§5.6) — ou aceitar como está até haver dado real de uso.
3. Autorizar (ou não) seguir para provisionar o projeto Supabase real e
   eliminar o modo DEV_INSECURE — é o próximo bloqueio de release, mas não
   necessariamente da próxima etapa deste processo.
4. Confirmar se alguém roda o client Flutter num ambiente com SDK antes da
   próxima etapa, já que este slice não conseguiu validar isso.

## 9. Próximo passo — aguardando autorização

Conforme combinado: parei aqui. Não avancei para Testes formais
(`docs/.../03_TESTES` ou equivalente), Auditoria, nem qualquer etapa
seguinte do processo (`MENTAL_KICKOFF.md` §8). Devolvendo para revisão.
