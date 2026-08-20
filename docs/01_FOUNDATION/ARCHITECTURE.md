# MENTAL — ARCHITECTURE.md

Status: Foundation, para apresentação e aprovação de Rhoney. Formaliza o
que `MENTAL_KICKOFF.md` §2 e §4 já decidiram, e resolve o ponto deixado em
aberto ali ("deploy backend: a definir entre Render/Railway free tier").

## 1. Visão geral

```
┌─────────────┐        ┌──────────────────────┐        ┌────────────────────┐
│   Flutter    │ HTTPS  │   FastAPI (backend)   │  SQL   │  Supabase Postgres  │
│   (Android)  │───────▶│   regras de negócio   │───────▶│  schema "mental"    │
└─────────────┘        │   única autoridade     │        │  (isolado de outros │
       │                │   de score/XP/         │        │   produtos)         │
       │                │   desbloqueio          │        └────────────────────┘
       │                └──────────────────────┘                   ▲
       │                                                            │
       │                Supabase Auth (identidade central          │
       └───────────────  RhoneyInc — "uma conta, todos os          │
        login/token      softwares") ────────────────────────────┘
```

Três camadas, cada uma com uma responsabilidade única:
- **Cliente (Flutter/Android)** — interface e captura de entrada. Nunca
  calcula score, XP, desbloqueio de território ou dificuldade. Nunca decide
  sozinho o que está liberado.
- **Backend (FastAPI)** — toda regra de negócio: scoring, XP, progressão,
  dificuldade adaptativa, hint engine, desbloqueio de território,
  assinatura, ranking. Única autoridade de dado de jogo.
- **Supabase** — Postgres (banco) + Auth (identidade). Auth é
  **compartilhada** com o projeto central de identidade RhoneyInc; o
  **schema de dado de jogo é próprio do MENTAL**, ligado ao usuário apenas
  via `user_id`. MENTAL nunca lê nem escreve em schema de outro produto
  RhoneyInc (`MENTAL_KICKOFF.md` §2).

## 2. Módulos do backend (FastAPI)

| Módulo | Responsabilidade | Fonte de decisão |
|---|---|---|
| `auth` | Valida token do Supabase Auth, resolve `user_id` | `MENTAL_KICKOFF.md` §2 |
| `age_gate` | Tela de idade neutra, define `child_safe_mode` da sessão | `FAMILY_SAFETY.md` §3-4 |
| `challenge_engine` | Serve o próximo desafio (tipo + dificuldade), valida resposta | `GAMEPLAY.md`, `ADAPTIVE_DIFFICULTY.md` |
| `scoring` | Calcula XP/score por tentativa, aplica fórmula de penalidade de dica | `GAMIFICATION.md`, `HINT_ENGINE.md`, `RISKS_AND_OPEN_DECISIONS.md` §1 |
| `hint_engine` | Serve dicas progressivas, registra dicas usadas por tentativa | `HINT_ENGINE.md` |
| `progress` | Território atual, XP acumulado, nível, streak (com freeze) | `TERRITORIES.md`, `GAMIFICATION.md` |
| `subscription` | Status de assinatura, valida recibo Google Play Billing, desbloqueio | `MONETIZATION.md` |
| `ranking` | Ranking geral (janela semanal) e de amigos | `RANKING.md` |
| `social` | Card de conquista, deep link de convite (captura de origem, sem recompensa no V1) | `MENTAL_KICKOFF.md` §6 |

Cada módulo é isolado por responsabilidade dentro do mesmo serviço FastAPI
no V1 — não há necessidade de microsserviços separados nesse volume de
tráfego; dividir agora seria complexidade sem benefício real
(`PRODUCT_PRINCIPLES.md` §7).

## 3. Deploy do backend — decisão

Kickoff §2 pediu avaliação de custo entre Render e Railway free tier antes
de decidir. Verificação feita nas páginas oficiais de pricing/docs (não por
suposição, conforme exige a regra Zero-Cost API):

| | Render (Free Web Service) | Railway (Free Plan) |
|---|---|---|
| Custo base | $0 | $0 |
| Cartão de crédito para começar | Não exigido | Não exigido |
| Cobrança automática possível | Só se houver método de pagamento cadastrado e a banda mensal incluída for excedida | Uso além dos créditos mensais ($1) é cobrado às taxas do plano |
| Comportamento sem cartão cadastrado | Sem cobrança — serviço fica limitado/suspenso | Documentação não deixa claro o comportamento sem cartão além do crédito |
| Sleep por inatividade | Sim, após 15 min sem tráfego (cold start ~1 min) | Não é o modelo (créditos, não sleep) |
| Horas incluídas | 750h/mês por workspace | Créditos ($1/mês), não horas |

**Decisão: Render Free, sem cartão de crédito cadastrado.** Classificação
`cost_status = ZERO_COST` (regra da skill Zero-Cost API) — sem cartão no
sistema, não existe caminho para cobrança automática; ao exceder banda, o
serviço é limitado, nunca cobrado. Railway fica descartado para o V1 porque
o modelo de crédito mensal cria ambiguidade sobre cobrança de overage que
não foi possível confirmar como impossível na documentação oficial —
falha-segura da mesma skill: quando a possibilidade de cobrança não pode
ser descartada com certeza, a resposta é não integrar.

**Trade-off identificado, com mitigação obrigatória** (ressalva técnica de
Rhoney, 2026-08-19): cold start de ~1 minuto após 15 min de inatividade não
é só detalhe técnico — para um jogo cuja proposta é "diversão imediata,
sem parecer estudo" (`VISION.md` §4), 1 minuto de espera na primeira
requisição mata a primeira impressão, com risco agravado para
criança/idoso (`FAMILY_SAFETY.md` §1), que tende a interpretar a demora
como o app ter travado. Duas mitigações, ambas obrigatórias no V1, não
opcionais:

1. **Loading com feedback explícito, nunca tela branca/travada.** Toda
   chamada que possa coincidir com cold start (primeira requisição da
   sessão, especialmente `GET /challenges/next`) exibe estado de
   carregamento com mensagem ("Preparando seu desafio...") em vez de
   spinner genérico ou tela sem resposta visual — requisito de UI do
   Vertical Slice 01, não polimento posterior.
2. **Keep-alive externo gratuito.** Ping HTTP contra o backend a cada 5
   minutos via UptimeRobot (plano free: sem cartão de crédito, sem risco
   de cobrança — verificado na página oficial de pricing, mesmo rigor
   Zero-Cost API aplicado à escolha do Render). Isso mantém o serviço
   ativo durante janelas de uso normal, reduzindo a chance real de o
   jogador encontrar o cold start, sem custo e sem upgrade de plano. Um
   ping a cada 5 min fica dentro do intervalo de sleep de 15 min do Render
   com folga suficiente, e o consumo de horas resultante (~730h/mês) ainda
   cabe nas 750h/mês incluídas no free tier — não gera custo adicional.

Cold start residual (ex.: os primeiros segundos após um gap de rede do
próprio UptimeRobot, ou pico de tráfego simultâneo ao restart) continua
possível — a mitigação reduz a frequência, não elimina 100% o cenário; por
isso o item 1 (loading explícito) é obrigatório independente do keep-alive
estar funcionando.

## 4. Autenticação e identidade

- Login via Supabase Auth (mesmo provedor de identidade de outros produtos
  RhoneyInc) — token JWT do Supabase é validado pelo FastAPI em cada
  requisição autenticada.
- `user_id` do Supabase é a única chave que liga o jogador ao seu progresso
  no schema MENTAL. Nenhum outro dado de outro produto RhoneyInc é lido.
- Métodos de login: a definir na Foundation seguinte de UX/onboarding —
  fora do escopo deste documento (não é decisão de arquitetura de sistema).

## 5. Infraestrutura de dados

- Banco: Postgres gerenciado pelo Supabase (mesmo projeto de auth, schema
  `mental` isolado).
- Cache: nenhum cache externo no V1 — não há justificativa de escala para
  isso ainda (`PRODUCT_PRINCIPLES.md` §7). Se o cold start do Render se
  mostrar um problema real de UX, reavaliar como ADR, não como decisão
  silenciosa.

## 6. Observabilidade mínima do V1

- Logs padrão do FastAPI + logs do Render (nenhum SDK de terceiro de
  analytics/crash reporting inicializado fora do modo child-safe, conforme
  `FAMILY_SAFETY.md` §4).
- Sem APM pago no V1 — reavaliar quando houver tráfego real que justifique.

## 7. O que este documento não decide

- Schema de tabelas (→ `DATA_MODEL.md`).
- Contratos de endpoint (→ `API_CONTRACT.md`).
- Controles de segurança detalhados (→ `SECURITY.md`).
