# MENTAL — SECURITY.md

Status: Foundation, para apresentação e aprovação de Rhoney.
Este documento formaliza, em termos de implementação, as regras já
aprovadas em `FAMILY_SAFETY.md` e `MONETIZATION.md` — não reabre nenhuma
delas, apenas diz como cada uma é garantida em código.

## 1. Autoridade única do backend (reforço transversal)

Todo cálculo de score, XP, dificuldade, desbloqueio de território e status
de assinatura acontece exclusivamente no FastAPI. Nenhum destes valores é
aceito como input do cliente em nenhum endpoint (`API_CONTRACT.md` §1) —
isso não é só regra de produto, é controle de segurança: impede que
engenharia reversa do cliente Flutter destrave conteúdo ou infle XP.

Validação técnica: qualquer endpoint que retorne dado de jogo deve ser
coberto por teste que confirma que um payload forjado de input (ex.:
tentar enviar `xp_awarded` ou `unlocked` no request) é ignorado.

## 2. Child Safe Mode

- `child_safe_mode` nasce `true` por padrão até `POST /age-gate` confirmar
  `adult` (`DATA_MODEL.md` §1, `API_CONTRACT.md` §2) — "idade desconhecida
  tratada como criança" (`FAMILY_SAFETY.md` §2) é o estado inicial real do
  sistema, não apenas uma frase de princípio.
- Enquanto `child_safe_mode = true`:
  - Nenhuma chamada a `TelephonyManager` no cliente Android.
  - `AAID` nunca é lido nem transmitido ao backend.
  - Qualquer SDK de terceiro (quando existir) inicializa em modo
    child-directed.
  - `nickname` é sempre gerado pelo sistema, nunca texto livre
    (`DATA_MODEL.md` §1).
- Mudança de `child_safe_mode` de `true` para `false` só acontece via
  `POST /age-gate` retornando `adult` — nunca automaticamente, nunca por
  inferência.

## 3. Parental Gate

- Obrigatório antes de qualquer fluxo de compra (`API_CONTRACT.md` §6).
- Implementado como desafio simples (ex.: operação matemática) no cliente,
  mas a *confirmação* de que foi passado é registrada no backend
  (`parental_gate_passed_at`) — o cliente não pode simplesmente pular a
  tela e chamar o endpoint de validação de recibo direto, porque o backend
  rejeita sem esse registro.
- **Expira em 10 minutos** (`config.PARENTAL_GATE_VALIDITY_MINUTES`,
  corrigido na revisão do Vertical Slice 01). Sem expiração, um registro
  antigo destravaria compra indefinidamente para qualquer pessoa com
  acesso ao aparelho já logado — inclusive uma criança, meses depois do
  adulto ter passado o gate uma única vez. `validate-receipt` rejeita com
  `403 PARENTAL_GATE_EXPIRED` fora da janela; o cliente precisa revalidar
  o gate a cada nova tentativa de compra, nunca reaproveitar um registro
  antigo.

## 4. Validação de recibo Google Play Billing

- `POST /subscription/validate-receipt` chama a API server-side do Google
  Play para validar o `purchase_token` — nunca confia na confirmação local
  do cliente (`MONETIZATION.md` §4).
- **Proteção contra replay**: cada `purchase_token` só pode ativar
  `status = active` uma vez por ciclo de cobrança; reenvio do mesmo token
  após já processado retorna o status atual sem reprocessar, sem estender
  `expires_at` de novo.
- Erros de validação (token inválido, expirado, de outro produto) nunca
  ativam assinatura — fail-closed, não fail-open.

## 5. Idempotência de tentativa

`attempt_id` gerado pelo cliente é chave primária de `attempts`, o que
garante `UNIQUE` no nível do banco (não apenas checagem na aplicação) —
confirmado a pedido de Rhoney em `DATA_MODEL.md` §6, com o
`INSERT ... ON CONFLICT (attempt_id) DO NOTHING` explícito lá para que a
implementação não fique livre para interpretar o comportamento de
duplicata. Reenvio do mesmo `attempt_id` (retry de rede, app
matado no meio da requisição) retorna o resultado já calculado, nunca
recalcula XP nem duplica progresso — previne tanto bug de UX (perda de
resposta) quanto abuso (reenviar a mesma tentativa esperando resultado
diferente).

## 6. Proteção do conteúdo do desafio

- `correct_answer` nunca é enviado ao cliente em `GET /challenges/next`
  (`API_CONTRACT.md` §3) — só depois de `POST /challenges/{id}/answer`.
- Conteúdo de dica (`challenge_hints`) é servido nível a nível, sob
  demanda — o backend não envia todos os níveis de uma vez, para não
  expor a resposta indiretamente por dedução de múltiplas dicas
  entregues de uma vez.

## 7. Isolamento entre produtos RhoneyInc

- Schema `mental` no Supabase é próprio; nenhuma query do backend MENTAL
  faz join ou leitura cross-schema em dado de outro produto RhoneyInc
  (`MENTAL_KICKOFF.md` §2, `DATA_MODEL.md` §12).
- Se RLS (Row Level Security) do Supabase for usado como camada adicional
  de proteção (além da validação no FastAPI): cada policy filtra por
  `user_id = auth.uid()`, nunca por lógica que dependa de dado de outro
  schema.

## 8. Privacidade — dado mínimo, ranking

- Ranking (`API_CONTRACT.md` §7) nunca expõe `user_id`, email, idade ou
  qualquer identificador além de `nickname` e `xp` (`RANKING.md` §4).
- Para perfil em `child_safe_mode`, `nickname` é sempre
  system-generated — nenhum texto livre de menor fica publicamente visível
  em ranking geral, mitigando o risco de exposição de identificador
  registrado em `RISKS_AND_OPEN_DECISIONS.md` §2.

## 9. Curadoria de conteúdo (mitigação formalizada)

- Todo registro em `challenges` do território `conhecimento` precisa de
  `age_reviewed = true` antes de entrar em rotação de produção
  (`DATA_MODEL.md` §4) — processo editorial (não técnico) a ser definido
  por Rhoney antes de popular o banco, mas o campo/trava técnica já existe
  desde a Foundation.

## 10. Superfícies de ataque explicitamente fora de escopo do V1

(Registradas para não serem esquecidas, não porque sejam ignoradas
silenciosamente — se algum destes pontos precisar de tratamento antes do
V1, é decisão de Rhoney, não assunção técnica.)
- Rate limiting agressivo por IP: básico do FastAPI/Render é aceito no V1;
  revisar se abuso real for observado.
- Detecção de bot em resposta de desafio (ex.: resposta automatizada muito
  rápida repetida): não implementado no V1 — reavaliar se ranking for alvo
  de abuso perceptível.

## 11. Checklist de segurança pré-deploy (herda `FAMILY_SAFETY.md` §8)

- [ ] Nenhum input de cliente aceito para score/XP/desbloqueio/assinatura.
- [ ] `child_safe_mode` nasce `true` por padrão, confirmado por teste.
- [ ] `AAID`/telefone nunca transmitidos antes de `age_mode = adult`.
- [ ] Nickname system-generated obrigatório para `child_safe_mode = true`.
- [ ] Parental gate bloqueia `validate-receipt` sem confirmação registrada,
      e confirmação expirada (>10 min) é tratada como ausente.
- [ ] Validação de recibo é fail-closed e protegida contra replay.
- [ ] `attempt_id` idempotente testado (reenvio não duplica XP).
- [ ] `correct_answer` nunca aparece em payload antes da resposta.
- [ ] Nenhuma query MENTAL faz join com schema de outro produto RhoneyInc.
- [ ] Conteúdo de `conhecimento` só entra em produção com `age_reviewed = true`.
