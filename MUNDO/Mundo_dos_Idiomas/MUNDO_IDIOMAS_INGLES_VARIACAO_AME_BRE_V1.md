# MENTAL — Inglês: Variação Regional (American English vs. British English)

**Status:** EM IMPLEMENTAÇÃO (03/10/2026) — aprovado por Rhoney, decisão de escopo §2 resolvida: **Opção A** (território dedicado). Mecanismo completo já implementado e testado (migration 120, formato MCQ padrão sem mudança de client, backend 606/606 passando, commit `aa4203b`) — conteúdo ainda só no lote1 (90 de até 150 unidades previstas em §3), aguardando revisão de Rhoney antes dos próximos lotes. Movido pra MUNDO/Mundo_dos_Idiomas/ (03/10/2026) — mecanismo implementado e testado já é suficiente, não é preciso esperar o volume total de conteúdo. Com esta frente, as 4 prioridades da análise de lacunas de Inglês (02/10/2026) estão todas com mecanismo implementado.

---

## 1. Objetivo

Hoje não há nenhuma cobertura sistemática das diferenças entre inglês americano e britânico (vocabulário: color/colour, elevator/lift, apartment/flat, truck/lorry; preposição/uso: "on the weekend"/"at the weekend", "write someone"/"write to someone"; e o caso real já encontrado na curadoria de Preposições e Artigos — "taken to hospital" sem artigo é regra britânica, "taken to the hospital" é o normal americano). Sem essa cobertura, o usuário pode ficar confuso ao encontrar as duas variantes "corretas" em fontes diferentes (filmes, livros, conversas) sem entender que são regionalismo, não erro.

## 2. Decisão de escopo em aberto — Rhoney precisa escolher antes de eu prosseguir

Duas abordagens possíveis, com tradeoffs diferentes:

**Opção A — Território dedicado** (recomendação deste documento): mesmo padrão de Falsos Cognatos — volume moderado (25 Desafios + 25 Relâmpagos por nível, 150 unidades totais), testando reconhecimento ativo de qual variante é qual e em que contexto cada uma é esperada. Vantagem: conteúdo deliberado, com progressão própria, fácil de expandir depois. Desvantagem: mais uma frente nova pra manter.

**Opção B — Notas anexadas aos territórios existentes**: em vez de território novo, adicionar uma nota de variação dialetal (como já foi feito ad-hoc no item "hospital" de Preposições e Artigos) aos itens já existentes que tiverem esse tipo de ambiguidade, territoriais por território. Vantagem: mais barato, sem overhead de frente nova. Desvantagem: exigiria revisar/editar conteúdo já publicado em produção (centenas de itens já curados e aprovados), risco de regressão em conteúdo que já passou por auditoria; e cobertura ficaria dispersa/incompleta, dependente de a curadoria notar o caso em vez de ensinar a diferença de forma deliberada.

Este documento segue estruturado para a **Opção A** (recomendada), mas nada deve ser implementado até Rhoney confirmar qual das duas seguir.

## 3. Volume e estrutura (assumindo Opção A)

- **25 Desafios + 25 Relâmpagos por nível** (Básico/Intermediário/Avançado), mesmo volume de Falsos Cognatos — universo de pares AmE/BrE didaticamente relevantes é finito, de tamanho comparável.
- Por nível: 25 + 25 = 50 unidades. Total: **150 unidades, exclusivamente em Inglês** (3 níveis × 50).

## 4. Critério de progressão por nível

- **Básico**: pares de vocabulário mais notórios e de altíssima frequência (color/colour, apartment/flat, elevator/lift, truck/lorry, cookie/biscuit, soccer/football).
- **Intermediário**: diferenças de uso/preposição menos óbvias (on the weekend/at the weekend, write someone/write to someone, different from/different to).
- **Avançado**: casos mais sutis, incluindo gramática/artigo (taken to hospital/taken to the hospital, in future/in the future) e diferenças de pronúncia marcantes quando relevante ao texto.

## 5. Formato de pergunta

Apresentar a palavra/expressão em contexto de frase e perguntar qual variante (americana ou britânica) está sendo usada, ou o equivalente na outra variante — nunca apresentar como "uma está certa, a outra errada".

## 6. Integração com as mecânicas já formalizadas do Mundo dos Idiomas

- Compatível com Imersão Progressiva, Constelação de Palavras, regra de áudio vinculado ao elemento.
- Conexão com o MENTAL LINGO — o LINGO deve reconhecer que ambas as variantes estão corretas quando o usuário usar uma ou outra, nunca corrigir uma como erro.
- Elegível para Repetição Espaçada assim que a UI de revisão existir.

## 7. Delegação ao agente de curadoria e revisão em lotes

- Produção conduzida pelo agente autônomo de curadoria, com pesquisa em fontes linguísticas confiáveis sobre AmE/BrE.
- Revisão humana de Rhoney em lotes por nível.

## 8. Critério de aceite

- Decisão de escopo (§2) confirmada por Rhoney antes de qualquer implementação.
- Se Opção A: 25 Desafios + 25 Relâmpagos por nível, totalizando 150 unidades, nunca apresentando uma variante como "errada".
- Revisão e aprovação de Rhoney em lotes, sem abrir mão da aprovação humana obrigatória.
