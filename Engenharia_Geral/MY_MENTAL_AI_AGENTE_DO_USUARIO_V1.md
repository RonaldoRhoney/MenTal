# My_Mental_AI — agente do usuário

**Status:** IMPLEMENTADO (21/09/2026, pedido de Rhoney). Nome escolhido por Rhoney: **My_Mental_AI**.

## O que é
Um agente dentro do app que analisa o **desempenho do próprio usuário** e dá dicas, considerações e recomendações: onde ele vai melhor, onde focar, o que falta para conquistar territórios e completar Mundos, posição no ranking da semana, XP e teto diário, sequência, uso do boost e como aproveitar melhor o app.

## Regra de custo (obrigatória)
**Custo monetário zero, sempre.** É análise **por regras** sobre dados que já existem no banco — nenhuma API de IA generativa/paga. O app descreve a função como "análise automática do seu desempenho", sem prometer IA generativa. Se um dia houver uma fonte de IA realmente gratuita e sustentável, ela entra como camada opcional sobre estas regras, nunca no lugar.

## Como funciona
- Backend: `GET /coach` (`app/routers/coach.py`, lógica em `app/coach.py`). Só leitura, só dados do próprio usuário, exige maioridade confirmada, rate limit `RATE_LIMIT_COACH`.
- Do ranking sai **apenas um número** (XP que falta para o próximo colocado) — nunca a identidade de outra pessoa.
- Resposta: `name`, `summary` (respostas, acerto, XP e posição da semana, sequência, XP do dia/teto), `daily_tip` (a recomendação mais prioritária) e até 9 `cards` ordenados por prioridade. Cada card tem `title`, `body`, `action` (destino: território/Relâmpago, Movimento, MentalCoins, Ranking, Amigos) e `territory_id`. O texto usa `{territory}`, resolvido no app com o nome do território.
- Client: `lib/screens/coach_screen.dart` (tela) e cartão "Dica do My_Mental_AI" na Home (toque abre a tela).

## Regras (prioridade decrescente)
| Card | Dispara quando |
|---|---|
| `streak_repair` (100) | há reparo de sequência disponível |
| `daily_cap` (92/88) | XP de resposta do dia ≥ teto / ≥ 80% do teto |
| `close_to_conquest` (82) | território com ≥ 60% do XP de conquista, ainda não conquistado |
| `world_closest` (76) | Mundo ≥ 30% conquistado e ainda incompleto |
| `weakest` (72) | território com ≥ 10 respostas e acerto < 60% |
| `newcomer` (70) | menos de 10 respostas no total |
| `ranking` (66) | tem XP de resposta correta na semana |
| `streak` (60/58) | marco seguinte de sequência / começar a sequência |
| `strongest` (52) | território com ≥ 10 respostas e acerto ≥ 75% (sugere Relâmpago) |
| `boost` (46) | joga com regularidade, tem moedas e ainda não bateu metade do teto |
| `hints` (42) | usa ≥ 0,8 dica por resposta |
| `explore_movement` / `explore_friends` (34/33) | Movimento desativado / sem amigos |
| `how_to` (10) | sempre (guia de como aproveitar melhor o app) |

Amostra mínima de 10 respostas por território antes de afirmar qualquer taxa de acerto.

## Testes
`backend/tests/test_coach.py` (cada regra com o caso que dispara e o que não dispara, ranking sem identidade, rate limit, age gate) e `client/test/coach_screen_test.dart`.

## Ideias futuras (sem custo)
Melhor horário do usuário, comparação com a própria semana anterior, metas semanais com acompanhamento, notificação push da dica do dia (respeitando as preferências de notificação).
