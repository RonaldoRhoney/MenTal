# MENTAL — Regra de Não-Repetição com Revisão de Erros ao Final da Rodada

**Status:** Aprovado para implementação.
**Documento relacionado:** BUG_PERGUNTAS_REPETINDO_SEQUENCIA.md (define a sequência sem repetição dentro do lote — este documento adiciona a regra específica de tratamento de erros, refinando aquele comportamento).

---

## 1. Regra central

Dentro de uma mesma rodada (sequência de perguntas de um desafio/nível, seja no formato tradicional ou Relâmpago), **nenhuma pergunta se repete durante o andamento da rodada**, independente de o usuário ter acertado ou errado. Se o usuário errar uma pergunta, o sistema segue normalmente para a próxima pergunta da sequência — nunca insere a mesma pergunta de novo em seguida, nem em qualquer outro ponto no meio da rodada.

## 2. O que acontece com as perguntas erradas

- Toda pergunta respondida incorretamente durante a rodada é registrada numa lista temporária de "erros da rodada" (existente apenas durante aquela sessão de jogo, não persistida como histórico permanente separado).
- Essa lista não interfere na sequência normal de perguntas — o usuário continua avançando pelo lote completo, na ordem já definida pela regra de não-repetição (BUG_PERGUNTAS_REPETINDO_SEQUENCIA.md).

## 3. Revisão ao final da rodada

- Assim que o usuário chegar ao final da rodada (última pergunta do lote respondida, seja acerto ou erro), o sistema verifica se há alguma pergunta na lista de erros daquela rodada.
- **Se houver pelo menos uma pergunta errada**, o sistema pergunta ao usuário se ele quer refazer especificamente as perguntas que errou, antes de seguir para a tela de conclusão/decisão já existente (repetir todo o desafio, seguir para o próximo, ou voltar à Home, conforme já definido em BUG_PERGUNTAS_REPETINDO_SEQUENCIA.md).
- Se o usuário aceitar, o sistema apresenta apenas as perguntas erradas daquela rodada, uma a uma, na mesma mecânica de resposta já usada no restante do desafio.
- Se o usuário recusar, ou se não houver nenhuma pergunta errada na rodada, o fluxo segue direto para a tela de conclusão já existente, sem essa etapa extra.

## 4. O que NÃO muda

- A regra de sequência sem repetição durante o andamento normal da rodada (BUG_PERGUNTAS_REPETINDO_SEQUENCIA.md) continua valendo integralmente — esta regra não a substitui, apenas adiciona o que acontece com os erros ao final.
- A tela de decisão "repetir ou seguir para o próximo" ao final de cada item individual, e a transição para a Home ao esgotar o lote completo, continuam funcionando como já especificado — a revisão de erros (seção 3) acontece antes dessas telas, não em vez delas.
- Autoridade sobre XP, tempo e resultado permanece 100% no backend, incluindo o resultado da rodada de revisão de erros (acertar na revisão não deve gerar duplicação de recompensa da pergunta original, apenas confirmar o aprendizado).

## 5. Critério de aceite

- Nenhuma pergunta se repete durante o andamento normal de uma rodada, mesmo quando respondida incorretamente.
- Ao final da rodada, se houve pelo menos um erro, o sistema pergunta se o usuário quer refazer as perguntas erradas.
- Se aceito, apenas as perguntas erradas daquela rodada são reapresentadas, uma a uma.
- Se recusado ou se não houve erro, o fluxo segue direto para a tela de conclusão já existente, sem alteração.
- Responder corretamente na etapa de revisão não gera XP duplicado pela mesma pergunta.
