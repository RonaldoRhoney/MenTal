# MENTAL — Mundo dos Idiomas: Mecânica Complementar "Constelação de Palavras"

**Status:** Fases 1 (backend/dados) e 2 (tela Flutter) IMPLEMENTADAS (19/09/2026). Nova mecânica de reforço prático, sequencial a cada Desafio do Mundo dos Idiomas — presente e futuro. Não é um modo isolado, é uma etapa complementar obrigatória ao final de cada Desafio dessa categoria.

## Decisões confirmadas com Rhoney (19/09/2026)
- Regra de seleção automática entre as 2 interações (§4): `correct_answer` com espaço → reconstrução por peças (§4.1); sem espaço → reconhecimento de significado (§4.2). Levantamento no conteúdo real confirmou 100% dos prompts de Idiomas seguem só 2 templates fixos ("Como se escreve 'X' em IDIOMA?" / "Traduza para o IDIOMA: 'X'"), permitindo extrair o significado em português por regex, sem ambiguidade.
- XP: +5 por acerto (igual resposta Média), só na 1ª conclusão correta por (usuário, desafio) — mesmo padrão anti-farm de Pausa para Aprender/Caça-palavras. Formalizado em REGRA_OFICIAL_GAMIFICACAO_MENTAL.md item 1.6. **Não implementa o teto diário de 150 XP** (essa infraestrutura ainda não existe no código, é um item separado e maior da própria Regra Oficial, ainda pendente de decisão de fases com Rhoney).

## Fase 1 — o que foi implementado (backend, sem UI ainda)
- `backend/migrations/079_word_constellation.sql` + `models.WordConstellationCompletion` — registro de 1ª conclusão por (usuário, desafio).
- `config.WORD_CONSTELLATION_XP_REWARD = 5`, `config.IDIOMA_TERRITORY_IDS` (registro explícito dos 9 territórios de idioma falado — Libras fica de fora, não usa TTS/palavra escrita).
- `services.generate_word_constellation_round` — gera a rodada (peças ou significado) direto do `Challenge.correct_answer`/`prompt`, com distratores de outros Desafios do MESMO território. Sem estado persistido: a correção sempre re-deriva do Challenge, nunca do que foi mostrado.
- `services.complete_word_constellation` — valida a resposta no servidor (nunca confia no client), credita XP (perfil + território) só na 1ª vez correta.
- `GET /challenges/{id}/word-constellation` e `POST /challenges/{id}/word-constellation/complete` — endpoints, gated a `IDIOMA_TERRITORY_IDS` (404 fora do Mundo dos Idiomas).
- Testes: `backend/tests/test_word_constellation.py` (6 testes — peças vs. significado, XP só 1x, resposta errada nunca paga, validação de ordem de peças, 404 fora de Idiomas). Suíte completa do backend sem regressão.

## Fase 2 — o que foi implementado (tela Flutter)
- `client/lib/screens/word_constellation_screen.dart` — tema de constelação/galáxia (fundo de estrelas, peças/opções em "pastilha" dourada/teal), sem nenhum elemento copiado do Duolingo (§5). Reutiliza `TtsService`/`idioma_voices.dart` já existentes (botão de áudio no mesmo padrão Duolingo do resto do app) e a mesma estrutura de seletor de velocidade.
- `client/lib/api/api_client.dart::wordConstellationRound/completeWordConstellation` — novos métodos.
- **Integração automática**: `challenge_screen.dart::_loadNextChallenge` intercepta ANTES de buscar o próximo desafio — se o território é de idioma falado (`voiceForTerritory != null`) e o jogador acabou de responder algo (não é a primeira carga da tela), abre a Constelação de Palavras primeiro. Nunca dispara em Batalha nem Relâmpago. Único ponto de interceptação — nenhum botão/call site precisou saber que essa etapa existe.
- Errar não bloqueia: "Tentar de novo" reseta a rodada; XP só é creditado na 1ª conclusão CORRETA (validado no backend).
- Testes: `client/test/word_constellation_screen_test.dart` (3 testes — rodada "pieces" certa/errada, rodada "meaning"). Suíte completa do client sem regressão (184/184).

## Próximos passos
- Aplicar a migration 079 em produção (feito — ver commit) e fazer o deploy do backend antes de testar em produção.
- Próximo build/AAB do client pra essa etapa aparecer de verdade nas contas reais.

---

## 1. Origem e referência

Rhoney trouxe três prints do Duolingo (telas de "Palavra Nova" com reconstrução de tradução por pastilhas de palavras, e seleção de significado correto) como referência de **mecânica**, não de identidade visual. A instrução explícita é: **não copiar a aparência do Duolingo** (mascotes, paleta, estilo de card) — usar a lógica de interação (reconstrução de frase/palavra com peças, reconhecimento de significado) traduzida para a identidade visual já estabelecida do MENTAL.

## 2. Nome de trabalho da mecânica

**"Constelação de Palavras"** (nome sugerido, ajustável por Rhoney antes da implementação final) — conecta tematicamente com a metáfora de Universo/Galáxia já em desenvolvimento para o Mapa de Trajetória (MAPA_TRAJETORIA_MUNDOS_V1.md), reforçando uma identidade visual coesa entre diferentes partes do app.

## 3. Posicionamento — complemento sequencial, nunca isolado

- Esta mecânica **não é um modo de jogo separado** que o usuário escolhe acessar isoladamente.
- Ela aparece **automaticamente como etapa final de cada Desafio já existente no Mundo dos Idiomas** — funcionando como o "capítulo de prática" que fecha o Desafio, depois das perguntas tradicionais de quiz.
- Aplica-se tanto aos Desafios **já publicados hoje** quanto a **qualquer Desafio futuro** do Mundo dos Idiomas — deve ser tratada como parte estrutural da experiência dessa categoria, não como conteúdo adicional avulso.
- O vocabulário/frases usados nesta etapa devem ser **extraídos do próprio conteúdo do Desafio que o usuário acabou de completar** — reforçando o que acabou de ser aprendido, não introduzindo vocabulário novo e desconexo.

## 4. Tipos de interação (baseados na lógica observada nos prints, com tratamento visual próprio)

### 4.1 Reconstrução de tradução por peças
- O app reproduz (via TTS, sob demanda) uma palavra ou frase no idioma estudado.
- O usuário monta a tradução correta tocando peças/blocos de palavras dispostos em ordem embaralhada, incluindo distratores plausíveis (palavras que não pertencem à resposta correta, como visto nos prints de referência).
- Aplica-se tanto a palavras isoladas quanto a frases completas, dependendo do que o Desafio de origem trabalhou.

### 4.2 Reconhecimento de significado
- O app reproduz uma palavra/expressão no idioma estudado.
- O usuário escolhe o significado correto entre algumas opções (múltipla escolha simples), reaproveitando o mesmo padrão de alternativas já usado no restante do MENTAL.

### 4.3 Regra de reprodução de áudio
Esta mecânica reutiliza integralmente o que já foi definido em MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md: TTS via `flutter_edge_tts`, áudio tocando apenas mediante clique explícito do usuário (nunca automático), com as 3 velocidades já definidas (normal, rápido, acelerado) disponíveis também nesta etapa.

## 5. Identidade visual — tema de constelação/galáxia, não mascotes

- Cada palavra/peça da reconstrução deve ser representada como um elemento temático de estrela/constelação (ex.: pastilhas com brilho sutil, conectando-se visualmente conforme o usuário acerta a ordem — remetendo à ideia de "desenhar uma constelação").
- Paleta de cores alinhada à identidade já estabelecida do MENTAL (dourado/teal/violeta sobre fundo escuro, conforme já usado no redesign do Splash e nas demais telas).
- Nenhum mascote ilustrado de personagem (diferente da referência do Duolingo) — a experiência deve ser reconhecível como parte do universo visual do MENTAL, não uma imitação de outro app.
- Efeito de dinamismo ao acertar: reforçar a sensação de conquista (linha de constelação se completando, brilho, pequena animação), na mesma linha de cuidado já pedida para o redesenho do Caça-palavras (CACA_PALAVRAS_BUG_E_VISUAL_V1.md) — o MENTAL está elevando o padrão de acabamento visual de forma consistente entre suas mecânicas.

## 6. Gamificação — integração com a Regra Oficial já vigente

- Esta etapa complementar deve gerar recompensa própria, a ser incorporada como nova linha na Regra Oficial de Gamificação (REGRA_OFICIAL_GAMIFICACAO_MENTAL.md), já vigente desde 18/09/2026.
- Sugestão de valor a validar com Rhoney antes de formalizar a atualização da Regra Oficial: XP equivalente ao de uma resposta correta de dificuldade Média (+5 XP) por acerto nesta etapa, respeitando o teto diário anti-farming já estabelecido (150 XP/dia).
- Qualquer valor definido aqui deve ser formalizado como revisão da Regra Oficial, conforme a seção de Governança daquele próprio documento (item 9) — não implementado como valor solto fora do documento central de gamificação.

## 7. Escopo técnico (a propor em detalhe por Claude Code)

- Desenhar o componente reutilizável de "Constelação de Palavras", parametrizado por idioma e por conteúdo do Desafio de origem, para que qualquer Desafio futuro do Mundo dos Idiomas já nasça com essa etapa complementar automaticamente, sem trabalho manual extra de configuração por Desafio.
- Integrar com a lógica de TTS já definida (`flutter_edge_tts`) para a reprodução de áudio nesta etapa.
- Aplicar essa etapa retroativamente a todos os Desafios já publicados no Mundo dos Idiomas, extraindo vocabulário/frases de cada um para compor sua respectiva rodada complementar.
- Propor a Rhoney o valor final de recompensa (seção 6) antes de codificar, para formalização na Regra Oficial de Gamificação.
- Validar performance e fluidez da interação de "montar por peças" no Flutter, com atenção à experiência em diferentes tamanhos de tela.

## 8. Critério de aceite

- Toda vez que o usuário conclui um Desafio do Mundo dos Idiomas, a etapa de Constelação de Palavras aparece automaticamente em sequência, usando vocabulário daquele mesmo Desafio.
- Áudio reproduzido apenas sob clique explícito, com as 3 velocidades disponíveis.
- Identidade visual coerente com o tema Universo/Galáxia do MENTAL, sem elementos copiados de outro app.
- Recompensa de XP formalizada como atualização da Regra Oficial de Gamificação antes de entrar em produção.
- Funciona tanto para Desafios já publicados (retroativo) quanto para qualquer Desafio novo criado no futuro, sem necessidade de configuração manual adicional.
