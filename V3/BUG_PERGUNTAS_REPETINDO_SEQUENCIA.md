# MENTAL — BUG: Perguntas se repetindo dentro do mesmo desafio/nível

**Status:** Prioridade alta — reportado por múltiplos testadores no teste fechado.
**Tipo:** Correção de bug de comportamento + especificação de fluxo esperado.

---

## 1. Descrição do problema

Testadores relataram que, dentro de um mesmo desafio/nível (seja no formato de pergunta tradicional ou Relâmpago), as perguntas estão se repetindo antes de esgotar o banco de itens disponíveis daquele território/dificuldade. O comportamento esperado é uma sequência sem repetição dentro do lote, não sorteio aleatório a cada rodada.

## 2. Comportamento esperado (especificação)

### 2.1 Sequência sem repetição
- Dentro de uma sessão de jogo num território/dificuldade específica, as perguntas/desafios Relâmpago devem seguir uma **sequência sem repetição**, cobrindo o lote completo disponível (ex: se o território tem 15 itens cadastrados naquela dificuldade, o jogador deve passar pelos 15 sem que nenhum se repita, na sequência).
- A ordem dentro do lote pode ser embaralhada a cada nova sessão (para variar a experiência entre partidas), mas **nunca repetir um item já respondido dentro da mesma sessão em andamento**, até o lote se esgotar.
- Se o jogador já respondeu todos os itens disponíveis daquele território/dificuldade numa sessão e decide continuar mesmo assim (ver seção 2.2), o sistema pode reiniciar o embaralhamento do mesmo lote — mas isso só deve acontecer depois de esgotado o lote completo, nunca no meio dele.

### 2.2 Tela de decisão ao final de cada desafio/nível
Ao final de cada desafio/nível individual (ou seja, quando o jogador termina de responder aquele item específico), exibir uma tela/modal de decisão perguntando se o jogador quer:
- **Repetir** aquele mesmo desafio/nível, ou
- **Seguir para o próximo** desafio/nível da sequência.

Isso é consistente com o Feedback Pós-Nível já existente no app (menu perguntando "o que você achou" + opção de repetir ou seguir) — esta correção deve reaproveitar esse fluxo já implementado, garantindo que ele funcione corretamente em conjunto com a sequência sem repetição (ou seja, se o jogador escolher "seguir", o próximo item apresentado deve ser o próximo da sequência sem repetição, não um sorteio aleatório que pode repetir algo já visto).

### 2.3 Fim do lote do mundo/território
Quando o jogador chegar ao **último** desafio/nível disponível daquele mundo/território (ou seja, todos os itens do lote já foram apresentados nesta sessão), o comportamento muda:
- Em vez de oferecer "repetir ou seguir para o próximo" (já que não há próximo dentro daquele lote), o app deve **retornar automaticamente à tela Home**, permitindo que o jogador escolha livremente um novo mundo, território ou dificuldade para continuar jogando.
- Essa transição para a Home deve ser clara para o jogador — não pode parecer que o app travou ou terminou abruptamente. Pode incluir uma mensagem breve confirmando que aquele lote foi concluído (ex: "Você completou todos os desafios disponíveis aqui por agora!"), antes de retornar à Home.

## 3. Investigação necessária antes de corrigir

Peço que você investigue a causa raiz antes de aplicar a correção:
1. Verificar como a seleção do próximo desafio/pergunta é feita hoje — é um sorteio aleatório simples a cada rodada (sem controle de histórico dentro da sessão), ou existe alguma lógica de sequência que está falhando?
2. Verificar se existe algum controle de "itens já vistos nesta sessão" no estado do jogo, e se esse controle está sendo persistido corretamente durante toda a sessão (não resetando por engano no meio do fluxo).
3. Verificar como o fluxo atual do Feedback Pós-Nível decide o que vem a seguir quando o jogador escolhe "seguir" — hoje ele provavelmente está pegando o próximo item de forma que permite repetição; isso precisa ser corrigido para consumir da sequência sem repetição.
4. Confirmar como o app hoje decide que "acabou o lote" (se é que decide) — pode ser que essa lógica nem exista ainda, e por isso os testadores nunca veem esse encerramento, só a repetição.

## 4. Escopo do teste antes de considerar corrigido

- Jogar um território/dificuldade completo do início ao fim, confirmando que nenhuma pergunta se repete até o lote se esgotar.
- Confirmar que a tela de decisão (repetir/seguir) aparece corretamente após cada item, exceto no último.
- Confirmar que, no último item do lote, em vez da tela de decisão repetir/seguir, o app retorna à Home com uma transição clara.
- Testar o caso de reiniciar o mesmo território/dificuldade em uma nova sessão, confirmando que o lote é reembaralhado (ordem diferente é aceitável, repetição dentro da nova sessão não).

## 5. Critério de aceite

- Nenhuma pergunta/desafio Relâmpago se repete dentro de uma mesma sessão de um território/dificuldade, até o lote completo ser apresentado.
- Fluxo de "repetir ou seguir" funciona corretamente entre itens do meio do lote.
- Ao final do lote completo, o app retorna à Home automaticamente, com transição clara, em vez de continuar oferecendo "próximo" (que não existiria) ou repetir itens.
- Testes automatizados adicionados especificamente para esse fluxo (sequência sem repetição + transição de fim de lote), para evitar regressão futura.
