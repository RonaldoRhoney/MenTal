# MENTAL — DATA_MODEL.md

Status: Foundation, para apresentação e aprovação de Rhoney.
Schema Postgres (`mental`), Supabase. Todas as tabelas usam `user_id`
(UUID do Supabase Auth) como chave de ligação ao jogador — nenhuma tabela
duplica dado de identidade (email, nome real) que já vive no Auth central.

## 1. `profiles`

Perfil de jogo do usuário — 1:1 com `user_id` do Supabase Auth.

| Campo | Tipo | Notas |
|---|---|---|
| `user_id` | uuid, PK | FK lógica para Supabase Auth |
| `nickname` | text | Ver regra de anonimização abaixo |
| `nickname_is_system_generated` | boolean | `true` quando gerado automaticamente por estar em `child_safe_mode` |
| `age_mode` | enum(`unknown`, `child`, `adult`) | Resultado da tela de idade neutra (`FAMILY_SAFETY.md` §3) |
| `child_safe_mode` | boolean | Deriva de `age_mode != 'adult'`; flag de sessão persistida |
| `xp_total` | integer | Soma de XP entre territórios |
| `level` | integer | Derivado de `xp_total` (fórmula em `progress` module, não neste schema) |
| `role` | enum(`user`, `admin`) | Ver regra de admin padrão abaixo. Default `user` |
| `created_at` | timestamptz | |

**Regra de nickname para menor** (mitigação aceita em
`RISKS_AND_OPEN_DECISIONS.md` §2): se `age_mode` é `unknown` ou `child`, o
backend gera `nickname` automaticamente (ex.: adjetivo+substantivo
aleatório, sem input livre de texto) e marca
`nickname_is_system_generated = true`. Nickname livre só é permitido para
`age_mode = 'adult'`.

**Regra de admin padrão RhoneyInc** (`role`, adicionada em 2026-08-20):
`rhoneyinc@gmail.com` é sempre promovido a `role = 'admin'` — automaticamente,
nunca por passo manual. Implementado via trigger Postgres em `auth.users`
(`migrations/002_admin_role.sql`, função `mental.handle_new_mental_user()`),
que cria a linha em `profiles` no momento do cadastro (antes mesmo do
onboarding/age-gate) e já define `role` com base no e-mail da conta. Se a
conta já existir antes da migration rodar, a mesma migration promove
retroativamente. Nenhum endpoint do V1 usa `role` ainda — não existe
painel administrativo no Vertical Slice 01 — mas o campo e o trigger
nascem agora, mesmo raciocínio já aplicado a `child_safe_mode` (nasce na
arquitetura antes da feature existir, para não virar retrabalho
estrutural depois).

## 2. `territories`

Catálogo de territórios (dado semi-estático, não por usuário).

| Campo | Tipo | Notas |
|---|---|---|
| `id` | text, PK | ex.: `palavras`, `numeros`, `logica`, `conhecimento` |
| `challenge_type` | text | Tipo de desafio associado (`GAMEPLAY.md`) |
| `requires_subscription` | boolean | Régua travada: `palavras`/`numeros` = false; `logica`/`conhecimento` = true |
| `free_sample_count` | integer | Nº de desafios de amostra grátis em território pago (permite provar antes de assinar) |
| `display_order` | integer | |

Extensível: novo território em V2 é um novo registro, sem mudança de
schema (`TERRITORIES.md` §4).

## 3. `user_territory_progress`

| Campo | Tipo | Notas |
|---|---|---|
| `user_id` | uuid, FK | |
| `territory_id` | text, FK | |
| `xp_in_territory` | integer | |
| `conquered_at` | timestamptz, nullable | Preenchido quando o limiar de conquista é atingido |
| `unlocked` | boolean | Calculado a partir de `requires_subscription` + status de assinatura + `territory_id` estar entre os free — nunca lido diretamente do cliente |

PK composta `(user_id, territory_id)`.

## 4. `challenges`

Banco de desafios pré-produzidos (curados manualmente, `RISKS_AND_OPEN_DECISIONS.md` §2).

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid, PK | |
| `territory_id` | text, FK | |
| `difficulty_level` | integer | Faixa de dificuldade (quantidade de níveis a fechar na Foundation de conteúdo) |
| `prompt` | text | Enunciado |
| `options` | jsonb, nullable | Para múltipla escolha |
| `correct_answer` | text | **Nunca enviado ao cliente antes da confirmação da resposta** |
| `explanation` | text | Exibida após resposta, certa ou errada |
| `age_reviewed` | boolean | Marca que passou pelo processo de revisão por faixa etária (mitigação de conteúdo de "Conhecimentos gerais") |

## 5. `challenge_hints`

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid, PK | |
| `challenge_id` | uuid, FK | |
| `hint_level` | integer | 1, 2, 3 — progressivo, mais explícito a cada nível |
| `content` | text | |

Quantidade de níveis por desafio: 2 ou 3, a fechar na Foundation de
conteúdo (`HINT_ENGINE.md` §6) — schema já suporta ambos sem alteração.

## 6. `attempts`

Registro de tentativa — idempotente via `attempt_id` gerado pelo cliente
(`MENTAL_KICKOFF.md` §9.5).

**Confirmação da constraint** (pedida por Rhoney, 2026-08-19):
`attempt_id uuid PRIMARY KEY` já é, por definição do Postgres, uma
constraint `UNIQUE` (toda PK implica índice único) — não é um campo solto
com checagem só na aplicação, é garantido pelo banco. Comportamento exato
de escrita, para não deixar a implementação livre para interpretar:

```sql
INSERT INTO attempts (attempt_id, user_id, challenge_id, submitted_answer, ...)
VALUES (...)
ON CONFLICT (attempt_id) DO NOTHING
RETURNING *;
```

Se `ON CONFLICT` disparar (reenvio do mesmo `attempt_id`), o backend não
insere linha nova nem recalcula XP — busca a linha já existente por
`attempt_id` e retorna o resultado já persistido. Isso é o que
efetivamente impede duplicação de XP por retry de rede: a garantia vem do
banco (constraint), não de uma checagem de aplicação que poderia ter
condição de corrida sob requisições concorrentes.

| Campo | Tipo | Notas |
|---|---|---|
| `attempt_id` | uuid, **PK (= UNIQUE, nível de banco)** | Gerado pelo cliente; `ON CONFLICT DO NOTHING` no insert, ver acima |
| `user_id` | uuid, FK | |
| `challenge_id` | uuid, FK | |
| `submitted_answer` | text | |
| `is_correct` | boolean | Calculado pelo backend |
| `hints_used` | integer | Nº de dicas usadas nesta tentativa |
| `xp_base` | integer | XP antes da penalidade de dica |
| `xp_awarded` | integer | `round(xp_base × max(0, 1 − 0.25 × hints_used))` — fórmula travada em `RISKS_AND_OPEN_DECISIONS.md` §1, ver `API_CONTRACT.md` §4 |
| `created_at` | timestamptz | |

## 7. `streaks`

| Campo | Tipo | Notas |
|---|---|---|
| `user_id` | uuid, PK | |
| `current_streak` | integer | Dias consecutivos |
| `last_played_date` | date | |
| `freeze_available` | boolean | Reseta a `true` a cada semana — mitigação travada em `RISKS_AND_OPEN_DECISIONS.md` §1 (1 falha perdoada por semana) |
| `freeze_used_this_week` | boolean | |

## 8. `subscriptions`

| Campo | Tipo | Notas |
|---|---|---|
| `user_id` | uuid, PK | |
| `status` | enum(`none`, `active`, `expired`, `cancelled`) | |
| `google_play_purchase_token` | text, nullable | Usado na validação server-side de recibo |
| `validated_at` | timestamptz, nullable | Última validação server-side bem-sucedida |
| `expires_at` | timestamptz, nullable | |

Regra técnica inegociável (`MONETIZATION.md` §3-4): `status` só muda após
validação server-side do recibo do Google Play Billing — nunca por
confirmação local do cliente.

## 9. `daily_challenge_usage`

| Campo | Tipo | Notas |
|---|---|---|
| `user_id` | uuid, FK | |
| `usage_date` | date | |
| `challenges_consumed` | integer | Reseta por linha nova a cada dia |

PK composta `(user_id, usage_date)`. Limite diário free travado em 8/dia
(`RISKS_AND_OPEN_DECISIONS.md` §1) — usuário com assinatura ativa não é
bloqueado por este contador.

## 10. `invites`

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid, PK | |
| `inviter_user_id` | uuid, FK | |
| `invite_code` | text, unique | Usado no deep link |
| `created_at` | timestamptz | |

## 11. `invite_conversions`

| Campo | Tipo | Notas |
|---|---|---|
| `id` | uuid, PK | |
| `invite_id` | uuid, FK | |
| `invited_user_id` | uuid, FK | |
| `converted_at` | timestamptz | |

Captura de origem apenas — sem tabela de recompensa no V1
(`MENTAL_KICKOFF.md` §6, fora de escopo até V2).

## 12. Isolamento entre produtos RhoneyInc

Nenhuma tabela deste schema referencia dado de outro produto RhoneyInc por
FK direta. A única ligação entre MENTAL e o resto do ecossistema é
`user_id`, resolvido via Supabase Auth — nunca lido/escrito por join direto
em schema de outro produto (`MENTAL_KICKOFF.md` §2, reforçado como
requisito de arquitetura).
