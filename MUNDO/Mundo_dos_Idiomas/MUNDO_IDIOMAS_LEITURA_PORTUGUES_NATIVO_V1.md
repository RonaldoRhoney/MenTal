# MENTAL — Mundo dos Idiomas: Leitura do Português Sempre em Voz Nativa, Sem Entonação Inventada

**Status:** APROVADO. Regra estrutural aplicável a todo o Mundo dos Idiomas — Inglês, Espanhol, Francês e qualquer idioma futuro aderido. Complementa MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md e MENTAL_IDIOMAS_ENTONACAO_TTS_URGENTE_V1.md.

---

## 1. Problema a prevenir

No Mundo dos Idiomas, uma mesma tela de pergunta frequentemente mistura **português** (o enunciado, ex.: "Como se escreve 'triste' em inglês?") com o **idioma-alvo** sendo estudado (ex.: as alternativas "Sad", "Sed", "Saad"). Rhoney determinou explicitamente que **todo trecho em língua portuguesa**, em qualquer parte do Mundo dos Idiomas, deve ser lido com **voz nativa de português**, sem nenhuma entonação inventada ou artificial — nunca com sotaque, cadência ou prosódia emprestada do idioma estrangeiro que está sendo estudado naquela tela.

## 2. Regra

- **Todo texto em português** (enunciados, instruções, rótulos, qualquer conteúdo que esteja em português na tela) deve ser lido com uma **voz nativa de português do Brasil**, com pronúncia e entonação naturais do próprio idioma português — nunca uma leitura "estrangeirizada" ou com influência de sotaque do idioma-alvo daquela tela específica.
- Isso vale de forma idêntica para **todos os idiomas-alvo** do Mundo dos Idiomas: Inglês, Espanhol, Francês, e qualquer idioma futuro que venha a ser adicionado — o português nunca muda sua forma de ser lido em função de qual idioma está sendo ensinado ao lado dele.
- **Nenhuma entonação inventada**: o motor de TTS não deve aplicar ênfases, pausas dramáticas ou variações de tom que não correspondam à leitura natural e neutra de um enunciado em português — a leitura deve soar como uma pessoa nativa lendo aquele texto normalmente, não uma interpretação teatral ou artificialmente entonada.

## 3. Relação com a correção de entonação já solicitada para os idiomas estrangeiros

Este documento trata do lado **português** da equação. O documento MENTAL_IDIOMAS_ENTONACAO_TTS_URGENTE_V1.md já trata do lado **estrangeiro** (garantir que "car", "I will" etc. sejam lidos com entonação natural do inglês/espanhol/francês, não robótica ou apressada). Juntos, os dois documentos garantem que **cada trecho de texto seja lido com a voz e a prosódia certas do seu próprio idioma** — português como português, idioma-alvo como idioma-alvo, sem contaminação entre os dois em nenhuma direção.

## 4. Escopo técnico (a propor em detalhe por Claude Code)

- Confirmar que a integração atual do `flutter_edge_tts` já realiza a troca correta de voz/locale conforme o idioma de cada trecho de texto (português vs. idioma-alvo), dentro da mesma tela de pergunta.
- Auditar todas as telas do Mundo dos Idiomas (em todos os idiomas já existentes) em busca de qualquer trecho em português sendo lido com voz ou configuração de locale incorreta.
- Garantir que essa detecção de idioma por trecho funcione de forma genérica e automática (por análise do próprio texto/campo, não por configuração manual por pergunta), para que qualquer conteúdo futuro (novos idiomas, novos Desafios) já nasça correto sem exigir ajuste manual adicional.
- Reportar a Rhoney qualquer caso encontrado durante a auditoria antes de aplicar correção em massa.

## 5. Critério de aceite

- Todo texto em português, em qualquer tela do Mundo dos Idiomas (Inglês, Espanhol, Francês, e futuros idiomas), é lido com voz nativa de português, sem sotaque emprestado do idioma-alvo.
- Nenhuma entonação artificial ou inventada é aplicada à leitura do português.
- Comportamento validado de forma consistente em todos os idiomas do Mundo dos Idiomas, não apenas num deles.

## 6. Status de implementação (29/09/2026)

**Auditoria concluída — nenhuma violação encontrada, nenhuma correção necessária.** A regra já estava
satisfeita antes mesmo deste documento existir, por dois motivos:

1. **O enunciado em português nunca é lido em voz alta** em nenhuma tela do Mundo dos Idiomas
   (`ChallengePromptText` em `challenge_screen.dart` é só texto, sem botão de áudio) — só as
   alternativas/tiles interativos têm som, e sempre via `voiceForTerritory()` (`idioma_voices.dart`),
   que já resolve a voz certa por conteúdo real de cada trecho (idioma estrangeiro nas opções-palavra
   dos territórios clássicos de vocabulário; português nas opções-significado de Phrasal Verbs e
   Expressões Idiomáticas, desde o ajuste do mesmo dia pedido por Rhoney: "o app deve ler as frases em
   português, com entonação da língua português").
2. **Constelação de Palavras** (`word_constellation_screen.dart`) reaproveita a mesma função
   `voiceForTerritory()` — herdou a correção automaticamente, sem precisar de nenhuma mudança própria.
   **Mental Lingo** já separava por trecho (`speech_segments`) desde antes.
3. `tts_service.dart` só ajusta velocidade via SSML (`<prosody rate="...">`) — nenhuma ênfase, pausa
   dramática ou entonação inventada é aplicada em nenhum trecho, português ou estrangeiro.

Arquivos auditados: `client/lib/screens/challenge_screen.dart`,
`client/lib/screens/word_constellation_screen.dart`, `client/lib/screens/mental_lingo_screen.dart`,
`client/lib/idioma_voices.dart`, `client/lib/services/tts_service.dart`. Nenhuma alteração de código foi
necessária além da já feita em `idioma_voices.dart` no mesmo dia.
