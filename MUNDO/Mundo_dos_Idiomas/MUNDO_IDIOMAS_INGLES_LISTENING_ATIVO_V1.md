# MENTAL — Inglês: Listening Ativo (compreensão auditiva)

**Status:** EM IMPLEMENTAÇÃO (03/10/2026) — aprovado por Rhoney, decisão de escopo §8 confirmada (áudio só sob toque, nunca automático). Mecanismo completo já implementado e testado (migration 117, `Challenge.audio_script`, botão dedicado no client, backend 606/606 e client 263/263 passando, commit `aa097b0`) — conteúdo ainda só no lote1 (90 de até 600 unidades previstas em §2), aguardando revisão de Rhoney antes dos próximos lotes. Movido pra MUNDO/Mundo_dos_Idiomas/ (03/10/2026) — mecanismo implementado e testado já é suficiente, não é preciso esperar o volume total de conteúdo.

---

## 1. Objetivo

Hoje o único uso de áudio no Mundo dos Idiomas é TTS **sob demanda**, pra confirmar a pronúncia de uma palavra/frase que o usuário já está vendo escrita na tela (MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md). Não existe nenhum formato onde o usuário **ouve primeiro, sem o texto visível**, e responde só com base no que ouviu — a habilidade que apps de referência (Duolingo, Babbel) tratam como pilar separado de leitura, e tipicamente a mais fraca de um falante de português autodidata. Este documento propõe fechar essa lacuna.

## 2. Volume e estrutura

- **100 Desafios + 100 Relâmpagos por nível** (Básico/Intermediário/Avançado), mesmo volume das frentes centrais de gramática já formalizadas (Phrasal Verbs, Preposições e Artigos) — a habilidade é central o suficiente pra justificar o mesmo investimento.
- Por nível: 100 + 100 = 200 unidades. Total: **600 unidades, exclusivamente em Inglês** (3 níveis × 200).
- Cada item é um áudio curto (1-3 frases, TTS) + uma pergunta de compreensão sobre o que foi dito — nunca uma transcrição literal (testar entendimento, não memória ortográfica).

## 3. Critério de progressão por nível

- **Básico**: uma frase curta e simples, ritmo de fala um pouco mais lento/claro (mesma voz TTS já usada hoje). Pergunta de compreensão direta (ex.: "o que a pessoa pediu?").
- **Intermediário**: frases um pouco mais longas, ritmo de fala natural. Pode incluir uma pergunta que exige inferência simples (não só repetição literal do que foi dito).
- **Avançado**: diálogo curto entre duas vozes (reaproveitando o padrão já usado em Compreensão de Texto pra diálogos), ritmo natural, podendo incluir expressão idiomática ou phrasal verb já coberto em outras frentes.

## 4. Formato de pergunta — áudio antes do texto, sempre

- O áudio toca (automaticamente ao abrir o Desafio, ou via toque explícito — decisão de UX a confirmar com Rhoney) **antes** de qualquer texto da pergunta aparecer.
- O usuário pode reouvir o áudio quantas vezes quiser antes de responder (sem penalidade — diferente de um teste de ouvido único).
- As alternativas de resposta são sempre **texto** (nunca áudio) — o teste é compreender o que foi dito, não decorar o som das opções.
- Nunca pedir transcrição literal palavra por palavra — sempre uma pergunta de compreensão sobre o conteúdo (o quê, quem, quando, por quê), igual ao espírito das perguntas de Compreensão de Texto, mas a partir do que foi OUVIDO, não lido.

## 5. Integração com as mecânicas já formalizadas do Mundo dos Idiomas

- Reaproveita 100% o motor de TTS já em produção (MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md) — nenhuma infraestrutura de áudio nova.
- **Territórios NEVER_TIMED** (mesma decisão de arquitetura já aplicada a Compreensão de Texto): ouvir contra o relógio contraria o propósito do exercício — o usuário precisa do tempo real de reprodução do áudio, e apressar isso prejudica a compreensão genuína. "Relâmpago" aqui significa áudio mais curto/menos perguntas, nunca timer.
- `correct_answer` sempre 2+ palavras (regra do Word Constellation, mesma lição de todas as frentes anteriores).
- Elegível para Repetição Espaçada assim que a UI de revisão existir (backend já pronto).

## 6. Delegação ao agente de curadoria e revisão em lotes

- Produção conduzida pelo agente autônomo de curadoria — frases/diálogos curtos, com atenção a não usar vocabulário fora do que já foi coberto nas frentes anteriores (evitar introduzir palavra nova sem contexto de apoio).
- Revisão humana de Rhoney em lotes por nível, mesmo princípio já estabelecido nas demais frentes.

## 7. Critério de aceite

- 100 Desafios + 100 Relâmpagos de Listening Ativo em Inglês por nível, totalizando 600 unidades.
- Áudio sempre toca antes de qualquer texto da pergunta/alternativas ficar visível.
- Pergunta sempre de compreensão (nunca transcrição literal).
- Territórios marcados NEVER_TIMED.
- Revisão e aprovação de Rhoney em lotes, sem abrir mão da aprovação humana obrigatória.

## 8. Decisão em aberto para Rhoney

Antes de iniciar a implementação: confirmar se o áudio deve tocar **automaticamente** ao abrir o Desafio, ou só **sob toque explícito** do usuário (mesmo padrão do TTS sob demanda já usado hoje). Reprodução automática é mais fiel ao formato "listening" de apps de referência, mas é uma mudança de comportamento em relação a tudo que já existe no app (onde áudio nunca toca sozinho).
