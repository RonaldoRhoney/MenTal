# MENTAL — Inglês: Desafios de Preposições e Artigos (100 por nível)

**Status:** APROVADO. Quarto documento da análise de completude do Inglês (29/09/2026). Exclusivo ao Inglês por enquanto, mesma decisão de foco já aplicada às demais frentes desta expansão. Mesmo formato e volume já usados em Phrasal Verbs e Expressões Idiomáticas.

---

## 1. Objetivo

Criar conteúdo dedicado a **preposições** (in/on/at, for/since, by/until, entre outras) e **artigos** (a/an/the, e a ausência de artigo em generalizações) do inglês — uma das maiores fontes de erro recorrente para falantes de português, já que o uso de preposições em inglês frequentemente não segue lógica direta de tradução, e o uso de artigos tem regras que divergem do português em casos comuns (ex.: "I like coffee", sem artigo, para generalização; "at night" mas "in the morning").

## 2. Volume e estrutura

- **100 Desafios + 100 Relâmpagos por nível** (Básico/Intermediário/Avançado), mesmo volume já usado em Phrasal Verbs e Expressões Idiomáticas, dado que o universo de regras e exceções de preposições/artigos é extenso o suficiente para justificar esse volume.
- Por nível: 100 + 100 = 200 unidades. Total desta entrega: **600 unidades, exclusivamente em Inglês** (3 níveis × 200).
- Cada Desafio e cada Relâmpago segue o padrão de perguntas já usado no restante do app.
- **Expansão incremental futura prevista**, mesmo princípio já usado nas demais frentes desta expansão do Mundo dos Idiomas.

## 3. Critério de progressão por nível

- **Básico**: preposições de tempo e lugar mais comuns e diretas (in/on/at com dias, horários, lugares); uso básico de a/an/the.
- **Intermediário**: preposições dependentes de verbo (regência preposicional — ex.: "depend on", "listen to", "look for"); artigos em casos menos óbvios (generalizações, nomes de instituições).
- **Avançado**: preposições em expressões fixas e menos previsíveis (ex.: "by mistake", "on purpose", "in charge of"); casos de artigo mais sutis (uso de "the" com superlativos, nomes geográficos específicos).

## 4. Formato de pergunta — foco em contexto, não regra isolada

Como preposições em inglês raramente seguem regra memorizável de forma isolada, o formato de pergunta deve sempre apresentar a preposição/artigo **dentro de uma frase com contexto completo**, nunca como escolha abstrata sem frase — reforçando reconhecimento de padrão de uso real, não decoreba de regra solta.

## 5. Integração com as mecânicas já formalizadas do Mundo dos Idiomas

- Compatível com Imersão Progressiva, Constelação de Palavras, regra de áudio vinculado ao elemento (MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md).
- Conexão com a base de conhecimento do MENTAL LINGO — o LINGO deve ser capaz de corrigir e explicar erros de preposição/artigo quando o usuário os cometer numa conversa, já que este é um dos erros mais frequentes de falantes de português.
- Elegível para o sistema de Repetição Espaçada (MUNDO_IDIOMAS_REPETICAO_ESPACADA_V1.md) assim que implementado — preposições são candidatas naturais a reaparecer com frequência, dado o padrão de erro recorrente e a dificuldade de fixação que as caracteriza.

## 6. Delegação ao agente de curadoria e revisão em lotes

- Produção conduzida pelo agente autônomo de curadoria, com pesquisa em fontes gramaticais confiáveis sobre uso de preposições e artigos em inglês.
- Revisão humana de Rhoney em lotes por nível, mesmo princípio já estabelecido nas demais frentes — atenção especial nesta frente, dado que preposições têm alta incidência de exceção e nuance, exigindo revisão cuidadosa de cada frase de contexto.

## 7. Critério de aceite

- 100 Desafios + 100 Relâmpagos de preposições e artigos em Inglês produzidos por nível, totalizando 600 unidades.
- Toda pergunta apresenta a preposição/artigo dentro de frase com contexto completo, nunca isolada.
- Progressão de complexidade clara entre os três níveis.
- Conteúdo compatível com todas as mecânicas já formalizadas do Mundo dos Idiomas.
- Revisão e aprovação de Rhoney em lotes, sem abrir mão da aprovação humana obrigatória.

## 8. Status de implementação (02/10/2026)

**Concluído, aguardando migration em produção.** Migration 115 pronta
(`backend/migrations/115_preposicoes_artigos.sql`), mesmo padrão block_id "ingles"
direto, display_order 103-108 contíguo (Espanhol/Francês empurrados para 109-114).
Opções em inglês (texto da frase, não tradução) — não precisou de entrada em
`_kPortugueseOptionsTerritoryPrefixes` em `idioma_voices.dart`, já cobertas pelo
mapeamento padrão de voz `en-US-AriaNeural` por prefixo "ingles".

600 itens curados (100 por território × 6 territórios: Básico/Intermediário/Avançado ×
normal/Relâmpago), gerados por templates próprios (tempo in/on/at, lugar in/on/at,
regência preposicional verbo+preposição, expressões fixas, artigos a/an/the/ausência,
superlativo, nomes geográficos com/sem "the") com pool de sujeitos/substantivos/verbos
cruzados programaticamente.

Curado e validado (Sentinela + auditoria `mental-content-consistency`, 600/600 itens
lidos integralmente, com instrução extra para procurar bugs sistêmicos de geração por
template dado o volume). Achados corrigidos nesta rodada:
- Concordância verbal sujeito-verbo em blocos de regência preposicional e de "dream of
  becoming" (ex.: "My sister congratulate" → "congratulates", "They dreams of becoming"
  → "They dream of becoming") — introduzido helper `_conj()`.
- Sujeito plural/coletivo + profissão no singular (ex.: "The company trained to be an
  accountant", "They trained to be a journalist") — restringido a lista de sujeitos
  elegíveis para esses templates a indivíduos singulares reais.
- Verbo "consist" removido de todos os usos (gerava "Students consist in balance" sem
  sentido) — substituído por verbos semanticamente seguros (hope for/qualify for/strive
  for).
- Pessoa comparada a objeto via superlativo com cópula "is" (ex.: "He is the most
  reliable car I know", "She is the brightest hotel in the school") — listas de
  substantivos trocadas por papéis de pessoa em todos os blocos afetados.
- Mistura de contêiner/terreno incompatível em superlativo (ex.: "largest country in the
  city") e verbo específico de água com terreno não-aquático ("sailed across the Gobi
  Desert" → "traveled through the Gobi Desert").
- Verbo concreto ("bought"/"saw"/"found") + substantivo abstrato/incompatível em
  artigo a/an (ex.: "bought an hour", "bought an accident", "found an orange juice") —
  substantivos trocados por objetos fisicamente plausíveis de comprar/ver/achar.
- Nota de variação dialetal adicionada à explicação do item "hospital" em
  `intermediario.py` (regra de ausência de artigo é britânica; americano aceita "the
  hospital" no mesmo sentido) em vez de apresentar como regra universal.
- Achado da auditoria "190/600 itens com opção de 1 palavra" verificado e descartado
  como falso alarme: a restrição real do Word Constellation (`services.py`) só olha
  `correct_answer`, nunca `options` — confirmado por script de verificação direta, 0
  violações reais nos 600 itens.
- Duplicata de prompt em `avancado.py` (bloco GEO_ZERO_2 repetia a mesma frase 6×) —
  corrigida associando cada país a uma estação/época diferente.

Verificação final pós-fix: 0 prompts duplicados entre os 6 arquivos, `correct_answer`
sempre 2+ palavras nos 600 itens, Sentinela limpo nos 6 territórios, suíte completa do
backend 583/583.
