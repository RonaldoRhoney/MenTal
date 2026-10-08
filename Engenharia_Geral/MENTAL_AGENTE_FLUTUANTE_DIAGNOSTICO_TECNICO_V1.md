# MENTAL — Diagnóstico Técnico: Agente Flutuante "Mental"

Resposta ao processo obrigatório da seção 14 de `MENTAL_AGENTE_FLUTUANTE_V1.md` (formalizado 07/10/2026). **Nenhum código foi escrito ainda** — este documento é só INSPECIONAR → DIAGNOSTICAR → PROPOR, aguardando aprovação antes de IMPLEMENTAR.

## 1. Estado atual (INSPECIONAR, confirmado por leitura real do código)

- `client/lib/main.dart:98-129` — `MaterialApp` já tem um `builder: (context, child) => GameBackground(child: ...)` que envolve **toda** a árvore do app, incluindo qualquer rota empurrada por qualquer tela (não só os estágios splash/login/Home do `AnimatedSwitcher` interno de `AppEntryPoint`). Esse é o único ponto que já existe hoje capaz de desenhar algo por cima de literalmente qualquer tela — é o ponto de montagem natural do personagem flutuante.
- **Não existe nenhum sistema de rota nomeada** (`RouteSettings(name: ...)`) nem `NavigatorObserver` no app hoje — toda navegação é `Navigator.push(MaterialPageRoute(builder: (_) => XScreen(...)))`, sem metadado. Não dá pra perguntar "qual é a rota atual" de forma centralizada; cada tela só existe como widget.
- `ChallengeScreen` é a mesma tela pra **todo** território (Idiomas ou não) — é aberta de pelo menos 8 pontos diferentes do código (`home_screen.dart` em 4 lugares, `battles_screen.dart`, `friends_screen.dart`, `notifications_screen.dart`, `coach_screen.dart`), sempre recebendo só `territoryId` como parâmetro. Não existe hoje uma forma client-side de saber "este territoryId é do Mundo dos Idiomas" sem consultar a resposta de `/progress` (que já teria essa informação, mas não de forma centralizada/reaproveitável fora da Home).
- `MentalLingoScreen` só abre de um único lugar: dentro do banner do LINGO em `_WorldDetailScreen` (`home_screen.dart`), que já SABE que está no Mundo dos Idiomas (é a tela de detalhe do Mundo).
- **Já existe exatamente o card que o documento manda substituir na Home**: `home_screen.dart:806-847`, o selo "Dica do My_Mental_AI" (comentário na própria linha confirma essa é a descrição), clicável, abre `CoachScreen`. Os outros 2 cards de orientação-like na Home (`_buildEconomyBanner`, reparo de sequência, linha 492; `_ContentSuggestionCard`, busca sem resultado, linha 953) têm CTA próprio e ação concreta, não são "dica/orientação" genérica — recomendo **não** tratá-los como candidatos a substituição (ver seção 5).
- **Já existe toda a infraestrutura visual do personagem**: `client/lib/widgets/mental_character.dart`, enum `MentalCharacterExpression` com 8 expressões (`felizNeutro`, `apontando`, `okPositivo`, `negativoSuave`, `pensando`, `comemorando`, `acenando`, `dormindo`), já mapeadas pra PNGs 800×800 em `client/assets/character/`, já em uso no splash, no banner do LINGO, no resultado de Desafio. **Isso resolve de cara a dúvida #2 do documento** ("ícone provisório até a arte final existir") — não precisa de nenhuma arte nova, o personagem flutuante usa essa mesma infraestrutura desde o primeiro dia.
- Central de Notificações (`Engenharia_Geral/CENTRAL_DE_NOTIFICACOES_HOME_V1.md`) é um histórico assíncrono de eventos (convite, streak, etc.), não um mapeamento "tela atual → dica". Não resolve sozinha a parte de "contexto da tela atual" que o Agente precisa — pode no máximo ser **uma das fontes** de conteúdo, não a estrutura inteira.
- Padrão de estado local já maduro em `guest_challenge_service.dart` (SharedPreferences: bool, string, lista com JSON por item, sempre com `try/catch` silencioso) — mesmo padrão a seguir pro estado ligado/desligado + posição do personagem.
- Padrão de acessibilidade já estabelecido: `Semantics(label: ...)` envolvendo o widget visual, texto vindo de uma chave l10n dedicada (`ranking_screen.dart:374-391`).

## 2. Decisão de arquitetura central: como saber "estou no Mundo dos Idiomas"

Como não existe sistema de rota nomeada, a opção mais simples e menos invasiva é **cada tela se auto-registrar** num controlador global, em vez de criar um `NavigatorObserver` que precisaria de nome de rota em 8+ pontos de chamada diferentes de `ChallengeScreen`.

**Proposta**: `FloatingMentalController` (singleton, `ChangeNotifier`, mesmo padrão já usado por `ThemeModeService.instance`) expõe um contador (não um bool simples, pra suportar telas aninhadas): `hideForIdiomas()` / `unhideForIdiomas()`. `ChallengeScreen` chama isso no `initState`/`dispose`, decidindo com base no `territoryId` recebido (prefixo `ingles_`/`espanhol_`/`frances_` ou igual a `libras` — mesma lista que já existe no backend em `IDIOMA_TERRITORY_IDS`, só que no cliente é usada apenas pra decidir visibilidade, nunca pra regra de jogo). `MentalLingoScreen` e as telas de Constelação de Palavras fazem o mesmo incondicionalmente (sempre dentro de Idiomas).

Isso mantém a mudança em **3-4 arquivos** (as próprias telas de Idiomas), em vez de tocar nos 8+ pontos de chamada espalhados pelo app.

## 3. Decisão: "escondido até chegar na Home"

Em vez de criar um opt-out explícito pra cada tela de login/cadastro/age-gate/onboarding (que já são os estágios do `AnimatedSwitcher` de `AppEntryPoint`, ANTES da Home), a proposta é: o personagem flutuante **só aparece depois que a Home é alcançada pela primeira vez** nesta sessão do app (`AppEntryPoint` expõe isso via um `ValueNotifier<bool>` simples, virado `true` quando `_buildBody` retorna `HomeScreen`). Isso resolve de graça:
- Dúvida #4 do documento (não aparece nas 3 perguntas do fluxo guest nem no seletor de Mundo).
- Metade da dúvida #6 (login/cadastro/age-gate já ficam de fora automaticamente).

A outra metade da dúvida #6 (Ajustes, telas de erro que acontecem DEPOIS da Home) usa o mesmo mecanismo de opt-in/opt-out por tela do item 2 (ex.: `SettingsScreen` chama `hideTemporarily()`/`unhide()`).

## 4. Componente e estado

- `FloatingMentalController` — estado: `enabled` (bool, persistido), `position` (Offset, persistido), `homeReached` (bool, runtime), `idiomasDepth` (int, contador runtime), `hiddenScreensDepth` (int, contador runtime, pras telas de opt-out tipo Ajustes).
- Visibilidade final = `enabled && homeReached && idiomasDepth == 0 && hiddenScreensDepth == 0`.
- Montado no `builder:` do `MaterialApp` (item 1), como um `Stack` por cima do `child` existente — um `ListenableBuilder` escutando o controller decide se desenha o personagem arrastável (`GestureDetector` com `onPanUpdate`, posição clampada pra nunca cobrir a barra de navegação inferior nem sair da tela).
- Estado "desligado": personagem continua desenhado, mas com opacidade reduzida (`Opacity`/`ColorFiltered` esmaecido) — nunca some de vez, conforme §3 do documento ("apagado em todas as telas"). Duplo toque reativa.
- Desligar pela primeira vez (dúvida #1): toggle em Ajustes (`_CompactSwitchRow`, mesmo padrão de som/tema), **mais** pressionar-e-segurar o personagem como atalho — ambos chamam o mesmo `FloatingMentalController.setEnabled(false)`.

## 5. Painel de orientações — conteúdo, sem backend novo

Pra respeitar "sempre grátis" e "sem sistema paralelo" com o mínimo de superfície nova:

- **Categorias estáticas** (zero chamada de API): "por onde começar", "como funciona cada modo" — texto fixo, curado, revisado por Rhoney, vive no cliente como um mapa `Map<String, String>` (ou l10n), chaveado por uma categoria simples.
- **Categorias dinâmicas** ("continuar de onde parou", sequência diária, próxima etapa): a tela que já está aberta quando o personagem é tocado **já tem** a resposta de `/progress` carregada (ex.: Home já busca isso) — o painel recebe essa informação por parâmetro na hora de abrir, em vez do `FloatingMentalController` fazer sua própria chamada de API. Fora da Home (ex.: dentro de `ChallengeScreen`), a categoria dinâmica simplesmente não aparece nesta primeira fase — evita duplicar lógica de busca de progresso em todo lugar que o personagem aparece.
- **Nenhum endpoint novo no backend** nesta primeira fase — toda a orientação é texto local + dado que a tela já tinha em mãos.

## 6. Banners/cards a substituir (seção 5 do documento, aprovação item a item)

| Local | O que é hoje | Recomendação |
|---|---|---|
| `home_screen.dart:806-847` — selo "Dica do My_Mental_AI" | Abre `CoachScreen` | **Substituir** — é exatamente o card que o documento descreve em §1 ("na Home não existe card") |
| `home_screen.dart:492-558` — banner de reparo de sequência | CTA de ação concreta (comprar reparo), com X de dispensar | **Manter** — não é orientação genérica, é uma oferta transacional |
| `home_screen.dart:953-977` — card de sugestão de conteúdo | Aparece só após busca sem resultado, CTA de enviar sugestão | **Manter** — fluxo próprio, não é "dica contextual" |

Nenhuma dessas 3 remoções/manutenções é aplicada sem sua confirmação explícita, item a item, conforme o próprio documento pede.

## 7. Respostas às 6 dúvidas abertas (seção 12 do documento)

As recomendações já estavam no próprio documento formalizado; confirmo todas após checar contra o código real, sem achar motivo pra divergir:

1. Toggle em Ajustes + pressionar-e-segurar — **confirmado**, compatível com o padrão existente de `settings_screen.dart`.
2. Ícone provisório — **confirmado, e nem é provisório**: a infraestrutura de `mental_character.dart` já é a definitiva, só falta o rig animado real (fora de escopo aqui, já registrado como pendência no doc do personagem).
3. Oculto durante a pergunta, visível nas telas de entrada/resultado — **confirmado**; mesmo mecanismo de opt-in/opt-out do item 2 (`ChallengeScreen` chama hide/unhide internamente ao trocar de fase, não só no `initState`/`dispose` do widget inteiro).
4. Só aparece na Home durante o fluxo guest, nunca dentro das 3 perguntas — **confirmado de graça** pelo mecanismo "escondido até chegar na Home" (seção 3 acima) — nem precisa de tratamento especial pro fluxo guest.
5. Mundo dos Idiomas inclui desafios/relâmpagos dele — **confirmado**, mesma lista de prefixos usada pra decidir timer (`kAlwaysTimedTerritoryIds` é prova de que o cliente já lida com listas de território por categoria hoje).
6. Login/cadastro ficam de fora automaticamente (item 3); Ajustes e telas de erro usam opt-out explícito por tela — **confirmado**.

## 8. Fora de escopo nesta entrega (igual à seção 10 do documento original)

Rig animado real, variação por marco de gamificação, atalho "Falar com o LINGO" fora de Idiomas, qualquer recompensa — nada disso muda aqui.

## 9. Plano de implementação, se aprovado

1. `FloatingMentalController` (novo serviço/estado).
2. Montagem no `builder:` do `MaterialApp`, widget arrastável com esmaecimento quando desligado.
3. Opt-in/opt-out em `ChallengeScreen` (por território + por fase da pergunta) e `MentalLingoScreen`/telas de Constelação de Palavras (sempre oculto).
4. `ValueNotifier` de "Home alcançada" em `AppEntryPoint`.
5. Painel de orientações (categorias estáticas + dinâmicas via dado já carregado pela tela).
6. Toggle em Ajustes + gesto de pressionar-e-segurar.
7. Substituição do selo "Dica do My_Mental_AI" na Home (só esse, conforme seção 6).
8. Testes: visibilidade por tela/fase, persistência de estado ligado/posição, acessibilidade (`Semantics` no personagem e no botão de religar).

## 10. Pergunta final pra Rhoney

Além da aprovação item a item da seção 6 (banners) e da confirmação geral das seções 2 a 7 acima: tudo bem eu reaproveitar a infraestrutura JÁ EXISTENTE de `mental_character.dart` (8 expressões já prontas) pro personagem flutuante nesta primeira entrega, em vez de esperar o rig animado novo? Isso significa que o personagem flutuante já nasce com expressões reais (não um ícone genérico), só sem animação fluida ainda.
