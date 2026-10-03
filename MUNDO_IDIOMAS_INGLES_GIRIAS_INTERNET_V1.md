# MENTAL — Inglês: Gírias e Inglês Informal de Internet

**Status:** EM IMPLEMENTAÇÃO (03/10/2026) — aprovado por Rhoney. Mecanismo completo já implementado e testado (migration 119 já rodada em produção, formato MCQ padrão sem mudança de client, backend 606/606 passando, commit `aeb5476`) — conteúdo ainda só no lote1 (90 de até 180 unidades previstas em §2), aguardando revisão de Rhoney antes dos próximos lotes. Mover para `MUNDO/Mundo_dos_Idiomas/` só quando o volume de conteúdo estiver completo.

---

## 1. Objetivo

Diferente de Expressões Idiomáticas (expressões fixas e "atemporais" — MUNDO_IDIOMAS_INGLES_EXPRESSOES_IDIOMATICAS_V1.md), este documento cobre abreviações de chat/mensagem (lol, idk, tbh, omg, brb) e gírias contemporâneas de internet/redes sociais (lowkey, no cap, bet, ghosting, simp, rizz, delulu). É o inglês que um usuário brasileiro mais encontra fora de sala de aula — redes sociais, jogos, streaming, mensagens — e hoje não existe conteúdo nenhum cobrindo isso no MENTAL. Lacuna real, sem sobreposição com conteúdo já existente.

## 2. Volume e estrutura

- **30 Desafios + 30 Relâmpagos por nível** (Básico/Intermediário/Avançado) — volume intermediário entre o enxuto de Falsos Cognatos (25+25, universo mais finito) e o volume cheio das frentes de gramática (100+100): o universo de gírias relevantes e didaticamente estáveis é maior que falsos cognatos, mas menor que uma categoria gramatical inteira.
- Por nível: 30 + 30 = 60 unidades. Total: **180 unidades, exclusivamente em Inglês** (3 níveis × 60).
- Cada Desafio testa reconhecimento ativo do significado em contexto, com distratores plausíveis — nunca só a definição literal isolada.

## 3. Critério de progressão por nível

- **Básico**: abreviações de chat/mensagem de uso mais universal e estável (lol, idk, tbh, omg, brb, asap, fyi).
- **Intermediário**: gírias de internet/geração Z já consolidadas no uso cotidiano em texto e fala casual (lowkey, highkey, no cap, bet, ghosting, simp, flex).
- **Avançado**: gírias mais nichadas ou de cultura de internet/meme (rizz, delulu, "it's giving...", touch grass, mid, based) — com curadoria mais criteriosa, dado o risco de volatilidade (ver §8).

## 4. Formato de pergunta — reconhecimento ativo em contexto

Mesmo espírito de Falsos Cognatos (§4 daquele documento): apresentar a gíria dentro de uma frase/mensagem de contexto real (ex.: print de chat simulado em texto), com alternativas de significado incluindo um distrator plausível (interpretação literal errada da gíria, quando aplicável) — nunca pedir só a definição de dicionário isolada.

## 5. Integração com as mecânicas já formalizadas do Mundo dos Idiomas

- Compatível com Imersão Progressiva, Constelação de Palavras, regra de áudio vinculado ao elemento.
- Conexão com a base de conhecimento do MENTAL LINGO — o LINGO deve reconhecer e explicar gírias quando o usuário as usar ou perguntar sobre elas numa conversa.
- Elegível para Repetição Espaçada assim que a UI de revisão existir.

## 6. Delegação ao agente de curadoria e revisão em lotes

- Produção conduzida pelo agente autônomo de curadoria, com pesquisa em fontes atualizadas de gíria de internet em inglês (não fontes acadêmicas tradicionais, que tendem a estar desatualizadas nesse domínio específico).
- Revisão humana de Rhoney em lotes por nível — **atenção redobrada nesta frente**: gíria data rápido, e a curadoria deve favorecer termos com uso sustentado (não modismo passageiro de uma semana), evitando que o conteúdo pareça datado poucos meses depois de publicado.

## 7. Critério de aceite

- 30 Desafios + 30 Relâmpagos de gírias/inglês informal de internet por nível, totalizando 180 unidades.
- Toda gíria apresentada em contexto real de uso (mensagem/chat simulado), nunca só definição isolada.
- Progressão de complexidade/raridade clara entre os três níveis.
- Revisão e aprovação de Rhoney em lotes, sem abrir mão da aprovação humana obrigatória.

## 8. Risco conhecido — desatualização de conteúdo

Esta é a frente de conteúdo com **maior risco de desatualização rápida** de todo o Mundo dos Idiomas — gíria de internet muda mais rápido que vocabulário/gramática tradicional. Registrado aqui como risco conhecido, não como algo a resolver agora: não implementar nenhum mecanismo de revisão periódica automática nesta entrega — fica como nota para uma eventual revisão futura de conteúdo, a critério de Rhoney.
