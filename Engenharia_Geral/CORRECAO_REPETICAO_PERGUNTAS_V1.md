# MENTAL — Correção de Bug: Repetição de Perguntas dentro do Mesmo Desafio/Relâmpago

**Status:** CORRIGIDO (14/09/2026). Causa raiz: `pick_difficulty_for` (app/services.py) podia recomendar um nível de dificuldade sem NENHUM conteúdo curado — comum nos territórios "flat" (curadoria só em difficulty_level=1, ~36 territórios: Oceanos, Espaço, Gastronomia, Valores, Trânsito, Copa do Mundo etc.), já que o jogador respondendo bem sobe de nível mesmo sem existir conteúdo lá. GET /challenges/next então caía no fallback "território inteiro, qualquer dificuldade", mas `ChallengeBatchProgress` (o mecanismo de fila sem repetição do BUG_PERGUNTAS_REPETINDO_SEQUENCIA.md original) gravava o progresso na chave do nível INEXISTENTE — cada subida de nível abria uma fila nova sobre o MESMO conjunto de perguntas, reembaralhando do zero e repetindo itens já vistos minutos antes. Corrigido travando `pick_difficulty_for` pra nunca recomendar um nível sem conteúdo curado pro território (cai pro nível curado mais próximo, mantendo a mesma chave de lote estável a sessão inteira). Teste de regressão: `tests/test_challenge_batch_no_repeat.py::test_flat_territory_never_repeats_even_when_player_performs_well` (joga um território flat inteiro acertando tudo — o cenário que disparava o bug — e confirma zero repetição). Fluxo de "refazer questão errada" não foi tocado, continua exatamente como estava.

---

## 1. Problema relatado

Durante teste real no app, Rhoney identificou que a **mesma pergunta aparece mais de uma vez dentro de um mesmo Desafio ou Relâmpago**. Essa exigência de não-repetição já havia sido solicitada anteriormente e não foi cumprida — este documento formaliza a correção como prioridade de bug, não como sugestão nova.

## 2. Regra a ser implementada

### 2.1 Regra geral (obrigatória, sem exceção)
Dentro de uma mesma sessão de Desafio ou Relâmpago, **nenhuma pergunta pode se repetir**. A lógica de seleção/sorteio de perguntas deve garantir unicidade dentro daquela sessão específica.

### 2.2 Única exceção permitida: refazer questão errada
- Se o usuário **errar** uma pergunta, ele pode ter a opção de refazer aquela mesma questão — **mas somente mediante permissão explícita do próprio usuário** (ou seja, uma ação dele solicitando refazer, não algo automático).
- Esse fluxo de "refazer questão errada" **já existe** no app e **já não concede XP extra** — esse comportamento atual está correto e deve ser mantido exatamente como está.
- Essa exceção é a **única** situação em que a mesma pergunta pode aparecer duas vezes para o usuário dentro da mesma sessão. Fora desse caso específico (erro + pedido explícito de refazer), a repetição está proibida.

## 3. Escopo técnico (a investigar e corrigir por Claude Code)

- Localizar a lógica atual de seleção/sorteio de perguntas para Desafios e para o modo Relâmpago.
- Identificar a causa raiz da repetição (falta de controle de perguntas já exibidas na sessão, sorteio com reposição indevida, cache desatualizado, ou outra causa).
- Implementar controle de perguntas já exibidas **por sessão** (não perguntas já vistas historicamente pelo usuário — apenas dentro da sessão atual do Desafio/Relâmpago em andamento).
- Garantir que a correção funcione tanto para Desafios quanto para o modo Relâmpago, já que o bug foi relatado de forma genérica, cobrindo os dois modos.
- Validar que o fluxo de "refazer questão errada" continua funcionando exatamente como hoje (sem XP extra, mediante ação do usuário) após a correção — a correção da repetição indevida não pode quebrar esse fluxo já aprovado.

## 4. Critério de aceite

- Rodar múltiplas sessões de teste de Desafios e de Relâmpago, confirmando que nenhuma pergunta se repete dentro da mesma sessão, exceto no fluxo explícito de refazer questão errada.
- O fluxo de refazer questão errada continua exigindo ação explícita do usuário e não concede XP extra, como já funciona hoje.
- Regressão testada: a correção não deve reduzir de forma problemática o banco de perguntas disponível para desafios com poucas perguntas cadastradas (Claude Code deve reportar se algum Desafio específico tiver banco de perguntas pequeno demais para garantir unicidade total, para que o conteúdo seja complementado).
