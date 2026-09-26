# MENTAL — Mundo dos Idiomas: Desafios de Conjugação Verbal (100 por nível, por idioma)

**Status:** APROVADO. Produção delegada ao agente autônomo de curadoria, com revisão humana obrigatória em lotes, mesmo princípio já estabelecido para o banco de vocabulário (MUNDO_IDIOMAS_BANCO_VOCABULARIO_1000_V1.md) e para o Mundo da Linguagem (MUNDO_LINGUAGEM_ARQUITETURA_V1.md).

---

## 1. Objetivo

Criar conteúdo dedicado à conjugação verbal para cada idioma do Mundo dos Idiomas, cobrindo os três níveis de dificuldade já usados no app (Básico, Intermediário, Avançado).

## 2. Volume e estrutura

- **100 Desafios + 100 Relâmpagos por nível**, seguindo o mesmo padrão de escala já usado no Mundo da Linguagem (ex.: Crase = 25+25; conjugação verbal, por ser um eixo maior de conteúdo, recebe volume próprio de 100+100 por nível).
- Por nível (Básico/Intermediário/Avançado): 100 Desafios + 100 Relâmpagos = 200 unidades. Total por idioma: **600 unidades** (3 níveis × 200). Aplica-se a todos os idiomas já existentes no Mundo dos Idiomas (Inglês, Espanhol, Francês) e a idiomas futuros, seguindo a arquitetura genérica por idioma já estabelecida.
- Cada Desafio e cada Relâmpago segue o padrão de perguntas já usado no restante do app (5 ou 20 perguntas por unidade, conforme o padrão já estabelecido nos demais Mundos).

## 3. Critério de progressão por nível — repetição de verbo permitida, com complexidade crescente

Diferente do banco de vocabulário simples (onde cada palavra pertence a um único nível, sem repetição), a conjugação verbal segue uma lógica pedagógica distinta, confirmada por Rhoney: **o mesmo verbo pode aparecer em múltiplos níveis**, desde que o **tempo verbal ou modo cobrado mude e aumente em complexidade** a cada nível. Exemplo ilustrativo (não prescritivo — o agente de curadoria deve propor a distribuição real de tempos verbais por nível, por idioma):
- **Básico**: verbos comuns em tempos simples (ex.: presente simples, passado simples).
- **Intermediário**: os mesmos verbos comuns (e outros adicionais) em tempos compostos ou mais elaborados (ex.: presente perfeito, futuro composto, formas contínuas/progressivas).
- **Avançado**: os mesmos verbos em modos mais complexos (ex.: subjuntivo, condicional, voz passiva, formas irregulares menos comuns).

Isso reflete como métodos de ensino de idioma normalmente organizam conjugação verbal na prática — repetição do mesmo verbo com complexidade crescente, não uma lista de verbos totalmente exclusiva por nível.

## 4. Integração com as mecânicas já formalizadas do Mundo dos Idiomas

Cada Desafio e Relâmpago de conjugação verbal deve nascer compatível com:
- Imersão Progressiva por nível de dificuldade (MUNDO_IDIOMAS_IMERSAO_PROGRESSIVA_V1.md).
- Constelação de Palavras como etapa complementar (MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md).
- Regra de áudio sempre vinculado ao elemento específico, nunca solto (MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md).
- Conexão com a base de conhecimento do MENTAL LINGO (mesma lógica já estabelecida para o banco de vocabulário em MUNDO_IDIOMAS_BANCO_VOCABULARIO_1000_V1.md) — o vocabulário verbal e os tempos praticados também devem alimentar a capacidade do LINGO de construir e corrigir frases envolvendo conjugação, quando solicitado pelo usuário.

## 5. Delegação ao agente de curadoria e revisão em lotes

- Produção conduzida pelo agente autônomo de curadoria de conteúdo, com pesquisa em fontes gramaticais confiáveis por idioma, e redação original de todo conteúdo (nunca cópia literal).
- Revisão humana de Rhoney em **lotes por idioma/nível** (ex.: "100 Desafios do Básico de Espanhol"), com amostragem representativa e critério de progressão de tempos verbais explicado — mesmo princípio de adaptação de granularidade já usado no banco de vocabulário, dado o volume total (1.800 unidades: 600 por idioma × 3 idiomas).

## 6. Escopo técnico (a propor em detalhe por Claude Code)

- Propor, por idioma, a distribuição concreta de tempos/modos verbais por nível (a tabela da seção 3 é ilustrativa, não final).
- Propor quantos verbos distintos compõem a base de cada nível, e como a repetição entre níveis é distribuída (quantos verbos do Básico reaparecem no Intermediário, e assim por diante).
- Integrar a produção com a arquitetura de RAG do MENTAL LINGO, já referenciada no banco de vocabulário.
- Definir o formato de lote de revisão a ser entregue a Rhoney, e estimar prazo realista de produção para o volume total.

## 7. Critério de aceite

- 100 Desafios + 100 Relâmpagos de conjugação verbal produzidos por nível, por idioma, seguindo a estrutura da seção 2.
- Progressão de complexidade por nível seguindo o princípio da seção 3 (repetição de verbo permitida, com tempo/modo mais complexo a cada nível).
- Conteúdo compatível com todas as mecânicas já formalizadas do Mundo dos Idiomas.
- Revisão e aprovação de Rhoney realizada em lotes por idioma/nível, sem abrir mão da aprovação humana obrigatória.
- Nenhum conteúdo publicado em produção sem essa aprovação em lote.
