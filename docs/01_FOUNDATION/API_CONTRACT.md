# MENTAL — API_CONTRACT.md

Status: Foundation, para apresentação e aprovação de Rhoney.
Base: FastAPI, autenticação via token Supabase Auth em todo endpoint
autenticado (header `Authorization: Bearer <token>`). Formato: JSON.

## 1. Convenções gerais

- Toda resposta de erro segue `{ "error": { "code": "...", "message": "..." } }`.
- Nenhum endpoint aceita do cliente: score, XP, resultado de desafio,
  status de desbloqueio ou status de assinatura como *input* — esses
  valores são sempre *output* calculado pelo backend.
- Endpoints que dependem de `age_mode` verificam o valor salvo no perfil,
  nunca um valor enviado solto pelo cliente sem ter passado pelo fluxo de
  `age_gate`.

## 2. Age Gate

### `POST /age-gate`
Registra a resposta da tela de idade neutra (`FAMILY_SAFETY.md` §3).

Request:
```json
{ "age_mode": "child" | "adult" }
```
Response:
```json
{ "child_safe_mode": true, "nickname": "Corujinha-Veloz" }
```
Efeito: define `profiles.age_mode`, `child_safe_mode`, e — se `child` ou se
o app nunca chamar este endpoint (`unknown` por padrão) — gera nickname
automático (`DATA_MODEL.md` §1). Bloqueia qualquer chamada subsequente que
dependa de idade adulta (ex.: liberar assinatura) até este endpoint
retornar `adult`.

## 3. Challenge Engine

### `GET /challenges/next?territory_id={id}&language_code={code}`
Retorna o próximo desafio, com dificuldade decidida pelo backend
(`ADAPTIVE_DIFFICULTY.md`). Nunca inclui `correct_answer`.

`language_code` é opcional, default `pt-BR` (`config.DEFAULT_LANGUAGE_CODE`,
`ARCHITECTURE_UPDATE_I18N_READY.md`) — filtra desafios por idioma; hoje só
existe `pt-BR` no banco, mas o parâmetro já existe para que um 2º idioma
não exija mudança de endpoint.

Response:
```json
{
  "challenge_id": "uuid",
  "territory_id": "palavras",
  "difficulty_level": 2,
  "prompt": "...",
  "options": ["...", "...", "...", "..."],
  "hints_available": 3
}
```
Erros possíveis: `403 TERRITORY_LOCKED` (território exige assinatura e
usuário não tem), `429 DAILY_LIMIT_REACHED` (limite diário free atingido,
inclui `resets_at` no corpo do erro).

### `POST /challenges/{challenge_id}/hint`
Retorna o próximo nível de dica disponível para a tentativa em andamento.

Request:
```json
{ "attempt_id": "uuid" }
```
Response:
```json
{ "hint_level": 1, "content": "..." }
```
Efeito colateral: incrementa `hints_used` da tentativa em andamento
(rastreado server-side, não confiado ao cliente).

### `POST /challenges/{challenge_id}/answer`
Envia a resposta. **Idempotente via `attempt_id`** (`MENTAL_KICKOFF.md`
§9.5) — reenvio do mesmo `attempt_id` retorna o resultado já calculado,
nunca recalcula nem duplica XP.

Request:
```json
{
  "attempt_id": "uuid-gerado-pelo-cliente",
  "submitted_answer": "..."
}
```
Response:
```json
{
  "is_correct": true,
  "correct_answer": "...",
  "explanation": "...",
  "xp_base": 20,
  "hints_used": 1,
  "xp_awarded": 15,
  "streak": { "current_streak": 5, "freeze_available": true },
  "territory_progress": { "xp_in_territory": 340, "conquered": false }
}
```

## 4. Fórmula de penalidade de dica (contrato exato, sem ambiguidade)

Fonte da decisão: `RISKS_AND_OPEN_DECISIONS.md` §1 — modelo **aditivo**,
travado após ressalva técnica de Rhoney sobre ambiguidade entre aditivo e
multiplicativo.

```
fator = max(0, 1 - 0.25 * hints_used)
xp_awarded = round(xp_base * fator)
```

Tabela de referência (não redundante ao código — para revisão humana sem
precisar ler a implementação):

| `hints_used` | `fator` | Exemplo (`xp_base = 20`) |
|---|---|---|
| 0 | 1.00 | 20 |
| 1 | 0.75 | 15 |
| 2 | 0.50 | 10 |
| 3 | 0.25 | 5 |
| 4+ | 0.00 (piso) | 0 |

Esta tabela e a fórmula acima são a fonte de verdade para o Claude Code na
implementação — qualquer divergência entre código e esta seção é bug, não
interpretação válida.

## 5. Progress

### `GET /progress`
```json
{
  "xp_total": 1240,
  "level": 6,
  "territories": [
    { "territory_id": "palavras", "xp_in_territory": 340, "unlocked": true, "conquered": false }
  ],
  "streak": { "current_streak": 5, "freeze_available": true }
}
```

## 6. Subscription

### `GET /subscription/status`
```json
{ "status": "active" | "none" | "expired" | "cancelled", "expires_at": "..." }
```

### `POST /subscription/validate-receipt`
Validação server-side do recibo do Google Play Billing
(`MONETIZATION.md` §4) — única forma de ativar `status = active`.

Request:
```json
{ "purchase_token": "..." }
```
Response:
```json
{ "status": "active", "expires_at": "2026-09-19T00:00:00Z" }
```
Proteção obrigatória contra replay do mesmo `purchase_token`
(`MONETIZATION.md` §6) — token já validado não reativa assinatura
novamente nem gera efeito duplicado. Detalhado em `SECURITY.md`.

### Parental gate

`POST /subscription/validate-receipt` e qualquer endpoint que abra o fluxo
de compra exigem que o cliente já tenha passado pelo desafio de parental
gate (`MONETIZATION.md` §5).

### `POST /subscription/parental-gate`
Registra que o desafio de parental gate foi resolvido, gravando
`profiles.parental_gate_passed_at = now()` no backend — nunca um campo
enviado pelo cliente afirmando que o gate passou (isso reabriria a mesma
falha que a regra de "backend como única autoridade" já existe para
prevenir em score/XP/desbloqueio, `PRODUCT_PRINCIPLES.md` §2).

**Expiração obrigatória — corrigida na revisão do Vertical Slice 01**
(ressalva de segurança de Rhoney, 2026-08-19): `parental_gate_passed_at`
**não é válido indefinidamente**. `POST /subscription/validate-receipt`
só aceita o registro se `now() - parental_gate_passed_at <=
PARENTAL_GATE_VALIDITY_MINUTES` (10 minutos, `config.py`); do contrário,
`403 PARENTAL_GATE_EXPIRED` — o cliente precisa chamar
`POST /subscription/parental-gate` de novo antes de tentar a compra.

Razão: sem expiração, um adulto que passou o gate uma vez deixaria a
conta "destravada para compra" para sempre — incluindo para uma criança
que pegasse o celular já logado meses depois, sem o gate nunca ter
aparecido para ela naquele momento específico. A janela curta é
suficiente para completar um fluxo de checkout em andamento e insuficiente
para servir de autorização permanente.

Sem registro válido (nunca passado, ou expirado): `403
PARENTAL_GATE_REQUIRED`.

## 7. Ranking

### `GET /ranking?scope=global|friends&window=weekly|all-time`
```json
{
  "window": "weekly",
  "entries": [
    { "rank": 1, "nickname": "Corujinha-Veloz", "xp": 890 }
  ],
  "me": { "rank": 42, "xp": 340 }
}
```
Nunca expõe `user_id`, email ou qualquer dado além de `nickname` e `xp`
(`RANKING.md` §4).

## 8. Social / Convite

### `POST /social/achievement-card`
Gera o card visual de conquista (server-side vs. client-side: decisão de
implementação, não de contrato — este endpoint existe independente de qual
opção for escolhida).

### `GET /social/invite-code`
Retorna/gera o `invite_code` do usuário para o deep link de convite.

### `POST /social/invite-conversions`
Registra que um novo usuário chegou via um `invite_code` — apenas captura
de origem, sem efeito de recompensa no V1 (`MENTAL_KICKOFF.md` §6).

## 9. O que não existe no V1 (fora de escopo, não esquecido)

- Endpoint de compra avulsa de território.
- Endpoint de moeda virtual.
- Endpoint de recompensa por indicação (só captura, seção 8).
- Qualquer endpoint de IA generativa de conteúdo.
