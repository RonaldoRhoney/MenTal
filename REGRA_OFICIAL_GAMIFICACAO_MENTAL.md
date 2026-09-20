# MENTAL — Regra Oficial de Gamificação

**Status:** OFICIAL como fonte da verdade de REGRA (documento aprovado). **Fase 1 IMPLEMENTADA (19/09/2026)** — recalibração dos valores de ações que já existiam (itens 1.2, 1.5, 2.1, 3.4, 4.2). **Fase 2 IMPLEMENTADA (19/09/2026, aguardando revisão de segurança + deploy)** — recompensas novas, ver seção abaixo. **Fase 3 IMPLEMENTADA (20/09/2026, aguardando migration 084 + deploy + teste no aparelho)** — teto diário de XP, reparo de streak e boost de XP, ver seção abaixo.

## Fase 1 — recalibração de valores (19/09/2026, decisões confirmadas com Rhoney)

- Item 1.2: os 5 níveis numéricos de dificuldade (1-5) mapeiam 1:1 aos 4 nomeados do documento — nível 5 paga o mesmo valor de "Muito Difícil". A fórmula de penalidade por dica e o bônus de velocidade do Relâmpago continuam aplicando sobre o novo valor-base, sem mudança de lógica. `config.XP_BASE_BY_DIFFICULTY = {1: 3, 2: 5, 3: 7, 4: 10, 5: 10}` (era `{1:10, 2:20, 3:30, 4:40, 5:50}`), `XP_BASE_DEFAULT = 5` (era 20).
- Item 1.5: `config.BATTLE_WIN_BONUS_XP = 2` (era 30).
- Item 2.1: `config.MOVEMENT_MENTALCOINS_PER_MILESTONE = 1` (era 5) — mesma regra de 1000 passos por marco. XP de Movimento (faixas/meta/checkpoint) mantido como está, decisão explícita de Rhoney (o documento só recalibra o MentalCoin).
- Item 3.4/4.2: mesmas ações já existentes, só valor novo — `config.SHARE_XP_REWARD = 2` (era 15), `config.APP_INVITE_XP_REWARD = 2` (era 20), `config.APP_INVITE_MENTALCOINS_REWARD = 1` (era 5).
- Item 1.1 (conquista de território, 200 XP) já batia, nenhuma mudança.
- Testes: suíte completa do backend (441/441) — 7 testes que assumiam a escala antiga de XP (loops com teto de tentativas insuficiente pra nova escala menor) foram ajustados, nunca a regra de negócio em si.
- **Achado a reportar**: com a nova escala, conquistar 1 território sozinho (200 XP) agora exige ~23 respostas corretas mesmo com a dificuldade adaptativa no teto máximo — perto do limite diário gratuito de 24 desafios/dia (`DAILY_FREE_CHALLENGE_LIMIT`). Vale considerar se esse teto também precisa de revisão numa fase futura, já que a Fase 1 não alterou `DAILY_FREE_CHALLENGE_LIMIT`.

## Fase 2 — recompensas novas (19/09/2026, decisões confirmadas com Rhoney)

Decisões: meia moeda do login vira **1 moeda a cada 2 logins pagos** (saldo continua inteiro, sem migração de schema); "interação diária com amigos" = **Torcida, Batalha ou convite de Movimento a amigo confirmado**; entrega em duas fases (esta, depois a 3).

Todas passam por `backend/app/rewards.py`, com anti-farm por **claim único** em `mental.reward_claims` (PK `(user_id, claim_key)`, migration `082`) — a chave carrega o período (`login:2026-09-19`, `friends:10`, `feedback:2026-W38`...). Falha numa recompensa nunca quebra o fluxo principal (`rewards.safely`).

| Item | Regra | Onde dispara |
|---|---|---|
| 4.1 | Login diário: +1 XP; +1 moeda a cada 2º login | `GET /progress` |
| 5 | Streak 7d +15 XP · 15d +30 XP · 30d +75 moedas + badge `streak_30` · 100d +250 moedas + badge raro `streak_100` | `POST /answer` (streak acabou de subir) |
| 1.3 | Terminar o lote de perguntas: +3 XP | `POST /answer` (última do lote) |
| 1.4 | Lote perfeito (todas certas, sem dica, mín. 2 respostas): +5 XP extra | idem |
| 3.2 | A cada 5 amigos confirmados (5, 10, 15...): +1 XP, único por marco, pros dois lados | aceite de amizade |
| 3.3 | Torcida a **amigo confirmado**: +1 XP, 1x/dia (a desconhecido não paga) | `POST /profile/{id}/torcida` |
| 3.1 | Interação com amigo 7 dias seguidos: +10 XP (só repete numa nova sequência completa) | Torcida, criar/responder Batalha, convite de Movimento |
| 4.3 | Feedback: +5 XP, 1x por semana ISO, texto mínimo de 10 caracteres | `POST /feedback` |
| 2.2 | 7 dias ativos de Movimento (ciclo >= 2.000 passos): +10 moedas | `POST /movement/collect` |

Interpretações registradas (não estavam no documento): um "Desafio inteiro" é o **lote de perguntas** do território/dificuldade (mesmo que dispara "Revisar erros"); "dia ativo" de Movimento = ciclo com >= 2.000 passos (`MOVEMENT_ACTIVE_DAY_MIN_STEPS`); marcos de streak reaproveitam o sistema de badges como "distintivo".

Constantes em `config.py`; testes em `backend/tests/test_rewards_fase2.py` (15, cada um com o caso anti-farm). **Antes do deploy:** rodar a migration `082` e passar pelo agente `mental-security` (mexe em XP/MentalCoins).

## Fase 3 — IMPLEMENTADA (20/09/2026)

Decisões de Rhoney (20/09/2026) e como ficaram:
- **Teto diário de 150 XP** (`config.DAILY_ANSWER_XP_CAP`): só o XP de PERFIL de resposta (Desafio + Relâmpago) para; o território segue contando o valor cheio. A última resposta que passa do teto paga só o que falta. Bônus (lote, login, streak, mundo, Movimento, Constelação…) ficam fora do teto. O dia do teto é o dia civil de **Brasília** (decisão de Rhoney, 20/09/2026 — zera à meia-noite dele, não às 21h); reparo de streak e limite diário de desafios seguem o dia UTC.
- **Boost +20% por 24h (80 MentalCoins)**: só em XP de resposta, arredondado pra cima, calculado ANTES do teto (o teto vale sobre o valor final). Não empilha — comprar com boost ativo é bloqueado e não gasta moeda.
- **Reparo de streak (50 MentalCoins)**: sequência de ≥ 2 dias; janela até o fim do dia seguinte à quebra (última jogada + 3 dias); a folga semanal grátis que já existia continua valendo primeiro. Reparar antes de jogar perdoa os dias sem jogar (a próxima jogada estende); reparar depois de recomeçar soma a sequência perdida. Marcos de streak alcançados pelo reparo são pagos.
- **Interface**: seção "Turbinar e proteger" na tela de MentalCoins (boost + reparo + XP do dia), cartão de reparo e chip de boost na Home, e texto explicando teto/boost na resposta do desafio.
- Código: `backend/app/economy.py`, `routers/economy.py` (`/economy/status`, `/economy/xp-boost`, `/economy/streak-repair`), migration `084_economia_teto_reparo_boost.sql`. Revisão do `mental-security` feita (achados A2/M2 e qualidade corrigidos).
- **Em aberto**: os locks `FOR UPDATE` só são provados em Postgres real (SQLite dos testes ignora).

## (Histórico) Pendente antes da Fase 3

Teto diário de 150 XP de respostas (decisão: só o XP de perfil para; o progresso do território segue contando), reparo de streak (50 moedas) e boost de +20% de XP por 24h (80 moedas). Itens abaixo eram os pendentes originais das Fases 2 e 3:

Mecânicas totalmente novas (login diário, marco de amigos, Torcida gerando XP, streak geral com distintivos, teto diário de 150 XP, loja de reparo de streak/boost de XP) — ver tabela de divergência abaixo, itens marcados 🆕. Perguntas 1, 4 e 7 do levantamento original (mapeamento de dificuldade e fórmulas, definição de "interação diária com amigos", MentalCoins fracionário) seguem em aberto pras fases que ainda não têm decisão.

## Divergência entre este documento e o código real (levantamento §10, antes de implementar)

| # | Regra deste documento | Código hoje | Situação |
|---|---|---|---|
| 1.1 | Conquista de território: 200 XP | `CONQUEST_XP_THRESHOLD = 200` | ✅ Já bate, nenhuma mudança necessária |
| 1.2 | Resposta correta por dificuldade: 3/5/7/10 (Fácil/Média/Difícil/Muito Difícil — 4 categorias) | `XP_BASE_BY_DIFFICULTY = {1:10, 2:20, 3:30, 4:40, 5:50}` (5 níveis numéricos) + fórmula multiplicativa de dica (`1-0,25×dicas`) + bônus de velocidade no Relâmpago | ⚠️ Divergência grande — escala totalmente diferente, e o código tem 5 níveis numéricos contra 4 categorias nomeadas no documento. **Precisa de decisão de Rhoney**: qual nível numérico vira qual categoria (existe um "nível 5" sem categoria correspondente?), e se as fórmulas de penalidade por dica/bônus de velocidade continuam existindo sobre esse novo valor-base ou são descartadas |
| 1.3 | Finalizar um Desafio inteiro: +3 XP bônus | Não existe — XP é só por resposta individual, não há conceito de "bônus por completar o desafio todo" | 🆕 Mecânica nova a construir |
| 1.4 | Desafio perfeito (100%, zero dicas): +5 XP extra | Não existe como bônus de XP — só existe o badge `no_help_needed` (10 respostas certas sem dica, acumulado, não por desafio) | 🆕 Mecânica nova |
| 1.5 | Vencer Batalha: +2 XP | `BATTLE_WIN_BONUS_XP = 30` | ⚠️ Divergência grande (redução de 15x) |
| 1.6 | **Constelação de Palavras** (MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md, 19/09/2026): +5 XP por acerto — mesmo valor de uma resposta correta de dificuldade Média, sem criar faixa nova | 🆕 Mecânica nova a construir (ver documento próprio) — recompensa em 1ª conclusão por Desafio (mesmo padrão anti-farm já usado em Pausa para Aprender/Caça-palavras: XP só na 1ª vez, nunca em repetição). **Não implementa o teto diário de 150 XP** (item 6 abaixo) — essa infraestrutura ainda não existe no código (ver 🆕 no item 6), e não faz parte do escopo desta mecânica específica; fica valendo o mesmo teto/ausência de teto que já vale pra XP de resposta normal hoje |
| 2.1 | Movimento — a cada 1.000 passos: +1 MentalCoin | `MOVEMENT_STEPS_PER_MENTALCOIN=1000` × `MOVEMENT_MENTALCOINS_PER_MILESTONE=5` = **+5** coins a cada 1000 passos | ⚠️ Divergência (redução de 5x). Além disso, o código hoje também paga **XP** de Movimento (base 20 × multiplicador de faixa até ×4, bônus de meta +50 XP, bônus de checkpoint) — nada disso aparece no documento. **Precisa de decisão**: o XP de Movimento é removido, ou o documento está incompleto? |
| 2.2 | 7 dias consecutivos de Movimento ativo: +10 MentalCoins extras | Não existe streak específico de Movimento hoje (só o streak geral de uso do app) | 🆕 Mecânica nova — precisa definir o que conta como "dia de Movimento ativo" |
| 3.1 | Interação diária com amigos por 7 dias seguidos: +10 XP | Não existe — "interação diária com amigos" não é uma ação rastreada hoje | 🆕 Mecânica nova — precisa definir o que conta como "interação" (mensagem? Torcida? Batalha?) |
| 3.2 | Marco de 5 amigos confirmados: +1 XP | Não existe recompensa por marco de amizades | 🆕 Mecânica nova |
| 3.3 | Torcer por amigo: +1 XP (1x/dia) | Torcida hoje **não gera XP nem MentalCoins** — é só notificação social | ⚠️ Divergência total (de zero pra recompensado) |
| 3.4 | Compartilhar vitória no Feed: +2 XP (1x/dia) | `SHARE_XP_REWARD = 15` (mecanismo existente: `POST /social/share-reward`, `ShareAchievementButton`) | ⚠️ Divergência de valor (redução de ~7,5x) — a ação em si já existe, é só o valor que diverge |
| 4.1 | Login diário: +1 XP e +0,5 MentalCoin | Não existe recompensa por login | 🆕 Mecânica nova — MentalCoins fracionário (0,5) também é uma decisão nova (hoje o saldo é sempre inteiro) |
| 4.2 | Compartilhar o App (fora do Feed): +2 XP e +1 MentalCoin | `APP_INVITE_XP_REWARD=20` + `APP_INVITE_MENTALCOINS_REWARD=5` (ação existente: convidar amigo pro app, 1x/dia) | ⚠️ Divergência de valor (redução de 10x em XP, 5x em MentalCoins) — mesma ação, valores diferentes |
| 4.3 | Enviar feedback: +5 XP (1x/semana) | Canal de Feedback existe, mas não paga XP hoje | 🆕 Mecânica nova |
| 5.x | Streak geral: 7d→+15XP, 15d→+30XP, 30d→+75 coins+distintivo, 100d→+250 coins+distintivo raro | Hoje: badge `iron_streak` em 7 dias (sem XP), marcos de Feed em 30/60/100 dias (só celebração visual, sem recompensa). **15 dias não é rastreado como marco hoje.** | ⚠️ Divergência grande — nenhum dos 4 marcos paga o que o documento pede hoje |
| 6 | Teto diário de 150 XP de respostas corretas (Desafio+Relâmpago), sem bloquear progresso/estatística | Não existe teto de XP diário. O que existe (`DAILY_FREE_CHALLENGE_LIMIT=24`) é um limite de **quantidade de desafios grátis por dia**, mecanismo diferente (bloqueia acesso a desafio novo, não zera XP mantendo acesso) | 🆕 Mecânica nova, precisa ser construída do zero — não é o mesmo sistema que já existe |
| 7.1 | Item de destaque de perfil (custo variável, a definir) | Catálogo de resgate já existe e é funcional (`POST /mentalcoins/catalog/redeem`), hoje com 2 molduras de foto de perfil (80/150 coins) | ✅ Infraestrutura já existe, serve de base — só falta definir os itens/preços finais (o próprio documento já marca isso como pendente em §8) |
| 7.2 | Reparar streak quebrada: 50 MentalCoins | Não existe — hoje a única forma de "salvar" o streak é o freeze automático gratuito (1x/semana, sem custo) | 🆕 Mecânica nova de compra |
| 7.3 | Boost de +20% XP por 24h: 80 MentalCoins | Não existe nenhum conceito de boost temporário de XP | 🆕 Mecânica nova, mexe na fórmula de cálculo de XP em qualquer resposta durante a janela ativa |

### Resumo executivo
De ~20 regras do documento, **1 já bate exatamente** (conquista de território), **6 têm a ação já existente mas com valor diferente** (divergência de calibração), e **~13 são mecânicas que não existem hoje** (precisam ser construídas do zero, incluindo um sistema de teto diário de XP e uma loja de itens consumíveis). Isso é um projeto grande — reescreve a escala de XP inteira, adiciona ~10 gatilhos de recompensa novos, e cria 2 itens de compra novos com efeito em runtime (reparo de streak, boost de XP). Não é um ajuste pontual.

### Perguntas que precisam de decisão de Rhoney antes de qualquer código
1. Mapeamento dos 5 níveis numéricos de dificuldade pra as 4 categorias nomeadas (item 1.2) — existe um 5º nível "acima de Muito Difícil"?
2. A fórmula de penalidade por dica e o bônus de velocidade do Relâmpago continuam existindo sobre os novos valores-base, ou são descartados na troca?
3. Movimento: o XP (base + faixas + meta + checkpoint) que já existe hoje é removido, ou o documento está incompleto e deveria manter algum XP além do MentalCoin por passo?
4. Definição operacional de "interação diária com amigos" (3.1) — qual ação conta?
5. "Compartilhar vitória no Feed" (3.4) é a mesma ação de `ShareAchievementButton`/`SHARE_XP_REWARD`, só com valor novo, ou é uma ação distinta a criar?
6. "Compartilhar o App" (4.2) é a mesma ação de convidar amigo (`APP_INVITE_XP_REWARD`), só com valor novo, ou é distinta?
7. MentalCoins fracionário (0,5 no login diário) é aceitável, ou o saldo precisa continuar sempre inteiro (arredondar pra cima/baixo)?
8. Prioridade/fases: dado o tamanho do gap, sugiro dividir em fases (ex.: Fase 1 = recalibrar valores de ações que já existem; Fase 2 = mecânicas novas de recompensa; Fase 3 = loja/teto de XP) — mas quem decide a ordem é Rhoney.

**Nenhuma linha de código foi alterada para implementar este documento — só o levantamento acima.**

**Base de referência:** elaborado a partir de pesquisa sobre mecânicas de gamificação de apps líderes (Duolingo, Khan Academy) e da estrutura já existente do MENTAL, com validação e ajustes de Rhoney.

---

## 1. Progressão e Desafios

| Ação | Recompensa | Observação |
|---|---|---|
| Conquista de território/Mundo | **200 XP** | Regra histórica, mantida sem alteração |
| Resposta correta — nível Fácil | +3 XP | |
| Resposta correta — nível Média | +5 XP | Valor de referência central |
| Resposta correta — nível Difícil | +7 XP | |
| Resposta correta — nível Muito Difícil | +10 XP | |
| Finalizar um Desafio inteiro (todas as perguntas) | +3 XP (bônus) | Cumulativo com o XP das respostas individuais |
| Desafio perfeito (100% de acerto, zero dicas usadas) | +5 XP extra | Bônus adicional, reconhece domínio real |
| Vencer uma Batalha contra outro usuário | +2 XP | Distinto do XP de resposta correta |

## 2. Movimento

| Ação | Recompensa |
|---|---|
| A cada 1.000 passos | +1 MentalCoin |
| 7 dias consecutivos de Movimento ativo | +10 MentalCoins extras |

## 3. Social

| Ação | Recompensa | Observação |
|---|---|---|
| Interação diária com amigos, por 7 dias seguidos | +10 XP | Não importa a quantidade de interações no dia, apenas a ocorrência diária |
| A cada marco de 5 amigos confirmados na rede (5, 10, 15, 20...) | +1 XP | Evento único por marco atingido |
| Torcer por um amigo | +1 XP | Limite: primeira torcida do dia gera XP; torcidas adicionais no mesmo dia não geram XP extra |
| Compartilhar uma vitória no Feed | +2 XP | Limite: primeira vez no dia |

## 4. Engajamento

| Ação | Recompensa |
|---|---|
| Login diário | +1 XP e +0,5 MentalCoin |
| Compartilhar o App (fora do Feed, ex.: redes sociais externas) | +2 XP e +1 MentalCoin |
| Enviar feedback pelo canal Feedback | +5 XP | Limite: uma vez por semana |

## 5. Streak Geral (sequência de uso do app)

| Marco | Recompensa |
|---|---|
| 7 dias consecutivos | +15 XP bônus |
| 15 dias consecutivos | +30 XP bônus |
| 30 dias consecutivos | +75 MentalCoins + distintivo de perfil |
| 100 dias consecutivos | +250 MentalCoins + distintivo raro de perfil |

Streak geral é distinto do streak específico de Movimento (seção 2) — cada um tem sua própria lógica e recompensa.

## 6. Limites Anti-Farming (regra de equilíbrio econômico)

| Regra | Valor |
|---|---|
| Teto diário de XP proveniente de respostas corretas (Desafio + Relâmpago somados) | **150 XP/dia** |
| Comportamento ao atingir o teto | Respostas continuam contando para progresso e estatísticas do usuário, mas deixam de gerar XP adicional naquele dia |
| MentalCoins de passos (Movimento) | Sem teto artificial — autolimitado pelo esforço físico real do usuário |

Este limite é considerado **estrutural** para a integridade do sistema de gamificação — não deve ser removido sem nova decisão explícita e documentada.

## 7. Destinos de Gasto dos MentalCoins (sink)

| Uso | Custo |
|---|---|
| Item de destaque exibido no perfil (raridade a definir em fase de design visual) | Variável, a definir |
| Reparar uma sequência (streak) quebrada | 50 MentalCoins |
| Boost temporário de +20% XP por 24 horas | 80 MentalCoins |

## 8. Itens Pendentes de Detalhamento Futuro

- **Design visual dos itens de destaque de perfil**: recomenda-se sistema de raridade (não apenas ligar/desligar um selo único), com níveis visuais crescentes conforme o valor gasto ou o marco atingido.
- Novos destinos de gasto de MentalCoins podem ser adicionados no futuro, desde que documentados como revisão formal deste documento.

## 9. Regra de Governança deste Documento

Qualquer alteração de valor, adição de nova mecânica, ou remoção de regra existente deve ser feita através de **nova versão formal deste documento**, aprovada por Rhoney, nunca por ajuste direto e não documentado no código. Isso garante que este documento permaneça, de fato, a fonte única da verdade sobre gamificação no MENTAL.

## 10. Escopo técnico (a validar por Claude Code)

- Auditar o código atual e reportar toda divergência encontrada entre o comportamento real do app e as regras deste documento, antes de implementar qualquer correção.
- Implementar o teto diário de XP (seção 6), incluindo o comportamento correto de continuar registrando progresso sem gerar XP após o limite.
- Implementar os marcos de streak geral (seção 5), com os distintivos de perfil correspondentes (mesmo que em versão visual simples inicialmente, a refinar depois conforme seção 8).
- Implementar os dois novos destinos de gasto de MentalCoins (reparo de streak e boost de XP), incluindo a lógica de consumo do saldo do usuário.
- Confirmar que Torcida, Feed (compartilhamento de vitória) e canal de Feedback já existem tecnicamente no app para receber essas novas regras de recompensa — caso alguma dessas funcionalidades ainda não esteja implementada, reportar a Rhoney antes de tentar recompensar uma ação que não existe.
