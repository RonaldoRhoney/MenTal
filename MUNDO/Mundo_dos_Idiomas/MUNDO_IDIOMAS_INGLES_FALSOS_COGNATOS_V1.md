# MENTAL — Inglês: Desafios de Falsos Cognatos (False Friends)

**Status:** APROVADO. Prioridade 2 das lacunas identificadas na análise de completude do Inglês (29/09/2026) — alto valor específico para falantes de português, universo de conteúdo naturalmente menor que outras frentes já formalizadas. Exclusivo ao Inglês por enquanto, mesma decisão de foco já aplicada às demais frentes desta expansão.

---

## 1. Objetivo

Criar conteúdo dedicado a **falsos cognatos** (false friends) — palavras em inglês que se parecem com palavras em português, mas têm significado diferente, e são fonte clássica e recorrente de erro para falantes brasileiros. Exemplos: "pretend" não é "pretender" (é fingir), "actually" não é "atualmente" (é na verdade/de fato), "push" não é "puxar" (é empurrar), "college" não é necessariamente "colégio" (costuma ser faculdade).

## 2. Volume e estrutura

- **25 Desafios + 25 Relâmpagos por nível** (Básico/Intermediário/Avançado) — volume mais enxuto que Phrasal Verbs/Expressões Idiomáticas (100+100), pois o universo de falsos cognatos amplamente reconhecidos e didaticamente relevantes entre português e inglês é naturalmente menor e mais finito.
- Por nível: 25 + 25 = 50 unidades. Total desta entrega: **150 unidades, exclusivamente em Inglês** (3 níveis × 50).
- Cada Desafio e cada Relâmpago segue o padrão de perguntas já usado no restante do app.
- **Expansão incremental futura prevista**, mesmo princípio já usado em Phrasal Verbs e Expressões Idiomáticas.

## 3. Critério de progressão por nível

- **Básico**: falsos cognatos mais notórios e de altíssima frequência de erro (pretend, actually, push, pull, parents, exquisite).
- **Intermediário**: falsos cognatos comuns, porém menos conhecidos (fabric, lecture, pretend, injury, sensible).
- **Avançado**: falsos cognatos mais sutis ou de uso mais técnico/formal (compromise usado em sentido diferente, eventually, notice como verbo).

## 4. Formato de pergunta — ênfase em evitar a armadilha, não só decorar

Diferente de vocabulário simples, o formato ideal aqui deve **testar ativamente se o usuário cairia na armadilha** — ex.: apresentar a palavra em inglês com alternativas de tradução incluindo o "falso amigo" óbvio (mas errado) como distrator proposital, forçando reconhecimento ativo da diferença, não apenas memorização passiva.

## 5. Integração com as mecânicas já formalizadas do Mundo dos Idiomas

- Compatível com Imersão Progressiva, Constelação de Palavras, regra de áudio vinculado ao elemento (MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md).
- Conexão com a base de conhecimento do MENTAL LINGO — o LINGO deve estar apto a alertar sobre falsos cognatos quando o usuário usar um de forma equivocada numa conversa.
- Elegível para o sistema de Repetição Espaçada (MUNDO_IDIOMAS_REPETICAO_ESPACADA_V1.md) assim que implementado — falsos cognatos são candidatos naturais a reaparecer com frequência, dado o padrão de erro recorrente que os caracteriza.

## 6. Delegação ao agente de curadoria e revisão em lotes

- Produção conduzida pelo agente autônomo de curadoria, com pesquisa em fontes linguísticas reconhecidas sobre falsos cognatos português-inglês.
- Revisão humana de Rhoney em lotes por nível, mesmo princípio já estabelecido nas demais frentes.

## 7. Critério de aceite

- 25 Desafios + 25 Relâmpagos de falsos cognatos em Inglês produzidos por nível, totalizando 150 unidades.
- Perguntas formuladas para testar reconhecimento ativo da armadilha, não apenas memorização.
- Conteúdo compatível com todas as mecânicas já formalizadas do Mundo dos Idiomas.
- Revisão e aprovação de Rhoney em lotes, sem abrir mão da aprovação humana obrigatória.

## 8. Status de implementação (30/09/2026)

**Concluído, aguardando migration em produção.** Migration 114 pronta
(`backend/migrations/114_falsos_cognatos.sql`), mesmo padrão block_id "ingles" direto,
display_order 91-96 contíguo. Opções em português (incluindo o "falso amigo" como
distrator proposital) — `ingles_falsoscognatos` adicionado a
`_kPortugueseOptionsTerritoryPrefixes` em `idioma_voices.dart`, mesmo padrão de Phrasal
Verbs/Expressões/Compostas/Contrações.

29 falsos cognatos genuínos curados (10 Básico, 10 Intermediário, 9 Avançado — batem com
os exemplos do próprio documento §3), cada um em 3-4 frases-exemplo distintas pra
completar 25 itens por território. Territórios Relâmpago usam frases totalmente
diferentes dos territórios normais (checado por comparação cruzada de 100% dos prompts).

Curado e validado (Sentinela + auditoria `mental-content-consistency`, 150/150 itens
lidos integralmente); achados corrigidos: "legend" trocado por "ordinary" (achado real —
"legend" tem dois sentidos genuínos em inglês, legenda de mapa E lenda/mito, então rotular
"lenda" como falso amigo sempre errado ensinaria uma regra factualmente falsa; "ordinary"
não tem essa ambiguidade), "exit"/"library" com significado específico demais pra frases
sem contexto de emergência/público ("a saída de emergência"/"a biblioteca pública" →
genéricos "a saída"/"a biblioteca"), distrator "puxar" (1 palavra, único no lote inteiro
de 150 itens) padronizado pra "puxar ou arrastar". Suíte completa: 582/583 (1 falha é
flakiness conhecida e documentada no próprio teste, `test_monthly_chart_aggregates_
per_day_and_flags_best_day`, que quebra nos primeiros dias do mês — não relacionada a
este conteúdo).
