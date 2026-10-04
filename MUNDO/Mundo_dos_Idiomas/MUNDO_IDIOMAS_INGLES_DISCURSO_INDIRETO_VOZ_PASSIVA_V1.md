# MENTAL — Inglês: Discurso Indireto (Reported Speech) e Voz Passiva

**Status:** EM IMPLEMENTAÇÃO (03/10/2026) — aprovado por Rhoney. Mecanismo completo já implementado e testado (migration 118 já rodada em produção, formato MCQ padrão sem mudança de client, backend 606/606 passando, commit `c2512fb`) — conteúdo ainda só no lote1 (90 de até 600 unidades previstas em §2), aguardando revisão de Rhoney antes dos próximos lotes. Movido pra MUNDO/Mundo_dos_Idiomas/ (03/10/2026) — mecanismo implementado e testado já é suficiente, não é preciso esperar o volume total de conteúdo.

---

## 1. Objetivo

Voz passiva e discurso indireto já aparecem **embrionariamente** como variação dentro de Conjugação Verbal Avançado (MUNDO_IDIOMAS_CONJUGACAO_VERBAL_V1.md), mas sem volume próprio nem progressão dedicada. São duas das fontes mais recorrentes de erro estrutural de português→inglês — "he told me he is tired" em vez de "he told me he was tired" (erro de concordância de tempo no discurso indireto), ou uso incorreto/ausente de "by" na voz passiva. Este documento propõe um território dedicado, com o mesmo tratamento de volume já dado a Preposições e Artigos e Phrasal Verbs.

## 2. Volume e estrutura

- **100 Desafios + 100 Relâmpagos por nível** (Básico/Intermediário/Avançado), mesmo volume das frentes centrais de gramática.
- Por nível: 100 + 100 = 200 unidades. Total: **600 unidades, exclusivamente em Inglês** (3 níveis × 200).
- Cada Desafio apresenta a transformação (ativa→passiva, ou discurso direto→indireto) dentro de uma frase com contexto completo, nunca como regra abstrata isolada — mesmo princípio já usado em Preposições e Artigos.

## 3. Critério de progressão por nível

- **Básico**: voz passiva em tempos simples (presente simples, passado simples — "the cake was made"); discurso indireto com "said"/"told" + mudança de tempo verbal básica (presente→passado: "I'm tired" → "he said he was tired").
- **Intermediário**: voz passiva com modais e tempos compostos ("it will be done", "it has been done"); discurso indireto com perguntas e comandos reportados ("asked if...", "told [someone] to...").
- **Avançado**: voz passiva em estruturas mais sofisticadas ("is said to be", "was reported to have been"); discurso indireto com mudança de advérbios de tempo/lugar ("yesterday"→"the day before", "here"→"there", "tomorrow"→"the next day") e verbos introdutórios variados (suggested, denied, admitted, warned).

## 4. Formato de pergunta — transformação em contexto, nunca regra isolada

Mesmo princípio já estabelecido em Preposições e Artigos (§4 daquele documento): a transformação gramatical deve sempre aparecer dentro de uma frase com contexto completo. Formato sugerido: apresentar a frase original (ativa/discurso direto) e pedir a transformação correta entre alternativas, ou apresentar a frase já transformada com uma lacuna (igual ao padrão de Preposições).

## 5. Integração com as mecânicas já formalizadas do Mundo dos Idiomas

- Compatível com Imersão Progressiva, Constelação de Palavras, regra de áudio vinculado ao elemento (MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md).
- `correct_answer` sempre 2+ palavras (regra do Word Constellation).
- Conexão com a base de conhecimento do MENTAL LINGO — o LINGO deve ser capaz de corrigir discurso indireto/voz passiva mal formados numa conversa, dado que é um dos erros estruturais mais recorrentes de falantes de português.
- Elegível para Repetição Espaçada assim que a UI de revisão existir.
- **Atenção à sobreposição com Conjugação Verbal Avançado**: os itens já existentes ali que tocam voz passiva/discurso indireto devem ser mantidos (sobreposição de temas é normal e desejada), mas a curadoria desta frente deve evitar reusar os MESMOS exemplos literais — variar o conteúdo, não duplicar.

## 6. Delegação ao agente de curadoria e revisão em lotes

- Produção conduzida pelo agente autônomo de curadoria, com pesquisa em fontes gramaticais confiáveis.
- Revisão humana de Rhoney em lotes por nível, mesmo princípio já estabelecido nas demais frentes.

## 7. Critério de aceite

- 100 Desafios + 100 Relâmpagos de Discurso Indireto/Voz Passiva em Inglês por nível, totalizando 600 unidades.
- Toda transformação apresentada dentro de frase com contexto completo.
- Progressão de complexidade clara entre os três níveis.
- Nenhum exemplo literal duplicado dos já existentes em Conjugação Verbal Avançado.
- Revisão e aprovação de Rhoney em lotes, sem abrir mão da aprovação humana obrigatória.
