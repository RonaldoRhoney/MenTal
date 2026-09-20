# MENTAL — Posição Aleatória das Alternativas (Múltipla Escolha)

**Status:** Aprovado para implementação.
**Documentos relacionados:** PALAVRAS_RELAMPAGO.md, CONHECIMENTO_CONTEUDO_GERAL_E_IMAGEM.md

---

## 1. Problema identificado

Em desafios de múltipla escolha (Palavras Relâmpago, Conhecimento — conteúdo geral, e qualquer outro formato futuro do mesmo tipo), a posição da alternativa correta estava fixa entre as tentativas. Isso permite que o usuário memorize a **posição** da resposta certa em vez de aprender o **conteúdo** — indo contra o próprio propósito cognitivo do MENTAL.

---

## 2. Decisão

A posição das alternativas (correta e incorretas) deve ser **sorteada aleatoriamente a cada exibição de desafio** — nunca fixa em um slot específico (ex.: sempre a segunda opção).

- Aplica-se a todo desafio no formato de múltipla escolha, atual e futuro: Palavras Relâmpago, Conhecimento (conteúdo geral), e qualquer território que venha a adotar esse formato.
- A randomização é decidida no momento em que o desafio é servido ao usuário — cada vez que o mesmo desafio (ou um novo) é apresentado, a posição pode mudar.
- Autoridade da randomização: pode ser feita no backend (ordem das alternativas já embaralhada na resposta da API) ou no client (embaralhamento local ao renderizar) — decisão de implementação a critério de Claude Code, desde que o resultado seja imprevisível para o usuário em toda repetição.

---

## 3. Escopo técnico (alto nível)

- Não requer mudança de modelo de dados — é puramente lógica de apresentação/ordenação das alternativas já existentes.
- Nenhuma mudança na lógica de correção de resposta (o backend continua validando pelo conteúdo da alternativa, não pela posição).
