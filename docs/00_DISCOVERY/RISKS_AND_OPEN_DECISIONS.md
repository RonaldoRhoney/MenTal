# MENTAL — RISKS_AND_OPEN_DECISIONS.md

Status: decisões registradas por Claude (arquitetura) em 2026-08-19, a
pedido explícito de Rhoney — sujeitas a revisão técnica de Rhoney antes de
liberar a Foundation. Nada foi decidido silenciosamente: cada linha abaixo
tinha uma proposta em aberto na Discovery e foi travada aqui com
justificativa.

## 1. Decisões de produto (travadas)

| Ponto | Onde aparece | Decisão | Justificativa |
|---|---|---|---|
| Valor da assinatura mensal | `MONETIZATION.md` (origem) | R$ 9,90/mês | Ponto de entrada padrão de mercado BR para app consumer sem custo variável por uso; dá margem de ajuste sem travar caro demais agora. |
| Régua exata free vs. pago por território | `TERRITORIES.md` §2 | Palavras/Números free; Lógica/Conhecimento pago (com amostra free) | Cobre 2 dos 4 tipos gratuitos e completos — "joga bem antes de pagar" sem dar tudo de graça. |
| Limite diário de desafios free | `MONETIZATION.md` (origem) | 8/dia | Piso da faixa sugerida (8-10) — cria hábito sem canibalizar a conversão da assinatura ilimitada. |
| Existência de cronômetro visível no desafio | `GAMEPLAY.md` §1 | Não existe no V1 | Evita qualquer leitura de urgência agressiva num app de público misto com criança (`PRODUCT_PRINCIPLES.md` §3). |
| Tolerância de streak | `GAMIFICATION.md` §1 | Freeze de 1 dia por semana | Sem tolerância, streak pune esquecimento pontual e gera abandono; tolerância maior esvazia o significado da métrica. |
| Janela de tempo do ranking geral | `RANKING.md` §2 | Semanal como padrão, com aba secundária "todos os tempos" | Favorece jogador novo sem descartar o histórico para quem valoriza. |
| Penalidade de XP por uso de dica | `HINT_ENGINE.md` §2 | **Fórmula travada, modelo ADITIVO**: `fator = max(0, 1 − 0.25 × dicas_usadas)`; `xp_final = round(xp_base × fator)` | Ressalva técnica de Rhoney (2026-08-19): "cumulativo" sozinho era ambíguo entre aditivo (25%+25%+25%) e multiplicativo (0.75×0.75×0.75) — o `API_CONTRACT.md` precisa da fórmula exata para o Claude Code não interpretar dos dois jeitos. Decisão: **aditivo**, não multiplicativo. Razões: (1) mais simples de comunicar ao jogador ("cada dica custa 25% do XP daquele desafio"); (2) o piso em 0 só é uma salvaguarda real no modelo aditivo — no multiplicativo o resultado nunca chega a zero, então a cláusula "nunca abaixo de 0" já registrada ficaria sem efeito prático; (3) mantém headroom para territórios futuros com mais de 3 níveis de dica, onde o piso passa a atuar de fato (ex.: 4 dicas → fator seria −0.00, travado em 0). Exemplo com os 2-3 níveis atuais (`HINT_ENGINE.md` §6, quantidade exata a fechar na Foundation): 1 dica → fator 0.75; 2 dicas → fator 0.50; 3 dicas → fator 0.25. Rhoney registrou ressalva de produto (não técnica): -75% de XP com 3 dicas é penalidade pesada — aceita como intencional (desincentivo forte ao uso de dica), não reaberta aqui. |

## 2. Riscos identificados (mitigação aceita)

### Risco: conteúdo de "Conhecimentos gerais" mal curado
Banco de perguntas de cultura geral é o território com maior risco de
introduzir viés, erro factual, desatualização, ou conteúdo inadequado a
criança. Precisa de processo de curadoria/revisão definido antes de
popular o banco — não é um risco técnico, é um risco de produto/reputação.
**Mitigação aceita**: fonte curada manualmente (não IA-gerada, já fora de
escopo) e processo de revisão por faixa etária antes de publicar novo
conteúdo. A formalizar como processo editorial na Foundation.

### Risco: privacidade de nickname no ranking geral para menores
Ranking geral exibe nickname publicamente por padrão. Para jogador
confirmado como criança, isso pode ir além do necessário mesmo sendo só um
apelido — depende de como o Google Play interpreta "exposição pública de
identificador" na Families Policy. **Mitigação aceita**: `SECURITY.md` na
Foundation formaliza regra diferenciada para perfil infantil — nickname
obrigatoriamente anônimo/gerado pelo sistema (nunca nome real) para
qualquer conta em modo `child_safe_mode`.

### Risco: banco de desafios insuficiente para lançamento
Se a quantidade de desafios por território for baixa, o jogador percebe
repetição rapidamente, o que quebra a proposta de "joga bem desde o
gratuito" (`VISION.md` §4). **Mitigação aceita**: volume mínimo por tipo
definido na Foundation e tratado como critério de auditoria do V1 (não é
só "código pronto", é "conteúdo suficiente pronto").

### Risco: ambiguidade entre nível (gamificação) e desbloqueio (monetização)
Se a UI não deixar claríssimo que nível/XP é progresso cosmético e
desbloqueio de território é assinatura, o jogador pode se sentir enganado
("subi de nível mas não desbloqueei nada"). **Mitigação aceita**: UI separa
visualmente as duas barras de progresso desde a Foundation de design
(`GAMIFICATION.md` §1).

### Risco: deep link de convite sem recompensa pode ter baixa adoção
Capturar origem sem recompensar (V1) é decisão consciente de escopo
(`MENTAL_KICKOFF.md` §6). **Mitigação aceita**: sem ação agora — ponto de
atenção pós-lançamento; monitorar taxa de convite orgânico para decidir se
justifica antecipar a recompensa antes do V2.

## 3. Status

**Liberado para Foundation em 2026-08-19.** As 7 decisões de produto da
Seção 1 (incluindo a fórmula de penalidade de dica, revisada e travada como
aditiva após ressalva técnica de Rhoney) e as 5 mitigações da Seção 2 têm
validação técnica confirmada de Rhoney. Nenhum ajuste adicional pendente
neste documento.

Próximo passo: `ARCHITECTURE.md`, `DATA_MODEL.md`, `API_CONTRACT.md` e
`SECURITY.md` em `01_FOUNDATION/`, incorporando: a fórmula exata da
penalidade de dica (Seção 1, sem ambiguidade), campo de streak freeze,
regra de nickname anônimo obrigatório para conta em `child_safe_mode`, e as
réguas de preço/limite/ranking já travadas. Apresentação da Foundation
completa para Rhoney antes do Vertical Slice 01 (`MENTAL_KICKOFF.md` §8) —
não avança sozinho além disso.
