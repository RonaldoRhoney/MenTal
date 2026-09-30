# MENTAL — Inglês: Palavras Compostas (Compound Words) e Contrações Informais

**Status:** APROVADO. Duas mecânicas exclusivas do idioma Inglês, nos três níveis (Básico/Intermediário/Avançado). Ambas reaproveitam o banco de vocabulário de **3.000 palavras, exclusivo ao Inglês** (MUNDO_IDIOMAS_BANCO_VOCABULARIO_1000_V1.md, escopo revisado em 26/09/2026 para não mais cobrir Espanhol e Francês nesta fase) como fonte primária — não buscar palavras novas e soltas fora desse banco. Volume inicial deliberadamente moderado, com expansão incremental planejada, para não sobrecarregar o carregamento do app.

---

## 1. Por que exclusivo do Inglês

Ambas as mecânicas descritas nesta especificação exploram fenômenos linguísticos característicos do inglês (formação direta de palavras compostas por justaposição, e contrações informais de fala rápida) que não têm equivalente direto e sistemático no português nem, necessariamente, nos demais idiomas do Mundo dos Idiomas. Por decisão de Rhoney, esta especificação cobre apenas o Inglês por enquanto — extensão a outros idiomas com fenômeno semelhante (ex.: alemão, também conhecido por palavras compostas) pode ser avaliada no futuro, como frente separada, não incluída aqui.

## 2. Mecânica 1 — Palavras Compostas (Compound Words)

### 2.1 Conceito
O usuário une duas palavras conhecidas para formar uma terceira palavra composta, com significado próprio — muitas vezes distinto da soma literal das duas partes. Exemplo dado por Rhoney: **gold** (ouro) + **fish** (peixe) = **goldfish** (peixinho dourado — não "peixe de ouro" no sentido literal, ilustrando que o significado composto pode divergir da tradução literal de cada parte).

### 2.2 Fonte das palavras
As palavras-base usadas para formar os compostos devem ser extraídas **do banco de vocabulário de 3.000 palavras em Inglês já formalizado** (MUNDO_IDIOMAS_BANCO_VOCABULARIO_1000_V1.md), priorizando palavras que genuinamente participam de compostos reais e comuns do inglês — não uma combinação artificial de quaisquer duas palavras do banco, e sim compostos reconhecidos e usados de fato no idioma.

### 2.3 Progressão por nível
- **Básico**: compostos mais comuns e transparentes (o significado da palavra composta é mais previsível a partir das duas partes — ex.: sunflower, football).
- **Intermediário**: compostos de uso comum, mas com significado menos óbvio a partir das partes isoladas.
- **Avançado**: compostos menos frequentes, mais idiomáticos, ou com significado mais distante da soma literal das partes (como o próprio exemplo "goldfish").

## 3. Mecânica 2 — Contrações Informais (Informal Contractions)

### 3.1 Conceito
O usuário aprende a reconhecer e usar as formas contraídas/informais comuns na fala rápida e coloquial do inglês, que não aparecem no inglês formal escrito. Exemplos dados por Rhoney: **going to → gonna**, **want to → wanna**. Outras formas do mesmo fenômeno, a critério do agente de curadoria incluir conforme relevância (ex.: got to → gotta, give me → gimme, let me → lemme, kind of → kinda).

### 3.2 Progressão por nível
- **Básico**: as contrações mais onipresentes e conhecidas (gonna, wanna).
- **Intermediário**: contrações comuns adicionais, com contexto de uso (formal vs. informal — quando é apropriado usar cada forma).
- **Avançado**: contrações menos óbvias ou mais regionais/coloquiais, incluindo nuance de registro (o quão informal cada forma soa, em que contexto social é apropriada).

## 4. Duplo propósito — Desafios jogáveis + base do MENTAL LINGO

Ambas as mecânicas seguem o mesmo princípio de duplo propósito já estabelecido para o banco de vocabulário e a conjugação verbal:
- Viram **Desafios e Relâmpagos jogáveis**, no padrão já usado no restante do app.
- Alimentam a **base de conhecimento do MENTAL LINGO** (MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md), para que o assistente por voz: (a) reconheça formas compostas e contrações informais quando o usuário as usar numa pergunta falada, sem tratá-las como erro ou termo desconhecido, e (b) seja capaz de utilizá-las nas próprias respostas quando apropriado ao contexto/nível do usuário.

## 5. Volume — moderado e incremental (decisão de Claude, conforme delegado por Rhoney)

Rhoney delegou explicitamente a escolha do volume a Claude, com a orientação de manter o banco inicial leve o suficiente para não pesar o carregamento do app, prevendo incrementos futuros graduais em vez de uma carga única muito grande.

**Volume inicial proposto, por mecânica, por nível:**
- **25 Desafios + 25 Relâmpagos por nível** (Básico/Intermediário/Avançado), no padrão de perguntas já usado nos demais Mundos (5 ou 20 perguntas por unidade).
- Por mecânica: 3 níveis × 50 unidades = 150 unidades. Duas mecânicas (Palavras Compostas + Contrações): **300 unidades no total**, nesta primeira entrega.
- **Expansão incremental planejada**: novos lotes de conteúdo para as mesmas mecânicas devem ser adicionados em ciclos futuros (a cadência exata a definir junto com o ritmo geral de produção de conteúdo do agente), em vez de tentar produzir um volume massivo de uma única vez — mesmo princípio já usado para evitar sobrecarregar a revisão humana em outras frentes desta expansão do Mundo dos Idiomas.

Este volume é uma proposta inicial de Claude, dentro da margem de decisão que Rhoney concedeu — pode ser ajustado por Claude Code durante o diagnóstico técnico, caso encontre razão prática para um número diferente (ex.: performance real observada, quantidade de compostos/contrações genuínas disponíveis no banco de vocabulário atual).

## 6. Delegação ao agente de curadoria e revisão em lotes

- Produção conduzida pelo agente autônomo de curadoria de conteúdo, extraindo palavras-base do banco de vocabulário já existente (não pesquisando palavras novas soltas), e redigindo todo o conteúdo de forma original.
- Revisão humana de Rhoney em lotes por mecânica/nível, seguindo o mesmo princípio já estabelecido nas demais frentes desta expansão.

## 7. Escopo técnico (a propor em detalhe por Claude Code)

- Confirmar tecnicamente a viabilidade de extrair, do banco de vocabulário de 3.000 palavras em Inglês, os pares que formam compostos reais e reconhecidos do idioma (pode exigir cruzamento com uma lista/fonte de referência de compostos comuns, para não gerar combinações artificiais sem sentido real).
- Propor a lista de contrações informais a incluir, além dos dois exemplos dados por Rhoney, com justificativa de relevância/frequência de uso.
- Confirmar/ajustar o volume proposto na seção 5 com base em avaliação técnica de performance de carregamento do banco.
- Integrar ambas as mecânicas à arquitetura de RAG do MENTAL LINGO, já referenciada nos documentos anteriores desta expansão.
- Propor a cadência dos ciclos de expansão incremental futura.

## 8. Critério de aceite

- Ambas as mecânicas implementadas nos três níveis, com o volume inicial definido na seção 5 (ou volume ajustado tecnicamente por Claude Code, com justificativa reportada a Rhoney).
- Palavras-base extraídas do banco de vocabulário já existente, não de fontes novas e soltas.
- Conteúdo integrado à base de conhecimento do MENTAL LINGO.
- Revisão e aprovação de Rhoney realizada em lotes, sem abrir mão da aprovação humana obrigatória.
- Estrutura preparada para expansão incremental futura, sem necessidade de recriar a arquitetura a cada novo lote.

## 9. Status de implementação (30/09/2026)

**Concluído, aguardando migration em produção.** Volume final: **25 Desafios + 25 Relâmpagos
por nível, por mecânica** (proposta da seção 5, confirmada), 12 territórios, 300 itens.
Mesmo padrão de Phrasal Verbs/Expressões/Conjugação: `block_id "ingles"` direto (não são
idiomas novos), migration 112 pronta (`backend/migrations/112_palavras_compostas_
contracoes.sql`), display_order contíguo (67-78) logo depois de Conjugação Verbal,
Espanhol/Francês empurrados pra 79-84.

Formato: enunciado em inglês (frase-exemplo usando a palavra composta/contração), opções são
o SIGNIFICADO em português (sempre 2+ palavras via sinônimos com "ou", nunca 1 palavra —
mesma regra de Phrasal Verbs/Expressões, evita o bug de Word Constellation). Voz das opções:
`ingles_compostas`/`ingles_contracoes` adicionados a `_kPortugueseOptionsTerritoryPrefixes`
em `idioma_voices.dart` (mesmo motivo — opção é o significado em PT, não a palavra
estrangeira).

Palavras-base curadas manualmente (compostos genuínos e reconhecidos do inglês; contrações
informais de uso corrente), não uma combinação artificial. Territórios Relâmpago usam
sujeito/frase-exemplo distintos dos territórios normais correspondentes (checado por
comparação cruzada de 100% dos prompts, não amostra).

Curado e validado (Sentinela + auditoria `mental-content-consistency`); achados corrigidos:
concordância de artigo "a"/"an" antes de som de vogal (a airport → an airport, e mais 14
palavras), substantivos incontáveis usados com artigo indefinido (a homework/a feedback →
sem artigo), molde "found near the house" aplicado a conceito abstrato/evento não-físico
(fallout, upshot, downturn — trocado por um molde seguro pra esses casos), duas palavras que
eram adjetivo, não substantivo ("indoor"/"outdoor", trocadas por "flashlight"/"doorknob"),
erro de concordância sujeito-verbo em "she hafta" (hafta vem foneticamente de "have to", só
funciona com I/we/you/they), ambiguidade visual de aspas em contrações com apóstrofo interno
("ain't"/"y'all"), auto-referência circular ("wrote about the notebook in his notebook"), e
duplicação de prompt entre território Relâmpago e normal correspondente (bancos de frases
totalmente separados agora). Suíte completa: 583/583.

**Nota sobre a seção 7 ("Integrar à arquitetura de RAG do MENTAL LINGO"):** não existe RAG/IA
generativa na arquitetura real do MENTAL LINGO hoje — decisão registrada de "V1 100% custo
zero" (ver `app/mental_lingo.py`, docstring). `IDIOMA_TERRITORY_IDS` e `ALWAYS_TIMED_
TERRITORIES` (`app/config.py`) já cobrem os 12 territórios, o que já é suficiente pro Lingo
reconhecer/consultar esse conteúdo pelo mecanismo de lookup direto já existente (mesmo
padrão das frentes anteriores).
