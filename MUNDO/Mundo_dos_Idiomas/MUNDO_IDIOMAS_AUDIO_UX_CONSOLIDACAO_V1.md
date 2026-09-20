# MENTAL — Mundo dos Idiomas: Áudio Fiel (TTS) e Reforço Visual em Libras

**Status:** PARCIALMENTE IMPLEMENTADO (19/09/2026) — consolidação seleção+áudio do §2.2.1 feita; o destaque visual customizado de "bloco único" (fim do §2.2.1) NÃO foi feito, ver "Não implementado nesta rodada" abaixo. Escopo do reconhecimento de fala do usuário (ver seção 5) fica explicitamente fora desta entrega — registrado como evolução futura, não implementar agora.

## O que foi implementado nesta rodada (§2.2.1)

- `client/lib/screens/challenge_screen.dart` — o `onChanged` do `RadioGroup` de alternativas (territórios de idioma falado) agora também dispara `_speakOption` na mesma ação que seleciona a alternativa, eliminando o toque isolado que era necessário antes. O ícone de áudio de cada alternativa continua funcional, agora como replay (não altera a seleção já feita).
- Junto desta entrega, também foi resolvida a reclamação separada de Rhoney sobre demora no áudio ("está com uma certa demora, ajuste para que seja ao toque"): `client/lib/services/tts_service.dart` ganhou cache em memória (texto+voz+velocidade → MP3) e um método `preload()` chamado assim que a pergunta/rodada carrega (enunciado + alternativas em `challenge_screen.dart`; enunciado + peças em `word_constellation_screen.dart`), sem tocar nada — só deixa o áudio pronto em cache pro toque real. Nunca viola a regra de "áudio só sob clique explícito".
- **Não implementado nesta rodada:** o destaque visual "bloco único coeso" (mesmo container/estado de destaque entre alternativa e ícone) descrito no fim do §2.2.1 — o `RadioListTile` padrão já agrupa título+ícone numa mesma linha/tile, mas não foi feito um tratamento visual customizado além disso. Se Rhoney achar insuficiente ao testar, é um ajuste visual pontual a retomar.
- Testes: suíte completa do client (188/188) sem regressão.

---

## 1. Objetivo

Hoje o Mundo dos Idiomas não oferece um mecanismo de áudio fiel para palavras, frases e expressões nos idiomas falados (Inglês, Francês, Espanhol, e demais já existentes), nem reforço visual adequado para Libras (língua visual-espacial, sem componente sonoro). Este documento formaliza a correção dessas duas lacunas, com o padrão de rigor que a interação com o usuário nesse Mundo específico exige.

## 2. Escopo — Áudio para Idiomas Falados

### 2.1 Motor de TTS
- Pacote definido: **`flutter_edge_tts`** — gratuito, licença MIT, qualidade de voz natural (usa o motor de síntese neural do Microsoft Edge por baixo dos panos), com ampla cobertura de idiomas e variações regionais.
- Claude Code deve validar tecnicamente a integração antes de comprometer a arquitetura final, incluindo teste real de qualidade de voz nos idiomas prioritários do MENTAL.
- **Risco a monitorar**: `flutter_edge_tts` depende de um endpoint público não-oficial do Microsoft Edge. Não há custo direto, mas existe risco de instabilidade ou mudança de comportamento por parte da Microsoft no futuro, sem aviso prévio. Claude Code deve reportar esse risco a Rhoney se, durante a implementação, notar sinais de instabilidade (erros de conexão, rate limiting), para que uma alternativa de contingência (ex.: `flutter_tts` nativo) seja avaliada.

### 2.2 Comportamento de reprodução
- **O áudio nunca toca automaticamente sem interação do usuário.** A reprodução ocorre mediante ação explícita do usuário — e essa ação explícita passa a ser, preferencialmente, **a própria seleção da alternativa de resposta**, não um toque isolado num ícone separado (ver seção 2.2.1, ajuste de UX de 19/09/2026).
- **Três níveis de velocidade de reprodução, controláveis pelo usuário**: normal, rápido e acelerado. O controle de velocidade deve ser visível e acessível junto ao botão de reprodução, não escondido em configurações.

### 2.2.1 Ajuste de UX — seleção e reprodução de áudio consolidadas numa única ação (19/09/2026)

**Problema identificado por Rhoney, a partir de teste real do fluxo em produção:** no fluxo original, o usuário precisava de 3 toques separados para completar uma pergunta com áudio — (1) tocar no ícone de áudio para ouvir a alternativa, (2) tocar no círculo de seleção da alternativa, (3) tocar em "Confirmar resposta". Essa separação era redundante e aumentava desnecessariamente a quantidade de cliques e o tempo de interação.

**Novo comportamento definido:**
- **Ao tocar em qualquer alternativa de resposta** (a área completa do item — círculo de seleção, texto e ícone de áudio tratados como um único elemento clicável), duas ações ocorrem simultaneamente: a alternativa é selecionada **e** seu áudio é reproduzido automaticamente na velocidade atualmente ativa (normal, rápido ou acelerado).
- O ícone de áudio (speaker) permanece visível ao lado de cada alternativa, mas sua função passa a ser de **replay** — se o usuário quiser ouvir novamente antes de confirmar, ele pode tocar especificamente no ícone sem alterar a seleção já feita.
- A confirmação da resposta continua exigindo um toque separado no botão "Confirmar resposta", como já acontece hoje — este ajuste não elimina essa etapa, apenas consolida as duas primeiras em uma só.
- **Esclarecimento sobre a regra da seção 2.2**: este comportamento continua respeitando o princípio de "nenhum áudio automático sem interação do usuário" — o toque na alternativa É a ação explícita do usuário; o ajuste apenas reaproveita esse mesmo toque para dois efeitos (seleção + áudio) em vez de exigir dois toques separados para o mesmo resultado prático.

**Ajuste visual complementar (também solicitado por Rhoney):** o botão/área de cada alternativa e seu respectivo ícone de áudio devem ser **alinhados e tratados visualmente como um bloco único e coeso** (ex.: mesmo container, mesmo estado de destaque ao tocar), para que o usuário perceba claramente, só de olhar, que selecionar a alternativa e ouvir seu áudio são a mesma ação — não dois elementos independentes um do lado do outro por coincidência de layout.

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

- Usuário consegue ouvir o áudio de qualquer alternativa ao tocar nela, com a seleção e a reprodução ocorrendo na mesma ação (não mais dois toques separados).
- Ícone de áudio de cada alternativa continua funcional como opção de replay, sem alterar a seleção já feita.
- Botão de alternativa e ícone de áudio visualmente alinhados como um único bloco coeso, comunicando claramente que é uma ação conjunta.
- Confirmação da resposta continua exigindo toque explícito no botão "Confirmar resposta".
- Usuário consegue alternar entre as 3 velocidades de reprodução (normal, rápido, acelerado) livremente, com a velocidade ativa sendo respeitada também na reprodução automática ao selecionar.
- Todos os idiomas já existentes no app têm a funcionalidade de áudio disponível, não apenas um subconjunto.
- Conteúdo de Libras cadastrado exibe vídeo/GIF/imagem fiel do sinal, sem nenhuma tentativa de áudio associada.
- Nenhuma funcionalidade de captura ou análise de voz do usuário foi implementada nesta entrega.
