# MENTAL — Levantamento e Documentação Consolidada das Regras de Gamificação

**Status:** CONCLUÍDO (18/09/2026). Levantamento puro — nenhuma regra foi alterada. Baseado em leitura direta do código-fonte atual (`backend/app/`), com citação `arquivo:linha` em cada item, conforme pedido em §3.

## Sumário para Rhoney (achados mais importantes)

1. **Limite diário de 24 desafios grátis não pode ser confirmado pelo código-fonte sozinho** — o comportamento depende de uma env var (`DAILY_LIMIT_ENABLED`) que foi setada no Render durante o teste fechado, fora do repositório. Verificar direto no painel do Render.
2. **`CONQUEST_XP_THRESHOLD` (200 XP/território) e `XP_PER_LEVEL` (100 XP/nível) são marcados no próprio código como provisórios**, não calibrados com dado real de uso — candidatos a revisão futura, não números definitivos.
3. **Ranking já está ativo em produção real**, não é mais "planejado" — tem hardening de segurança de 17/09/2026 contra scan da tabela inteira, evidência forte de uso real em escala.
4. **MentalCoins tem resgate funcional de ponta a ponta**, mas o catálogo tem só 2 itens cosméticos (molduras de perfil), com preços que o próprio código chama de "ilustrativos, a calibrar depois do lançamento".
5. Janela do Relâmpago (60s) e todo o resto abaixo refletem o código **agora**, incluindo a mudança de 20s→60s feita hoje (18/09/2026) nesta mesma sessão.

---

## 1. XP (Experiência)

**Fórmula base por dificuldade** — `config.py:91-92`: `XP_BASE_BY_DIFFICULTY = {1: 10, 2: 20, 3: 30, 4: 40, 5: 50}`, default `20`. Lida por `scoring.xp_base_for()` (`scoring.py:19-20`).

**Penalidade por dica** — `1.0 − 0.25 × dicas_usadas`, nunca abaixo de 0:
```python
# scoring.py:11-16
def hint_penalty_factor(hints_used): return max(0.0, 1.0 - config.HINT_PENALTY_FACTOR * hints_used)
def xp_awarded(xp_base, hints_used): return round(xp_base * hint_penalty_factor(hints_used))
```
`HINT_PENALTY_FACTOR = 0.25` (`config.py:75`). A docstring do topo de `scoring.py` (linhas 1-6) chama essa fórmula de "fonte de verdade travada" — qualquer divergência com documentação antiga é bug, não reinterpretação.

**Aplicação em Desafio** — `routers/challenges.py:482-483,507`: `xp_final = xp_from_hints + speed_bonus_xp`.

**Bônus de velocidade (cronometrado/Relâmpago)** — `services.py:1003-1026` (`compute_speed_bonus_xp`): bônus máximo (+100% do xp_base) até 30% do tempo consumido, decaimento linear até 70%, zero depois (`config.py:291-293`). Janela de tempo: `TIMED_MULTIPLE_CHOICE_TIME_LIMIT_SECONDS = {1: 60, 2: 60, 3: 60}` (`config.py:220`) — **60s único pra todos os níveis**, alterado de 20s hoje (18/09/2026, pedido de Rhoney nesta sessão). Territórios sempre cronometrados: `conhecimento`, `cores`, `curiosidade_relampago` (`config.py:250`).

**Conquista de Território — 200 XP confirmado**: `CONQUEST_XP_THRESHOLD = 200` (`config.py:82`), aplicado em `services.py:383-395`. ⚠️ Comentário do próprio código (`config.py:78-82`) avisa que é valor provisório, "sem dado real ainda".

**Conquista de Mundo** — bônus fixo único de `WORLD_COMPLETION_BONUS_XP = 100` (`config.py:84-89`), pago no fechamento do último território — `routers/challenges.py:561-567`.

**Subida de nível — ainda linear e fixa**: `XP_PER_LEVEL = 100` (`config.py:90`), `nível = 1 + xp_total // 100` (`scoring.py:23-27`). O próprio código já sinaliza (linhas 24-27): "simples e linear de propósito para o V1; pode ser revisada com dado real de uso".

**Outras fontes de XP**:
| Fonte | Valor | Regra | Onde |
|---|---|---|---|
| Batalha vencida | 30 XP | 1x por batalha | `config.py:442`, `services.py:1436-1439` |
| Pausa para Aprender (leitura) | 5 XP fixo | só na 1ª leitura, mín. 3s de leitura real | `config.py:238,243`, `routers/learning_pauses.py:116-122` |
| Caça-palavras | `xp_base` + bônus de velocidade `×0.5` se dentro do prazo por dificuldade (60/90/120s) | só na 1ª conclusão, piso anti-fraude 3s | `config.py:304,305,312`, `routers/word_puzzles.py:138-145` |
| Compartilhar conquista | 15 XP | 1x/dia civil UTC | `config.py:344-352`, `services.py:1029-1055` |
| Convidar amigo pro app | 20 XP + 5 MentalCoins | 1x/dia | `config.py:354-360`, `services.py:1058-1082` |
| Movimento (passos) | ver seção 6 | — | — |

**Torcida não gera XP nem MentalCoins** — só notificação social (`services.py:1648-1700`). **Streak não paga XP diretamente** — só desbloqueia badge `iron_streak` (7 dias) e marcos de Feed (30/60/100 dias).

## 2. MentalCoins

Moeda de prestígio semanal, sem valor monetário (`mentalcoins.py:1-19`).

**Ações que creditam hoje**:
| Ação | Valor | Onde |
|---|---|---|
| A cada 1000 passos no ciclo | 5 coins | `config.py:322-323`, `movement.py:231-237` |
| Top 3 do dia no ranking de XP (apuração semanal) | 10 / 5 / 3 | `config.py:482`, `mentalcoins.py:121-140` |
| Campeão da semana em passos | 20 | `config.py:485`, `mentalcoins.py:144-170` |
| Recordista do dia em passos | 10 | `config.py:486`, `mentalcoins.py:172-198` |
| Convidar amigo pro app | 5 (+ 20 XP) | `services.py:1081` |

Nenhum teto agregado de MentalCoins/dia encontrado — só os limites naturais de cada ação (marco de 1000 passos, 1x/dia pra convite, apuração semanal fixa).

**Uso real: resgate funcional, catálogo raso.** `mentalcoins.py:232-258` (`redeem_item`) valida saldo, item não resgatado antes, debita e grava transação — end-to-end real, endpoint `POST /mentalcoins/catalog/redeem` (`routers/mentalcoins.py:82-94`). Catálogo seedado tem só **2 itens** (`seed.py:420-428`, ambos molduras de foto de perfil, custo 80 e 150), com preços que o próprio comentário chama de "ilustrativos, a calibrar depois do lançamento".

## 3. Streak (sequência)

Freeze: `STREAK_FREEZE_PER_WEEK = 1` (`config.py:76`), semana ancorada na segunda-feira (`services.py:250-251`).

Lógica completa (`services.py:254-285`, `register_play_for_streak`):
- Nova semana → freeze reseta (disponível de novo).
- Jogou hoje de novo → idempotente.
- Jogou ontem → `+1` na sequência.
- Gap de **exatamente 2 dias** (perdeu 1 dia) + freeze disponível + ainda não usado essa semana → usa o freeze, sequência continua (`+1`, não reseta).
- Qualquer outro gap (≥3 dias, ou gap de 2 sem freeze disponível) → **reseta pra 1**.

Sem tolerância além do freeze semanal de 1 dia perdido — o freeze não "estende" pra mais de 1 dia.

## 4. Limites e regras de uso

**Desafios gratuitos/dia**: `DAILY_FREE_CHALLENGE_LIMIT = 24` (`config.py:64`, histórico: 8→20→24). ⚠️ **Ativação real não é confirmável só pelo código**: `DAILY_LIMIT_ENABLED` lê env var, default Python `"true"`, mas a decisão documentada (`config.py:66-73`) foi desligar via env var no Render durante o teste fechado, com instrução explícita pra religar após o lançamento — **isso é configuração de infraestrutura fora do repositório**, precisa ser conferido direto no painel do Render, não dá pra saber pelo git.

**Outros limites diários/semanais**:
| Limite | Valor | Onde |
|---|---|---|
| Batalhas enviadas/dia | 3 | `config.py:367`, `routers/battles.py:44-48` |
| Torcida (por remetente→destinatário) | 10/dia, somando os 4 tipos | `config.py:428-429` |
| Convite de Movimento (por destinatário) | 1/dia | `config.py:441` |
| Denúncia (por par denunciante→denunciado) | 5/dia | `config.py:435` |

**Dicas por desafio**: sem teto numérico fixo — limitado implicitamente pela quantidade de `ChallengeHint` curadas por desafio (`routers/challenges.py:380-381`).

**Rate limits de segurança** (anti-automação, não é "uso normal"): resposta a desafio 30/min, nova tentativa 10/min, busca 20/min, criar batalha 10/min, entre outros (`config.py:396-426`).

## 5. Territórios, Ranking e Batalhas

**Território**: 200 XP pra conquistar (ver seção 1), acumulado em `services.py:383-395`.

**Ranking — implementado de verdade, ativo em produção, não é mais "planejado"**:
- `GET /ranking` (`routers/ranking.py:91-186`), com `scope` (`global` ou `friends`, filtrando por amizade confirmada) e `window` (`weekly` = XP dos últimos 7 dias, ou total acumulado).
- Cálculo de posição no próprio banco (`row_number()`), endurecido em 17/09/2026 contra scan da tabela inteira — evidência forte de uso real em escala mundial.
- Mostra streak, mundos completos, badges, saldo de MentalCoins e total de passos por usuário.
- **Não existe** ranking fatiado por categoria/Mundo/território — é sempre XP agregado (global ou entre amigos).

**Batalhas**:
- Só entre amigos confirmados, sorteia 2 desafios distintos do mesmo território/nível (um pra cada lado), "pra evitar cola combinando resposta" (`services.py:1114-1119`).
- Vencedor: acerto bate erro; entre 2 acertos, vence quem respondeu mais rápido; entre 2 erros, empate sem vencedor (`services.py:1353-1363`).
- Vencedor ganha 30 XP; empate e derrota não dão nem tiram XP.
- Limite de 3 batalhas enviadas/dia.

## 6. Outras mecânicas de gamificação

**Movimento (passos)** — ciclo de 24h (meia-noite Brasília):
- XP: `MOVEMENT_XP_BASE = 20` × multiplicador por faixa (`[(15000,×4),(10000,×3),(5000,×2),(2000,×1),(0,×0)]`, `config.py:142-148`) — sem teto de XP acima de 15.000 passos.
- Bônus de meta pessoal: +50 XP, 1x/ciclo, meta mínima configurável de 2.000 passos (`config.py:325,331`).
- Checkpoints intradiários: ciclo dividido em 4 partes, bônus extra ao fechar as 3 primeiras (`movement.py:46-82`).
- 5 MentalCoins a cada 1000 passos (já citado).
- Teto de sanidade: 2.500.000 passos/chamada, 60.000 passos/ciclo (reduzido de 150.000 em 03/09/2026 após incidente real: sensor defeituoso inflou um ciclo a ~165.000 passos, virando MentalCoins reais — `config.py:165-192`).

**Badges** — catálogo fixo de **7 badges hoje**, avaliadas a cada resposta correta, idempotentes (`services.py:636-678`):
| code | critério |
|---|---|
| `first_conquest` | 1º território conquistado |
| `collector` | todos os territórios conquistados |
| `iron_streak` | streak ≥ 7 dias |
| `sharp_mind` | ≥ 50 respostas corretas no total |
| `no_help_needed` | ≥ 10 respostas corretas sem dica |
| `world_master_linguagem` | Mundo da Linguagem completo |
| `world_master_mente_logica` | Mundo da Mente Lógica completo |

**Efeito visual "moedas subindo"** — dispara ao cruzar múltiplo de 100 XP ou 50 MentalCoins; é só celebração visual, não credita nada (`services.py:1085-1098`).

**Feed social (eventos automáticos)**: mundo completo, marco de streak (30/60/100 dias), marco de nível (a cada 10 níveis), batalha vencida, badge conquistada, recorde pessoal de passos — todos derivados, nunca contadores à parte (`config.py:448-460`).

**"Detentor" de território**: quem tem mais XP acumulado ali **entre você e seus amigos confirmados** (nunca ranking global) — perder a posição notifica o antigo detentor (`services.py:1455-1482`).

**Convite por link (`Invite`/`InviteConversion`)** — distinto do botão "convidar amigo" que paga recompensa (seção 1/2): a conversão de convite por link **não paga XP nem MentalCoins**, só cria vínculo de amizade automático e serve de métrica de crescimento (`routers/social.py:15-35`, `models.py:708-737`).

## 7. Inconsistências/pontos de atenção sinalizados (não corrigidos)

1. Limite diário de desafios: dependente de env var no Render, não confirmável só pelo git — verificar direto na infraestrutura.
2. `CONQUEST_XP_THRESHOLD` e `XP_PER_LEVEL` são valores que o próprio código já marca como provisórios/candidatos a recalibração com dado real, não definitivos de design.
3. Streak freeze só perdoa exatamente 1 dia perdido — gap de 2+ dias reseta mesmo com freeze disponível.
4. MentalCoins: resgate é real, mas catálogo é raso (2 itens cosméticos, preços "ilustrativos").
5. Janela do Relâmpago (60s) é uma mudança de hoje mesmo (18/09/2026) — já commitada e enviada ao GitHub, mas só entra em produção depois do deploy manual no Render que você faz no final da sessão.
6. Ranking tem evidência forte (hardening de segurança recente) de já estar ativo em produção mundial — qualquer documentação antiga que ainda o descreva como "planejado" está desatualizada.

---

## 1. Motivo da solicitação

Ao longo dos vários ciclos de desenvolvimento do MENTAL (V1 a V7+), diversas regras de XP, MentalCoins e outras mecânicas de gamificação foram definidas, ajustadas e implementadas em momentos diferentes. Não existe hoje um **documento único e atualizado** que sirva como fonte da verdade sobre essas regras — o que gera risco de decisões futuras (incluindo as tomadas em conversas de planejamento) serem baseadas em suposições desatualizadas em vez do comportamento real do código em produção.

## 2. O que deve ser levantado

Claude Code deve produzir um documento consolidado, baseado em **leitura direta do código-fonte atual** (backend FastAPI e client Flutter), cobrindo:

### 2.1 XP (Experiência)
- Fórmula/valor de XP ganho por: resposta correta em Desafio, conclusão de Bloco, conquista de território/Mundo, e qualquer outra ação que gere XP hoje.
- Fórmula de penalidade por uso de dicas (confirmar se o fator `máx(0, 1 − 0,25 × dicas_usadas)` ainda está vigente ou foi alterado).
- Regra de subida de nível (confirmar se ainda é a cada 100 XP, ou se virou progressão não-linear em algum momento).
- Qualquer bônus de XP relacionado a Movimento (passos), Batalhas, Torcida, streak, ou outras interações sociais/atividades.

### 2.2 MentalCoins
- Fórmula/regra completa de como o usuário ganha MentalCoins hoje (por quais ações específicas).
- Se existe algum limite diário/semanal de ganho.
- Se MentalCoins já tem algum uso definido dentro do app (loja, personalização, desbloqueio de conteúdo) ou se ainda é apenas um contador sem aplicação prática.

### 2.3 Streak (sequência)
- Confirmar a regra de streak freeze (1 dia por semana) e como ela é calculada/aplicada na prática.
- O que acontece exatamente quando o usuário quebra a sequência (reseta a zero, tem alguma tolerância adicional, etc.).

### 2.4 Limites e regras de uso
- Confirmar se o limite de 24 desafios gratuitos/dia (mencionado como desativado temporariamente durante o teste fechado) já foi reativado após a publicação mundial, ou continua desativado.
- Qualquer outro limite diário/semanal de uso que exista hoje (ex.: número de Batalhas iniciadas por dia, limite de dicas, etc.).

### 2.5 Territórios, Ranking e Batalhas
- Regra de conquista de território (confirmar se ainda são 200 XP para conquistar).
- Estado real de implementação do sistema de Ranking (geral, por categoria, por conhecimento) — o que já existe versus o que ainda está apenas planejado.
- Regras de pontuação/recompensa específicas do sistema de Batalhas.

### 2.6 Qualquer mecânica adicional não prevista acima
- Se existir qualquer outra regra de gamificação ativa no código que não se encaixe nas categorias acima (ex.: conquistas/badges, eventos especiais, multiplicadores temporários), deve ser documentada também.

## 3. Formato de entrega esperado

Documento único e organizado (markdown, seguindo o padrão já usado no projeto), estruturado por mecânica (XP, MentalCoins, Streak, Limites, Territórios/Ranking/Batalhas), citando, quando possível, o trecho de código ou arquivo onde cada regra está implementada — para que o documento sirva de referência rastreável, não apenas uma lista solta de números.

## 4. O que este documento NÃO é

- Não é uma solicitação de mudança de nenhuma regra existente.
- Não é uma aprovação para implementar as funcionalidades ainda marcadas como "planejadas mas não confirmadas" (ex.: Ranking, se ainda não estiver ativo) — apenas reportar o estado real encontrado.
- Qualquer inconsistência ou comportamento inesperado encontrado durante o levantamento deve ser sinalizado a Rhoney como observação, não corrigido automaticamente nesta tarefa.

## 5. Critério de aceite

- Documento consolidado entregue, cobrindo todas as seções da parte 2 deste documento.
- Cada regra documentada reflete o comportamento real do código em produção no momento do levantamento, não suposição ou documentação antiga não verificada.
- Rhoney recebe esse documento como nova fonte da verdade para decisões futuras de produto envolvendo gamificação.
