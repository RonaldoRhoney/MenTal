# MENTAL — Inglês: Desafios de Compreensão de Texto Corrido

**Status:** APROVADO. Prioridade 3 das lacunas identificadas na análise de completude do Inglês (29/09/2026) — fecha uma habilidade real (leitura/compreensão de texto conectado) que nenhuma mecânica atual do Mundo dos Idiomas cobre, já que todo o conteúdo formalizado até aqui trabalha com palavra ou frase isolada. Exclusivo ao Inglês por enquanto.

---

## 1. Objetivo

Criar Desafios no formato "texto curto + perguntas de compreensão" — o usuário lê (ou ouve) um pequeno parágrafo, diálogo ou trecho narrativo em inglês, e responde perguntas sobre o conteúdo, testando compreensão real de texto conectado, não apenas vocabulário ou gramática isolados.

## 2. Formato do conteúdo

- Cada unidade de Desafio contém: um **texto curto** (parágrafo único ou pequeno diálogo entre duas pessoas, 3 a 8 frases, dependendo do nível) + um conjunto de perguntas de múltipla escolha sobre esse texto (compreensão literal, inferência simples, vocabulário em contexto).
- **Diálogos entre dois falantes** devem ser incluídos como uma variação deste formato, com áudio narrado por duas vozes distintas (reaproveitando a lógica de alternância de vozes já definida em MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md), aproximando a experiência de como a língua realmente acontece em conversas.

## 3. Volume e estrutura

- **25 Desafios + 25 Relâmpagos por nível** (Básico/Intermediário/Avançado) — Relâmpago aqui assume formato de textos mais curtos com menos perguntas por unidade, dado que o formato de compreensão de texto é naturalmente mais denso que uma pergunta solta.
- Total desta entrega: **150 unidades, exclusivamente em Inglês** (3 níveis × 50).
- Expansão incremental futura prevista, mesmo princípio já usado nas demais frentes.

## 4. Critério de progressão por nível

- **Básico**: textos curtos e simples, vocabulário já coberto no banco de 3.000 palavras, estrutura gramatical direta, temas cotidianos.
- **Intermediário**: textos um pouco mais longos, incluindo phrasal verbs e expressões já cobertas nas frentes correspondentes, com uma pergunta de inferência simples (não apenas literal).
- **Avançado**: textos com estrutura mais complexa, podendo incluir expressões idiomáticas e vocabulário menos frequente, com perguntas de inferência mais exigentes.

## 5. Fonte do conteúdo

- Textos devem ser **originais**, escritos pelo agente de curadoria — nunca extraídos ou adaptados de obras protegidas por direitos autorais (livros, artigos jornalísticos reais, letras de música). Mesmo princípio de originalidade já seguido em toda curadoria do MENTAL.
- Vocabulário usado nos textos deve, prioritariamente, reaproveitar o banco de vocabulário já existente (MUNDO_IDIOMAS_BANCO_VOCABULARIO_1000_V1.md), introduzindo vocabulário novo apenas quando pedagogicamente necessário para o nível.

## 6. Integração com as mecânicas já formalizadas do Mundo dos Idiomas

- Compatível com regra de áudio vinculado ao elemento específico (não solto).
- Elegível para o sistema de Repetição Espaçada assim que implementado.
- Conexão com a base de conhecimento do MENTAL LINGO — os textos produzidos aqui também podem servir de referência para o LINGO ao construir respostas mais longas/contextualizadas.

## 7. Delegação ao agente de curadoria e revisão em lotes

- Produção conduzida pelo agente autônomo de curadoria, com redação 100% original.
- Revisão humana de Rhoney em lotes por nível — atenção especial nesta frente, dado que texto corrido tem mais superfície para erro sutil de naturalidade/gramática do que uma frase isolada.

## 8. Critério de aceite

- 25 Desafios + 25 Relâmpagos de compreensão de texto em Inglês por nível, totalizando 150 unidades.
- Textos 100% originais, sem cópia ou adaptação de fonte protegida.
- Diálogos entre dois falantes incluídos como variação, com áudio de duas vozes distintas.
- Progressão de complexidade textual e de inferência clara entre os três níveis.
- Revisão e aprovação de Rhoney em lotes, sem abrir mão da aprovação humana obrigatória.

## 9. Status de implementação (30/09/2026)

**Conteúdo concluído (150/150 itens), aguardando migration em produção. Áudio de duas
vozes para diálogo — FICOU PENDENTE, não implementado.**

Migration 113 pronta (`backend/migrations/113_compreensao_texto.sql`), mesmo padrão
block_id "ingles" direto, display_order 79-84 contíguo. Reaproveita o mecanismo já
existente de "cápsula de texto + perguntas" (`reading_passage`, mesmo usado em
Valores/Trânsito/Gastronomia/Oceanos/Espaço) — decisão de arquitetura: os 6 territórios
(incluindo os "Relâmpago") entram em `NEVER_TIMED_TERRITORY_IDS`, nunca cronometrados,
já que ler contra o relógio contraria o propósito de compreensão de leitura (mesmo
motivo já registrado pras outras frentes de cápsula de texto). "Relâmpago" aqui
significa só "texto mais curto, menos perguntas por unidade" (confirmado item a item
pela auditoria), nunca timer.

5 textos × 5 perguntas por nível normal (25), 6 textos × 4 perguntas + 1 texto × 1
pergunta por nível Relâmpago (25) — inclui 3 diálogos entre dois falantes (um por nível
normal). Toda `correct_answer` é uma frase de 2+ palavras (nunca substantivo solto):
achado real da curadoria — Word Constellation é elegível pra QUALQUER território com
prefixo "ingles" (gate real é `voiceForTerritory() != null`, não
`IDIOMA_TERRITORY_IDS`), então uma resposta de 1 palavra quebraria com
`MEANING_NOT_EXTRACTABLE` nesse território também.

Curado e validado (Sentinela + auditoria `mental-content-consistency`, 150/150 itens
lidos integralmente); achados corrigidos: 1 opção de 1 palavra ("Cooking" → "Cooking
meals"), hint/explanation genéricos e literalmente falsos em 19 perguntas de inferência
(agora um par diferente, específico pra inferência), 1 texto abaixo do mínimo de 3
frases (expandido), 1 pergunta de inferência mal sustentada pelo texto (reformulada), 2
textos avançados sem nenhuma pergunta de inferência real (adicionada), 3 perguntas de
inferência que eram literais disfarçadas (reformuladas pra exigir dedução de verdade).
Suíte completa: 583/583.

**Pendência real, não implementada nesta rodada — precisa de decisão de Rhoney:** o
critério de aceite §8 ("diálogos... com áudio de duas vozes distintas") não existe em
NENHUM lugar do app hoje — nem pra este território nem pros outros já publicados.
`reading_passage` (em `challenge_screen.dart`) não tem nenhum botão de áudio, de
qualquer voz; o pré-carregamento de TTS (`_preloadTtsForChallenge`) só cobre
`prompt`/`options`, nunca `reading_passage`. Os 3 diálogos já publicados (Anna/Mike,
Rachel/Tom, Laura/Peter) estão em texto puro, sem áudio nenhum — não é um bug desta
frente especificamente, é uma funcionalidade que nunca existiu pra nenhuma "cápsula de
texto" do app. Implementar exigiria: (1) um botão de "ouvir o texto" pra qualquer
`reading_passage` (novo, nenhum território tem hoje), e (2) lógica de detectar o padrão
"Nome: fala" por linha e alternar entre 2 vozes por falante — trabalho de engenharia
real, não só curadoria de conteúdo. Aguardando decisão de Rhoney: implementar agora
(escopo maior, nova funcionalidade de áudio pra cápsulas de texto) ou aceitar o
território sem áudio de passagem por enquanto (como todos os outros territórios desse
mesmo mecanismo já publicados).
