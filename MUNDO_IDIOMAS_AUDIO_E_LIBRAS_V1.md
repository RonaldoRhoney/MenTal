# MENTAL — Mundo dos Idiomas: Áudio Fiel (TTS) e Reforço Visual em Libras

**Status:** IMPLEMENTADO (18/09/2026). Escopo do reconhecimento de fala do usuário (seção 5) permanece explicitamente fora — não implementado, como decidido.

## O que foi implementado

### Áudio TTS (§2) — completo, funcional de ponta a ponta
- `client/lib/services/tts_service.dart` — usa `flutter_edge_tts` (validado tecnicamente ANTES de integrar: síntese real testada em en-US/es-ES/fr-FR fora da suíte de testes, ~22KB de MP3 válido cada, sem erro/instabilidade na primeira rodada — nenhum sinal de rate limiting até agora). Reproduz via `audioplayers` (já usado pelo Ouvido Afiado, sem 2º player de áudio no app).
- `client/lib/idioma_voices.dart` — mapeia território → voz, genérico por design (§2.3): idioma novo = 1 linha nova, nenhuma outra tela muda.
- Botão de áudio por opção (ícone 🔊, `RadioListTile.secondary`) + seletor de velocidade (Normal/Rápido/Acelerado, sempre visível, nunca escondido em configurações) em `challenge_screen.dart`, só nos territórios de idioma falado — Libras e o resto do app continuam iguais.
- Sempre sob demanda (nunca automático), reutiliza uma única instância de player, falha nunca trava a tela.

### Reforço visual (§3, unificado com MUNDO_IDIOMAS_BIBLIOTECA_VISUAL_V1.md) — estrutura pronta, SEM curadoria de conteúdo ainda
- Schema genérico por idioma (`Challenge.vocab_media_url/type/source_name/source_url`, migration `078_challenge_vocab_media.sql`), tudo-ou-nada como `audio_url`, validado em `content_validation.py`.
- `challenge_screen.dart::_buildVocabMediaSection` — `image`/`gif` renderiza inline; `video` abre como overlay reaproveitando `showInstitutionalVideo` (mesmo player da Pausa para Aprender de Libras). Ausência do campo (a maioria dos desafios hoje) não muda nada na tela.
- **Curadoria de conteúdo real (fotos/GIFs por palavra, vídeos de sinal em Libras) NÃO foi feita nesta entrega** — isso é trabalho de conteúdo com licenciamento verificado item a item (§3 da spec de biblioteca visual), não algo que deva ser inventado/preenchido automaticamente. Fica como próximo passo, com a estrutura já pronta pra receber.

### Testes
- `client/test/idioma_voices_test.dart`, `client/test/challenge_screen_tts_test.dart`, `client/test/challenge_screen_vocab_media_test.dart` — todos passando, suíte completa (backend 434 + client 181) sem regressão.

## Migration pendente
`backend/migrations/078_challenge_vocab_media.sql` — precisa rodar contra o Postgres de produção (mesmo processo de sempre: `psql $DATABASE_URL -f migrations/078_challenge_vocab_media.sql`, ou via o método que você já usa pra aplicar migrations no Render).

---

## 1. Objetivo

Hoje o Mundo dos Idiomas não oferece um mecanismo de áudio fiel para palavras, frases e expressões nos idiomas falados (Inglês, Francês, Espanhol, e demais já existentes), nem reforço visual adequado para Libras (língua visual-espacial, sem componente sonoro). Este documento formaliza a correção dessas duas lacunas, com o padrão de rigor que a interação com o usuário nesse Mundo específico exige.

## 2. Escopo — Áudio para Idiomas Falados

### 2.1 Motor de TTS
- Pacote definido: **`flutter_edge_tts`** — gratuito, licença MIT, qualidade de voz natural (usa o motor de síntese neural do Microsoft Edge por baixo dos panos), com ampla cobertura de idiomas e variações regionais.
- Claude Code deve validar tecnicamente a integração antes de comprometer a arquitetura final, incluindo teste real de qualidade de voz nos idiomas prioritários do MENTAL.
- **Risco a monitorar**: `flutter_edge_tts` depende de um endpoint público não-oficial do Microsoft Edge. Não há custo direto, mas existe risco de instabilidade ou mudança de comportamento por parte da Microsoft no futuro, sem aviso prévio. Claude Code deve reportar esse risco a Rhoney se, durante a implementação, notar sinais de instabilidade (erros de conexão, rate limiting), para que uma alternativa de contingência (ex.: `flutter_tts` nativo) seja avaliada.

### 2.2 Comportamento de reprodução
- **O áudio nunca toca automaticamente.** A reprodução só ocorre mediante ação explícita do usuário (toque num botão/ícone de áudio associado à palavra, frase ou expressão).
- **Três níveis de velocidade de reprodução, controláveis pelo usuário**: normal, rápido e acelerado. O controle de velocidade deve ser visível e acessível junto ao botão de reprodução, não escondido em configurações.

### 2.3 Cobertura de idiomas
- **Todos os idiomas já existentes no Mundo dos Idiomas** recebem essa funcionalidade nesta rodada — não é um piloto restrito a um ou dois idiomas.
- A estrutura de dados e de código deve ser **genérica por design** (idioma como parâmetro/configuração, nunca hardcoded), de forma que adicionar um novo idioma no futuro seja trabalho de conteúdo (cadastrar palavras/frases), não de reengenharia de sistema.

## 3. Escopo — Reforço Visual em Libras

- Libras **não usa TTS** — é língua visual-espacial, sem componente sonoro. A leitura fiel de sinais em Libras é feita por **vídeo, GIF ou imagem sequencial** do sinal correto, nunca áudio.
- Retomar e aplicar a especificação já existente da **Biblioteca Visual para Idiomas** (documento anterior do projeto, MUNDO_IDIOMAS_BIBLIOTECA_VISUAL_V1.md), que já definia: vídeo/GIF obrigatório para Libras, abordagem em fases (piloto → demais idiomas → conteúdo novo já nascendo com visual), e curadoria com licença verificada individualmente por item.
- Claude Code deve unificar este documento com aquela especificação anterior antes de iniciar, evitando retrabalho ou contradição entre os dois.

## 4. Interação com o usuário — o que entra nesta entrega

Apenas o caso já viabilizado pelo TTS: o **app reproduz** a palavra/frase/expressão para que o usuário perceba a pronúncia correta (idiomas falados) ou veja o sinal correto (Libras, via vídeo/GIF). Essa é a interação central desta primeira entrega — o usuário ouve/vê o conteúdo correto, sob demanda, no ritmo que escolher.

## 5. Fora de escopo nesta entrega (evolução futura, decisão explícita de Rhoney)

O caso em que **o usuário fala e o app analisa/avalia a pronúncia dele** (reconhecimento de fala com avaliação de pronúncia) fica **fora desta primeira entrega**, por decisão explícita de Rhoney, dado o salto de complexidade técnica (processamento de áudio do microfone, serviços especializados de avaliação de pronúncia) e as implicações de privacidade sobre dados de voz do usuário que essa funcionalidade exigiria tratar com cuidado. Não implementar nada relacionado a captura/análise de voz do usuário nesta rodada — isso será retomado como projeto à parte no futuro.

## 6. Prioridade e prazo

Esta entrega é prioritária para **coincidir com a publicação mundial do MENTAL no Google Play** — ou seja, deve ser tratada como parte do pacote de qualidade da versão que vai ao ar globalmente, não como melhoria incremental posterior.

## 7. Escopo técnico (a detalhar por Claude Code)

- Integrar `flutter_edge_tts` ao projeto Flutter, validando qualidade de voz nos idiomas prioritários.
- Implementar o componente de reprodução de áudio sob demanda (clique do usuário) com seletor de 3 velocidades, reutilizável em qualquer tela do Mundo dos Idiomas onde haja conteúdo falado.
- Modelar a estrutura de dados de forma genérica por idioma, sem hardcoding.
- Unificar com a especificação da Biblioteca Visual para produzir/integrar vídeo, GIF ou imagem sequencial para cada sinal de Libras cadastrado, respeitando curadoria com licença verificada.
- Reportar a Rhoney qualquer instabilidade identificada no uso do `flutter_edge_tts` durante testes, antes de finalizar a integração.

## 8. Critério de aceite

- Usuário consegue tocar áudio de qualquer palavra/frase/expressão cadastrada nos idiomas falados, apenas mediante clique explícito, nunca automaticamente.
- Usuário consegue alternar entre as 3 velocidades de reprodução (normal, rápido, acelerado) livremente.
- Todos os idiomas já existentes no app têm a funcionalidade de áudio disponível, não apenas um subconjunto.
- Conteúdo de Libras cadastrado exibe vídeo/GIF/imagem fiel do sinal, sem nenhuma tentativa de áudio associada.
- Nenhuma funcionalidade de captura ou análise de voz do usuário foi implementada nesta entrega.
