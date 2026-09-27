# MENTAL — Inglês: Banco de Vocabulário de 1000 Palavras por Nível (Alimentando o MENTAL LINGO)

**Status:** APROVADO. Escopo revisado por Rhoney em 26/09/2026 — **exclusivo ao idioma Inglês nesta fase**, não mais aos três idiomas simultaneamente. Produção delegada ao agente autônomo de curadoria, com revisão humana obrigatória em lotes (não item a item, dado o volume). Conecta-se diretamente à base de conhecimento do MENTAL LINGO (MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md).

---

## 1. Objetivo

Criar um banco de vocabulário massivo para o **Inglês**, com duplo propósito: (a) virar Desafios jogáveis no padrão já existente do app, e (b) alimentar a base de conhecimento do MENTAL LINGO, ampliando sua capacidade de reconhecer e **construir frases sob demanda** a partir do vocabulário disponível, quando o usuário pedir isso durante uma conversa por voz.

## 2. Volume e estrutura

- **1000 palavras no nível Básico + 1000 no Intermediário + 1000 no Avançado = 3.000 palavras, exclusivamente em Inglês.**
- As 3.000 palavras são **mutuamente exclusivas entre os três níveis** — sem repetição entre Básico, Intermediário e Avançado. Cada palavra pertence a um único nível, definido pela complexidade/frequência de uso real da palavra no idioma.
- **Escopo revisado (26/09/2026): esta entrega cobre apenas o Inglês.** Espanhol e Francês ficam explicitamente **fora desta fase** — Rhoney avaliou que o volume original (9.000 palavras, cobrindo os três idiomas simultaneamente) era grande demais para uma primeira entrega, e decidiu concentrar o esforço no Inglês primeiro.
- **Expansão futura planejada**: Rhoney já sinaliza a intenção de replicar este mesmo banco de vocabulário para Espanhol e Francês **no futuro**, como uma frente separada e posterior — não implementar isso agora, apenas manter a arquitetura genérica por idioma (já estabelecida nos documentos anteriores) pronta para receber essa expansão quando for decidida.
- **Volume total desta entrega: 3.000 itens de vocabulário** (não mais 9.000).

## 3. Formato de entrega — Desafios jogáveis

- As palavras devem ser organizadas em **Desafios**, seguindo o padrão já estabelecido no restante do app (agrupamento em unidades jogáveis, não uma lista corrida de 1000 itens numa tela só) — Claude Code e o agente de curadoria devem propor o agrupamento (ex.: quantos Desafios por nível, quantas palavras por Desafio), compatível com o padrão de volume já usado em outros Mundos.
- Cada Desafio gerado a partir deste banco deve já nascer compatível com as mecânicas já formalizadas para o Mundo dos Idiomas: Imersão Progressiva por nível de dificuldade (MUNDO_IDIOMAS_IMERSAO_PROGRESSIVA_V1.md), Constelação de Palavras como etapa complementar (MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md), Reconhecimento Visual via Canva no nível Média (MUNDO_IDIOMAS_RECONHECIMENTO_VISUAL_V1.md), e a regra de áudio sempre vinculado ao elemento específico, nunca solto (MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md).

## 4. Conexão direta com a base de conhecimento do MENTAL LINGO

- Este banco de vocabulário não é apenas conteúdo estático de Desafio — deve ser estruturado de forma **pesquisável e recombinável** pelo mecanismo de RAG (ou equivalente) já especificado na seção "Base de conhecimento" de MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md.
- Com esse vocabulário ampliado (3.000 palavras em Inglês), o MENTAL LINGO passa a ter matéria-prima suficiente para **construir frases originais sob demanda** em Inglês, combinando palavras do banco quando o usuário pedir isso numa conversa por voz (ex.: "monte uma frase com as palavras X e Y", ou pedidos abertos de prática).
- Este mesmo banco é também a fonte de palavras-base para as mecânicas de Palavras Compostas e Contrações Informais, já formalizadas separadamente em MUNDO_IDIOMAS_INGLES_PALAVRAS_COMPOSTAS_E_CONTRACOES_V1.md.
- Claude Code deve propor, no diagnóstico técnico já exigido em MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md, como esse banco de vocabulário se integra tecnicamente à camada de RAG do LINGO — não são dois sistemas isolados, é uma única base de conhecimento compartilhada entre o conteúdo jogável (Desafios) e o assistente conversacional (LINGO).

## 5. Delegação ao agente de curadoria e revisão humana em lotes

- Produção conduzida pelo **agente autônomo de curadoria de conteúdo**, seguindo o mesmo princípio já estabelecido em MUNDO_IDIOMAS_NOVOS_TEMAS_AGENTE_V1.md — pesquisa de vocabulário real e relevante, classificação por nível de dificuldade, e redação original de qualquer conteúdo de apoio (frases de exemplo, explicações).
- **Dado o volume (3.000 itens), a revisão humana de Rhoney ocorre em lotes representativos, não item a item.** Isso significa: o agente entrega o material organizado por nível (ex.: "1000 palavras do Básico de Inglês"), com amostragem clara e critério de classificação explicado, para que Rhoney valide o padrão de qualidade e a correção da classificação por nível em cada lote, sem precisar revisar as 3.000 palavras individualmente.
- Isso não abre mão do princípio de revisão humana obrigatória — apenas adapta a granularidade da revisão à escala real do trabalho, mantendo Rhoney como aprovador final de cada lote antes de publicação.

## 6. Escopo técnico (a propor em detalhe por Claude Code)

- Propor o critério técnico de classificação de palavras por nível (Básico/Intermediário/Avançado) — ex.: frequência de uso na língua inglesa, listas de referência linguística reconhecidas (ex.: listas de frequência de corpus, CEFR).
- Propor o agrupamento de palavras em Desafios jogáveis (quantidade por Desafio, quantidade de Desafios resultantes por nível).
- Propor a arquitetura de integração entre o banco de vocabulário e a camada de RAG do MENTAL LINGO.
- Definir o formato de lote de revisão a ser entregue a Rhoney (amostragem, critério de classificação, forma de aprovação por lote).
- Estimar prazo realista de produção para o volume total, considerando capacidade do agente e ritmo de revisão em lotes.
- Manter a estrutura de dados genérica por idioma (já estabelecida em documentos anteriores), para que a futura expansão a Espanhol e Francês não exija reengenharia — apenas repetição do mesmo processo quando Rhoney decidir avançar com ela.

## 7. Critério de aceite

- Banco de vocabulário de 3.000 palavras em Inglês produzido, com os três níveis mutuamente exclusivos entre si.
- Vocabulário organizado em Desafios jogáveis, compatíveis com todas as mecânicas já formalizadas do Mundo dos Idiomas.
- Base de vocabulário integrada tecnicamente à camada de RAG do MENTAL LINGO, permitindo construção de frases sob demanda em Inglês.
- Revisão e aprovação de Rhoney realizada em lotes por nível, não item a item, sem abrir mão do princípio de aprovação humana obrigatória.
- Nenhum conteúdo publicado em produção sem essa aprovação em lote.
- Espanhol e Francês permanecem fora desta entrega — nenhuma produção de vocabulário para esses dois idiomas deve ocorrer sob este documento.
