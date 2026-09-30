# MENTAL — Inglês: Desafios de Conjugação Verbal (100 por nível)

**Status:** APROVADO. Escopo revisado por Rhoney em 26/09/2026 — **exclusivo ao idioma Inglês por enquanto**, não mais aos três idiomas simultaneamente. Produção delegada ao agente autônomo de curadoria, com revisão humana obrigatória em lotes, mesmo princípio já estabelecido para o banco de vocabulário (MUNDO_IDIOMAS_BANCO_VOCABULARIO_1000_V1.md) e para o Mundo da Linguagem (MUNDO_LINGUAGEM_ARQUITETURA_V1.md).

---

## 1. Objetivo

Criar conteúdo dedicado à conjugação verbal para o **Inglês**, cobrindo os três níveis de dificuldade já usados no app (Básico, Intermediário, Avançado).

## 2. Volume e estrutura

- **100 Desafios + 100 Relâmpagos por nível**, seguindo o mesmo padrão de escala já usado no Mundo da Linguagem (ex.: Crase = 25+25; conjugação verbal, por ser um eixo maior de conteúdo, recebe volume próprio de 100+100 por nível).
- Por nível (Básico/Intermediário/Avançado): 100 Desafios + 100 Relâmpagos = 200 unidades. **Total desta entrega: 600 unidades, exclusivamente em Inglês** (3 níveis × 200).
- **Escopo revisado (26/09/2026): esta entrega cobre apenas o Inglês.** Espanhol e Francês ficam explicitamente **fora desta fase**, alinhado com a mesma decisão já tomada para o banco de vocabulário — Rhoney concentra o esforço no Inglês primeiro.
- **Expansão futura planejada**: Rhoney sinaliza intenção de replicar esta mesma estrutura de conjugação verbal para Espanhol e Francês **no futuro**, como frente separada e posterior — não implementar agora, apenas manter a arquitetura genérica por idioma (já estabelecida nos documentos anteriores) pronta para receber essa expansão quando for decidida.
- Cada Desafio e cada Relâmpago segue o padrão de perguntas já usado no restante do app (5 ou 20 perguntas por unidade, conforme o padrão já estabelecido nos demais Mundos).

## 3. Critério de progressão por nível — repetição de verbo permitida, com complexidade crescente

Diferente do banco de vocabulário simples (onde cada palavra pertence a um único nível, sem repetição), a conjugação verbal segue uma lógica pedagógica distinta, confirmada por Rhoney: **o mesmo verbo pode aparecer em múltiplos níveis**, desde que o **tempo verbal ou modo cobrado mude e aumente em complexidade** a cada nível. Exemplo ilustrativo (não prescritivo — o agente de curadoria deve propor a distribuição real de tempos verbais por nível):
- **Básico**: verbos comuns em tempos simples (ex.: presente simples, passado simples).
- **Intermediário**: os mesmos verbos comuns (e outros adicionais) em tempos compostos ou mais elaborados (ex.: presente perfeito, futuro composto, formas contínuas/progressivas).
- **Avançado**: os mesmos verbos em modos mais complexos (ex.: subjuntivo, condicional, voz passiva, formas irregulares menos comuns).

Isso reflete como métodos de ensino de idioma normalmente organizam conjugação verbal na prática — repetição do mesmo verbo com complexidade crescente, não uma lista de verbos totalmente exclusiva por nível.

## 4. Integração com as mecânicas já formalizadas do Mundo dos Idiomas

Cada Desafio e Relâmpago de conjugação verbal deve nascer compatível com:
- Imersão Progressiva por nível de dificuldade (MUNDO_IDIOMAS_IMERSAO_PROGRESSIVA_V1.md).
- Constelação de Palavras como etapa complementar (MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md).
- Regra de áudio sempre vinculado ao elemento específico, nunca solto (MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md).
- Conexão com a base de conhecimento do MENTAL LINGO (mesma lógica já estabelecida para o banco de vocabulário em MUNDO_IDIOMAS_BANCO_VOCABULARIO_1000_V1.md) — o vocabulário verbal e os tempos praticados também devem alimentar a capacidade do LINGO de construir e corrigir frases envolvendo conjugação em Inglês, quando solicitado pelo usuário.

## 5. Delegação ao agente de curadoria e revisão em lotes

- Produção conduzida pelo agente autônomo de curadoria de conteúdo, com pesquisa em fontes gramaticais confiáveis, e redação original de todo conteúdo (nunca cópia literal).
- Revisão humana de Rhoney em **lotes por nível** (ex.: "100 Desafios do Básico de Inglês"), com amostragem representativa e critério de progressão de tempos verbais explicado — mesmo princípio de adaptação de granularidade já usado no banco de vocabulário, dado o volume total (600 unidades).

## 6. Escopo técnico (a propor em detalhe por Claude Code)

- Propor a distribuição concreta de tempos/modos verbais por nível, em Inglês (a tabela da seção 3 é ilustrativa, não final).
- Propor quantos verbos distintos compõem a base de cada nível, e como a repetição entre níveis é distribuída (quantos verbos do Básico reaparecem no Intermediário, e assim por diante).
- Integrar a produção com a arquitetura de RAG do MENTAL LINGO, já referenciada no banco de vocabulário.
- Definir o formato de lote de revisão a ser entregue a Rhoney, e estimar prazo realista de produção para o volume total.
- Manter a estrutura de dados genérica por idioma (já estabelecida em documentos anteriores), para que a futura expansão a Espanhol e Francês não exija reengenharia.

## 7. Critério de aceite

- 100 Desafios + 100 Relâmpagos de conjugação verbal em Inglês produzidos por nível, seguindo a estrutura da seção 2.
- Progressão de complexidade por nível seguindo o princípio da seção 3 (repetição de verbo permitida, com tempo/modo mais complexo a cada nível).
- Conteúdo compatível com todas as mecânicas já formalizadas do Mundo dos Idiomas.
- Revisão e aprovação de Rhoney realizada em lotes por nível, sem abrir mão da aprovação humana obrigatória.
- Nenhum conteúdo publicado em produção sem essa aprovação em lote.
- Espanhol e Francês permanecem fora desta entrega — nenhuma produção de conjugação verbal para esses dois idiomas deve ocorrer sob este documento.

## 8. Status de implementação (29/09/2026)

**Concluído, aguardando migration em produção.** Mesmo padrão de Phrasal Verbs/Expressões Idiomáticas:
block_id "ingles" direto (não é idioma novo), migration 111 pronta
(`backend/migrations/111_conjugacao_verbal.sql`), display_order contíguo logo depois de
Expressões Idiomáticas (55-60), Espanhol/Francês empurrados pra 61-66.

Formato: cada item pede pra completar uma frase em inglês com lacuna, e as opções são
"sujeito + forma verbal completa" (ex.: "she had gone", "it is written", "I will go") — nunca
o verbo isolado, pra não cair no mesmo bug de Word Constellation com `correct_answer` de 1
palavra só (já visto em Phrasal Verbs/Expressões).

Distribuição de tempos/modos por nível (proposta técnica de Claude, dentro da margem
delegada pela seção 6): Básico = presente/passado simples + futuro (will/going to);
Intermediário = presente/passado contínuo + presente perfeito + futuro contínuo; Avançado =
passado perfeito + voz passiva + 2º/3º condicional + modais perfeitos (should/could have).
~40-80 verbos de alta frequência reaparecem entre níveis com tempo/modo mais complexo, como
pedido na seção 3.

Os 600 desafios (100 por território × 6: Básico/Intermediário/Avançado normais + os mesmos 3
níveis em Relâmpago, sempre cronometrado e com verbos/frases distintos dos territórios
normais) foram curados, validados (Sentinela + duas rodadas do agente
`mental-content-consistency`) e todos os achados corrigidos: verbo estativo em tempo
contínuo ("I am needing"), frases sem objeto natural ("you gave last night"), voz passiva
com verbo intransitivo ("it is gone"/"it is woken" — corrigida com uma lista de verbos
seguros pra voz passiva), erro ortográfico em distrator ("it trys"→"it tries"), distrator
fora de padrão em modal perfeito, e dificuldade calibrada por categoria gramatical (não mais
ciclo mecânico desconectado do conteúdo). Suíte completa: 582/582.

`IDIOMA_TERRITORY_IDS` e `ALWAYS_TIMED_TERRITORIES` (app/config.py) já cobrem os 6
territórios. Voz das opções: prefixo "ingles" já cai na voz em inglês por padrão (correto
aqui — diferente de Phrasal Verbs/Expressões, as opções desta frente SÃO a forma verbal em
inglês, não o significado em português — nenhum ajuste em `idioma_voices.dart` foi
necessário).

Falta: Rhoney rodar a migration 111 em produção e carregar os 6 arquivos de conteúdo via
`append_production_content.py` (mesmo fluxo de deploy manual já usado nas frentes
anteriores).
