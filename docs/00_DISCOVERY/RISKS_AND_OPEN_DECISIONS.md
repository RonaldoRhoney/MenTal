# MENTAL — RISKS_AND_OPEN_DECISIONS.md

Status: rascunho de Discovery, para aprovação de Rhoney.
Este documento consolida tudo que os demais documentos de Discovery
sinalizaram como "a definir" — nada aqui deve ser decidido silenciosamente
na Foundation sem passar por Rhoney primeiro.

## 1. Decisões de produto pendentes

| Ponto | Onde aparece | Proposta em Discovery | Precisa de aprovação de |
|---|---|---|---|
| Valor da assinatura mensal | `MONETIZATION.md` (origem) | R$ 9,90/mês (referência, não definitivo) | Rhoney |
| Régua exata free vs. pago por território | `TERRITORIES.md` §2 | Palavras/Números free, Lógica/Conhecimento pago | Rhoney |
| Limite diário de desafios free | `MONETIZATION.md` (origem) | 8-10/dia | Rhoney |
| Existência de cronômetro visível no desafio | `GAMEPLAY.md` §1 | Nenhum no V1 (evitar urgência agressiva) | Rhoney |
| Tolerância de streak (freeze de 1 dia?) | `GAMIFICATION.md` §1 | Aberto | Rhoney + Foundation |
| Janela de tempo do ranking geral | `RANKING.md` §2 | Semanal como padrão, ver "todos os tempos" | Rhoney + Foundation |
| Penalidade de XP por uso de dica | `HINT_ENGINE.md` §2 | Proposta: reduzir XP proporcional | Rhoney + Foundation |

## 2. Riscos identificados

### Risco: conteúdo de "Conhecimentos gerais" mal curado
Banco de perguntas de cultura geral é o território com maior risco de
introduzir viés, erro factual, desatualização, ou conteúdo inadequado a
criança. Precisa de processo de curadoria/revisão definido antes de
popular o banco — não é um risco técnico, é um risco de produto/reputação.
**Mitigação a propor na Foundation**: fonte curada manualmente (não
IA-gerada, já fora de escopo) e processo de revisão por faixa etária antes
de publicar novo conteúdo.

### Risco: privacidade de nickname no ranking geral para menores
Ranking geral exibe nickname publicamente por padrão. Para jogador
confirmado como criança, isso pode ir além do necessário mesmo sendo só um
apelido — depende de como o Google Play interpreta "exposição pública de
identificador" na Families Policy. **Mitigação a propor**: revisar com
`FAMILY_SAFETY.md`/`SECURITY.md` na Foundation se ranking geral precisa de
regra diferenciada para perfil infantil (ex.: nickname obrigatoriamente
anônimo/gerado pelo sistema, nunca nome real).

### Risco: banco de desafios insuficiente para lançamento
Se a quantidade de desafios por território for baixa, o jogador percebe
repetição rapidamente, o que quebra a proposta de "joga bem desde o
gratuito" (`VISION.md` §4). **Mitigação a propor na Foundation**: definir
volume mínimo por tipo antes de aprovar o lançamento do V1 como critério de
auditoria (não é só "código pronto", é "conteúdo suficiente pronto").

### Risco: ambiguidade entre nível (gamificação) e desbloqueio (monetização)
Se a UI não deixar claríssimo que nível/XP é progresso cosmético e
desbloqueio de território é assinatura, o jogador pode se sentir enganado
("subi de nível mas não desbloqueei nada"). **Mitigação a propor**: UI deve
separar visualmente as duas barras de progresso desde a Foundation de
design (`GAMIFICATION.md` §1).

### Risco: deep link de convite sem recompensa pode ter baixa adoção
Capturar origem sem recompensar (V1) é decisão consciente de escopo
(`MENTAL_KICKOFF.md` §6), mas vale monitorar se a taxa de convite orgânico
é baixa o suficiente para justificar acelerar a recompensa para antes do
V2 — não é uma ação agora, é um ponto de atenção pós-lançamento.

## 3. Como estes pontos devem ser resolvidos

Nenhum destes pontos é bloqueante para eu formalizar a Foundation
tecnicamente (arquitetura, contrato de API, modelo de dados) — mas os
valores exatos (preço, limites, réguas) precisam da decisão final de
Rhoney antes de qualquer implementação de código que dependa deles, e os
riscos de curadoria de conteúdo/privacidade de menor precisam de uma
resposta explícita (mesmo que "aceitar a proposta de mitigação como está")
antes do Vertical Slice 01 avançar até ranking e conhecimentos gerais.
