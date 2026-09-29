# MENTAL — Inglês: Desafios de Expressões Idiomáticas (100 por nível)

**Status:** APROVADO. Exclusivo ao idioma Inglês, mesmo formato e estrutura já usados em Phrasal Verbs (MUNDO_IDIOMAS_INGLES_PHRASAL_VERBS_V1.md), Conjugação Verbal e Palavras Compostas/Contrações. Produção delegada ao agente autônomo de curadoria, com revisão humana obrigatória em lotes.

---

## 1. Objetivo

Criar conteúdo dedicado a **expressões idiomáticas** (idioms) do Inglês — expressões cujo significado não pode ser deduzido literalmente da soma de suas palavras (ex.: "break the ice" = quebrar o gelo/iniciar uma conversa, não literalmente quebrar gelo; "piece of cake" = algo muito fácil, não literalmente um pedaço de bolo). Fenômeno de alta relevância cultural e comunicativa, frequente na fala cotidiana e na mídia em inglês.

## 2. Volume e estrutura

- **100 Desafios + 100 Relâmpagos por nível** (Básico/Intermediário/Avançado), mesma estrutura já usada em Phrasal Verbs e Conjugação Verbal.
- Por nível: 100 + 100 = 200 unidades. Total desta entrega: **600 unidades, exclusivamente em Inglês** (3 níveis × 200).
- Cada Desafio e cada Relâmpago segue o padrão de perguntas já usado no restante do app (5 ou 20 perguntas por unidade).
- **Exclusivo ao Inglês por enquanto**, mesma decisão de foco já aplicada às demais frentes desta expansão. Expansão a outros idiomas fica para o futuro.
- **Expansão incremental futura prevista**, mesmo princípio já aplicado a Phrasal Verbs — este volume inicial não esgota o universo de expressões idiomáticas do inglês (que é extenso), sendo uma primeira entrega robusta com ciclos futuros de ampliação.

## 3. Critério de progressão por nível

Seguindo a mesma lógica pedagógica já estabelecida (progressão de transparência/complexidade crescente) — o agente de curadoria deve propor a distribuição real, mas como orientação inicial:
- **Básico**: expressões muito comuns e amplamente conhecidas, de uso frequente e reconhecível mesmo por iniciantes (ex.: piece of cake, break the ice, time flies).
- **Intermediário**: expressões comuns, mas com significado menos óbvio ou mais dependente de contexto cultural (ex.: hit the books, under the weather, cost an arm and a leg).
- **Avançado**: expressões menos frequentes, mais regionais/coloquiais, ou com nuance de registro (formal vs. informal) mais sutil, incluindo expressões que exigem conhecimento cultural mais profundo para uso apropriado.

## 4. Cuidado editorial — expressões com origem sensível

Algumas expressões idiomáticas têm origens históricas ou culturais que podem remeter a temas sensíveis (violência, discriminação histórica, referências religiosas). O agente de curadoria deve:
- Priorizar expressões de uso corrente, amplamente aceitas e sem controvérsia associada.
- Evitar expressões cuja origem ou uso atual possa ser considerado ofensivo, discriminatório ou inadequado, mesmo que ainda estejam em uso informal em algumas regiões.
- Em caso de dúvida sobre a adequação de uma expressão, o agente deve reportar o caso a Rhoney para decisão, em vez de incluir ou excluir unilateralmente.

## 5. Integração com as mecânicas já formalizadas do Mundo dos Idiomas

Cada Desafio e Relâmpago de expressões idiomáticas deve nascer compatível com:
- Imersão Progressiva por nível de dificuldade (MUNDO_IDIOMAS_IMERSAO_PROGRESSIVA_V1.md).
- Constelação de Palavras como etapa complementar (MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md).
- Regra de áudio sempre vinculado ao elemento específico, nunca solto (MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md).
- Conexão com a base de conhecimento do MENTAL LINGO (MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md) — o LINGO deve reconhecer expressões idiomáticas usadas pelo usuário, explicar seu significado quando solicitado, e ser capaz de usá-las apropriadamente ao contexto da conversa.
- Verificação pelo Agente Sentinela de Conteúdo (AGENTE_SENTINELA_CONTEUDO_V1.md) — expressões idiomáticas com nuance cultural são um ponto natural de atenção para revisão contínua.

## 6. Delegação ao agente de curadoria e revisão em lotes

- Produção conduzida pelo agente autônomo de curadoria de conteúdo, com pesquisa em fontes confiáveis (dicionários de expressões idiomáticas reconhecidos, materiais linguísticos estabelecidos), e redação original de todo conteúdo.
- Revisão humana de Rhoney em **lotes por nível** (ex.: "100 Desafios do Básico"), com amostragem representativa — mesmo princípio de adaptação de granularidade já usado nas demais frentes.

## 7. Escopo técnico (a propor em detalhe por Claude Code)

- Propor a lista de expressões idiomáticas por nível, com justificativa de frequência/relevância de uso e checagem de adequação editorial (seção 4).
- Integrar a produção com a arquitetura de RAG do MENTAL LINGO.
- Definir o formato de lote de revisão e estimar prazo realista de produção.
- Propor a cadência dos ciclos de expansão incremental futura.

## 8. Critério de aceite

- 100 Desafios + 100 Relâmpagos de expressões idiomáticas em Inglês produzidos por nível, totalizando 600 unidades.
- Progressão de complexidade por nível, de expressões mais transparentes/comuns a mais regionais/nuançadas.
- Nenhuma expressão de origem sensível ou controversa incluída sem revisão explícita de Rhoney.
- Conteúdo compatível com todas as mecânicas já formalizadas do Mundo dos Idiomas.
- Revisão e aprovação de Rhoney realizada em lotes, sem abrir mão da aprovação humana obrigatória.
- Estrutura preparada para expansão incremental futura.

## 9. Status de implementação (29/09/2026)

**Concluído e em produção.** Migration 110 pronta (`backend/migrations/110_expressoes_idiomaticas.sql`) — segue o
mesmo padrão de Phrasal Verbs (migrations 107-108): block_id "ingles" direto (Expressões Idiomáticas é conteúdo
do idioma Inglês, não um idioma novo), display_order contíguo logo depois de Phrasal Verbs, Espanhol/Francês
empurrados pra abrir espaço, evitando o bug de bloco partido em dois lugares da tela.

Os 600 desafios (100 por território × 6: Básico/Intermediário/Avançado normais + os mesmos 3 níveis em
Relâmpago, sempre cronometrado e com conteúdo distinto) foram curados, validados (Sentinela + agente
`mental-content-consistency`, todos os achados corrigidos — incluindo o mesmo problema sistêmico de calibração
de dificuldade já visto em Phrasal Verbs Avançado, corrigido nos dois territórios Avançado deste SubMundo) e
carregados em produção. Nenhuma expressão se repete entre os 6 territórios (600 expressões distintas no total).
Decisões editoriais sobre expressões de origem historicamente sensível (violência/religião, nenhuma
discriminatória) foram revisadas e confirmadas por Rhoney caso a caso — todas mantidas.

`IDIOMA_TERRITORY_IDS` e `ALWAYS_TIMED_TERRITORIES` (app/config.py) já cobrem os 6 territórios. As opções (em
português) são lidas com voz pt-BR, não a voz do idioma — ajuste feito em `client/lib/idioma_voices.dart` no
mesmo dia (pedido de Rhoney: "o app deve ler as frases em português, com entonação da língua português").
