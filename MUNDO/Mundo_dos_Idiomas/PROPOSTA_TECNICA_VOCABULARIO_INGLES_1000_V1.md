# Proposta técnica — Vocabulário de Inglês (3.000 palavras) — Claude Code, 26/09/2026

Responde ao §6 de `MUNDO_IDIOMAS_BANCO_VOCABULARIO_1000_V1.md`. **Aguardando aprovação de Rhoney — nada produzido ainda.**

## 1. Situação real hoje (levantada no repositório)
- Inglês tem 3 territórios (`ingles_basico`, `ingles_intermediario`, `ingles_avancado`), cada um com 10 blocos × 5 palavras = **~50 palavras/nível (150 no total)**.
- Toda palavra é um Desafio com o template fixo `Como se escreve '<pt>' em inglês?` + 4 alternativas (1 correta + 3 grafias erradas plausíveis) + explicação `'<pt>' se traduz como '<en>' em inglês.`
- O Mental Lingo (V1, custo zero) já responde por **consulta exata a esse template** — então cada palavra nova do banco entra no Lingo automaticamente, sem RAG, sem IA generativa e sem custo.

## 2. Critério de nível (Básico / Intermediário / Avançado)
- Referência: frequência de uso e níveis CEFR (A1-A2 = Básico, B1-B2 = Intermediário, C1+ = Avançado), classificando por palavra **única** (sem repetir entre níveis, nem com as 150 já existentes).
- Limite honesto: o backend não tem lista de corpus offline nem acesso à web. A classificação será feita por mim, com base no meu conhecimento das listas de frequência/CEFR; **a validação por amostra é sua** (por isso a revisão em lote do documento).

## 3. Agrupamento
- Lotes de **100 palavras por tema** (ex.: Comida, Corpo, Trabalho, Viagem...), 10 lotes por nível = 30 lotes.
- Cada palavra = 1 Desafio no padrão atual (o app entrega 1 pergunta por vez), então os "Desafios" do documento correspondem a estes itens; o lote temático serve para produção e revisão.
- Destino: **acrescentar aos territórios existentes `ingles_*`** — não exige migration, nem mudança no app, nem novo APK; reaproveita adaptação de dificuldade, Constelação e Mental Lingo.
- Alternativa (não recomendo): territórios novos por tema — exigiria migration + registro no cliente + APK.

## 4. Fila de produção e revisão
1. Lote 1 = **100 palavras do Básico**, tema a tema, entregue em JSON de revisão em `MUNDO/Mundo_dos_Idiomas/vocabulario_ingles/` com a classificação e o critério.
2. Você valida por amostra e aprova; só então gero o JSON de carga, o Sentinela varre e você roda a carga (mesmo fluxo dos Concursos).
3. Repete lote a lote (o documento aceita revisão por lote, não por item).

## 5. Integração com o Mental Lingo (sem RAG)
- Já funciona por consulta direta ao vocabulário (item 1). "Montar frases sob demanda" exigiria modelo generativo (custo) — fica **fora**, conforme a regra de custo zero. O que dá para fazer sem custo: além de traduzir, responder a "use X em uma frase" com uma **frase-exemplo curada** por palavra (campo de explicação estendido) — proposta para a fase 2, sob sua aprovação.

## 6. Estimativa
Reconheço o volume (3.000 palavras): produzo ~100 palavras/lote com verificação de duplicidade (contra as 150 existentes e entre lotes). Os 30 lotes serão entregues em sequência conforme a sua revisão — o ritmo é o da sua aprovação, não o da produção.

## 7. Decisões que preciso de você
1. Aprova acrescentar aos territórios `ingles_*` existentes (recomendado)?
2. Aprova começar pelo Lote 1 (100 palavras Básico) para validar o padrão?

---

## Status (26/09/2026)
Aprovada por Rhoney (destino = territórios `ingles_*` existentes). **Básico: 1.000 palavras produzidas em 10 lotes de 100** (`backend/content/vocab_ingles_basico_lote1..10.json`; revisão em `MUNDO/Mundo_dos_Idiomas/vocabulario_ingles/LOTE<n>_BASICO_REVISAO.md`). Verificações por script: 1.000 respostas únicas, nenhuma colide com as 150 palavras anteriores, nenhuma alternativa errada é resposta correta de outro item, nenhuma palavra em inglês contida no próprio enunciado (cognatos removidos), sem grafias impróprias; Sentinela 0 itens; validador de carga sem erros. **Aguardando revisão de Rhoney antes da carga em produção.** Intermediário e Avançado: ainda não iniciados.
