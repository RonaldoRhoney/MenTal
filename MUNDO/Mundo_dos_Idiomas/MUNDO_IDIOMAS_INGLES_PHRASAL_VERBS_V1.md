# MENTAL — Inglês: Desafios de Phrasal Verbs (100 por nível)

**Status:** APROVADO. Exclusivo ao idioma Inglês, seguindo a mesma decisão de foco já aplicada ao Banco de Vocabulário (MUNDO_IDIOMAS_BANCO_VOCABULARIO_1000_V1.md), Conjugação Verbal (MUNDO_IDIOMAS_CONJUGACAO_VERBAL_V1.md) e Palavras Compostas/Contrações (MUNDO_IDIOMAS_INGLES_PALAVRAS_COMPOSTAS_E_CONTRACOES_V1.md). Produção delegada ao agente autônomo de curadoria, com revisão humana obrigatória em lotes.

---

## 1. Objetivo

Criar conteúdo dedicado a **phrasal verbs** (verbos frasais) do Inglês — combinações de verbo + partícula (preposição/advérbio) que formam um significado próprio, frequentemente distinto do verbo isolado (ex.: give up = desistir, não "dar para cima"; look after = cuidar de, não "olhar depois"). Fenômeno característico do inglês, com grande presença na fala cotidiana e frequentemente um dos pontos de maior dificuldade para falantes não-nativos.

## 2. Volume e estrutura

- **100 Desafios + 100 Relâmpagos por nível** (Básico/Intermediário/Avançado), seguindo exatamente a mesma estrutura já usada em Conjugação Verbal.
- Por nível: 100 + 100 = 200 unidades. Total desta entrega: **600 unidades, exclusivamente em Inglês** (3 níveis × 200).
- Cada Desafio e cada Relâmpago segue o padrão de perguntas já usado no restante do app (5 ou 20 perguntas por unidade).
- **Exclusivo ao Inglês por enquanto** — mesma decisão de foco já aplicada às demais frentes desta expansão. Expansão a outros idiomas com fenômeno equivalente (quando existir) fica para o futuro, não implementada agora.
- **"Futuramente mais serão implementados" (nota de Rhoney):** este volume inicial de 600 unidades não esgota o universo de phrasal verbs do inglês (que é extenso) — é uma primeira entrega robusta, com expansão incremental prevista em ciclos futuros, mesmo princípio já usado nas demais frentes desta expansão do Mundo dos Idiomas.

## 3. Critério de progressão por nível

Seguindo a mesma lógica pedagógica já estabelecida para Conjugação Verbal (repetição permitida entre níveis, com complexidade crescente) — o agente de curadoria deve propor a distribuição real, mas como orientação inicial:
- **Básico**: phrasal verbs mais comuns e transparentes, de uso frequente no dia a dia (ex.: wake up, get up, turn on/off).
- **Intermediário**: phrasal verbs comuns, mas com significado menos previsível a partir das partes isoladas (ex.: give up, look after, run into).
- **Avançado**: phrasal verbs menos frequentes, mais idiomáticos, com múltiplos significados possíveis conforme o contexto, ou phrasal verbs de três partes (ex.: come up with, get away with, look forward to).

## 4. Fonte das palavras — reaproveitar o banco já existente onde aplicável

Assim como já determinado para Palavras Compostas e Contrações: onde o verbo-base do phrasal verb já existir no banco de vocabulário de 3.000 palavras (MUNDO_IDIOMAS_BANCO_VOCABULARIO_1000_V1.md), o agente deve reaproveitá-lo como referência, em vez de introduzir vocabulário totalmente desconectado do que já existe no banco.

## 5. Integração com as mecânicas já formalizadas do Mundo dos Idiomas

Cada Desafio e Relâmpago de phrasal verbs deve nascer compatível com:
- Imersão Progressiva por nível de dificuldade (MUNDO_IDIOMAS_IMERSAO_PROGRESSIVA_V1.md).
- Constelação de Palavras como etapa complementar (MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md).
- Regra de áudio sempre vinculado ao elemento específico, nunca solto (MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md).
- Conexão com a base de conhecimento do MENTAL LINGO (MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md) — o LINGO deve reconhecer e ser capaz de usar phrasal verbs apropriadamente ao responder o usuário, e explicar seu significado quando solicitado.
- Verificação pelo Agente Sentinela de Conteúdo (AGENTE_SENTINELA_CONTEUDO_V1.md) — phrasal verbs com múltiplos significados conforme contexto são um ponto de atenção natural para inconsistência, então este conteúdo deve passar pela segunda camada de verificação normalmente.

## 6. Delegação ao agente de curadoria e revisão em lotes

- Produção conduzida pelo agente autônomo de curadoria de conteúdo, com pesquisa em fontes confiáveis (dicionários de phrasal verbs reconhecidos, materiais linguísticos estabelecidos), e redação original de todo conteúdo.
- Revisão humana de Rhoney em **lotes por nível** (ex.: "100 Desafios do Básico"), com amostragem representativa — mesmo princípio de adaptação de granularidade já usado nas demais frentes.

## 7. Escopo técnico (a propor em detalhe por Claude Code)

- Propor a lista de phrasal verbs por nível, com justificativa de frequência/relevância de uso.
- Confirmar tratamento de phrasal verbs com múltiplos significados (ex.: "get up" pode significar "levantar-se" ou "subir em algo", dependendo do contexto) — a pergunta deve deixar claro o contexto para evitar ambiguidade de resposta correta.
- Integrar a produção com a arquitetura de RAG do MENTAL LINGO.
- Definir o formato de lote de revisão e estimar prazo realista de produção.
- Propor a cadência dos ciclos de expansão incremental futura, conforme sinalizado por Rhoney.

## 8. Critério de aceite

- 100 Desafios + 100 Relâmpagos de phrasal verbs em Inglês produzidos por nível, totalizando 600 unidades.
- Progressão de complexidade por nível, de phrasal verbs mais transparentes/comuns a mais idiomáticos/complexos.
- Nenhuma pergunta ambígua quanto ao significado correto em casos de phrasal verb com múltiplos sentidos.
- Conteúdo compatível com todas as mecânicas já formalizadas do Mundo dos Idiomas.
- Revisão e aprovação de Rhoney realizada em lotes, sem abrir mão da aprovação humana obrigatória.
- Estrutura preparada para expansão incremental futura, conforme sinalizado por Rhoney.

## 9. Status de implementação (28/09/2026)

**Concluído e em produção.** Migrations 107 e 108 rodadas por Rhoney (a 108 corrige a
arquitetura de blocos: Phrasal Verbs não é um idioma novo, é conteúdo do idioma Inglês —
decisão de Rhoney, 27/09/2026 — então os 6 territórios entram no MESMO bloco "ingles" do
vocabulário, nunca num bloco próprio). Os 600 desafios (100 por território × 6 territórios:
Básico/Intermediário/Avançado normais + os mesmos 3 níveis em Relâmpago, sempre cronometrado
e com conteúdo distinto) foram curados, validados (Sentinela + agente
`mental-content-consistency`, todos os achados corrigidos) e carregados em produção. Nenhum
phrasal verb se repete entre os 6 territórios. `IDIOMA_TERRITORY_IDS` e
`ALWAYS_TIMED_TERRITORIES` (app/config.py) já cobrem os 6 territórios — Mental Lingo e
Constelação de Palavras funcionam com o novo conteúdo sem mudança de código adicional.
