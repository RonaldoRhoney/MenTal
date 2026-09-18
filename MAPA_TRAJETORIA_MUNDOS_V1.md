# MENTAL — Mapa de Trajetória dos Mundos

**Status:** Fases 1, 2 e 3 IMPLEMENTADAS (18/09/2026). Concluído.

## Decisões da rodada de perguntas em aberto (17/09/2026)

- **Profundidade**: Mundos + SubMundos no mapa (cada SubMundo confirmado — hoje Internet, Copa do Mundo, Futebol — vira planeta próprio, não só o Mundo de primeiro nível).
- **Cálculo de %**: XP conquistado / XP total possível, usando o mesmo teto de 200 XP/território já usado pra "território conquistado" (`config.CONQUEST_XP_THRESHOLD`) — nunca uma fórmula nova.
- **Ordem**: mesma de `World.display_order` (carrossel da Home hoje); SubMundos entram logo depois do Mundo pai, na ordem do próprio `Block.display_order`.
- **Arte**: IA de imagem + Canva (já conectado via MCP nesta sessão) pra montagem/curadoria — não ilustrador contratado nem banco de assets licenciado.
- **Elementos de conquista**: os 3 juntos — estrelas (1-3, por marco de %: 33/66/100), efeito de "planeta desbloqueado" progressivo (mesmo %), e troféu/insígnia fixo ao completar 100%.
- **Conexão entre planetas**: linhas de constelação.
- **Estilo visual**: estilizado/cartunizado (não realista tipo NASA).

## Fase 1 — o que foi implementado

- `services.SUBMUNDO_BLOCK_IDS` — registro explícito de quais Blocos são SubMundos de verdade (hoje: `internet`, `copa_do_mundo`, `futebol`) vs. Blocos que são só agrupamento de menu (`tecnologia`, `mitologia` etc.) — nunca inferido sozinho da estrutura de dados, sempre um registro manual, mesmo espírito de `BLOCO_TO_TERRITORY` nos scripts de conversão de conteúdo.
- `services.get_trajectory_map(db, user_id)` — um node por Mundo de primeiro nível + um node extra por SubMundo confirmado, com `percent`/`status` (not_started/in_progress/completed)/`stars` (0-3) calculados a partir do progresso real (`UserTerritoryProgress`). Territórios de um SubMundo nunca contam no Mundo pai.
- `GET /progress/trajectory-map` (`app/routers/progress.py`) — endpoint dedicado, separado de `GET /progress` (só chamado quando o jogador abre a tela do mapa, não em toda carga da Home).
- Testes: `backend/tests/test_trajectory_map.py` (5 testes — separação Mundo/SubMundo, cálculo de %/status/estrelas com progresso real via manipulação direta de XP, Mundo sem território não aparece, endpoint exige idade confirmada).

## Fase 2 — o que foi implementado

- `client/lib/screens/trajectory_map_screen.dart` — lista os planetas (Mundo + SubMundos indentados logo abaixo do pai), com placeholder simples (`_PlanetPlaceholder`: círculo colorido + ícone genérico, cor por status), barra de progresso, % + rótulo de status, e 1-3 estrelas — tudo direto do que `GET /progress/trajectory-map` devolve, nenhum cálculo no client.
- Botão **"Ver Mapa de Trajetória"** na tela de Progresso, acima de "Ver conquistas"/"Ver estatísticas" (mesmo padrão dos outros dois).
- `client/lib/api/api_client.dart::trajectoryMap()` — novo método consumindo o endpoint.
- Testes: `client/test/trajectory_map_screen_test.dart` (3 testes — lista vazia, nó de Mundo, nó de SubMundo com rótulo/indentação/3 estrelas).

## Fase 3 — o que foi implementado (18/09/2026, revisão de rota)

A ideia original (seção 3) previa ilustração de cada planeta via IA de
imagem + Canva. Rhoney testou um piloto de 3 planetas gerados no Canva
(Tecnologia/Esportes/Linguagem) direto no celular real e pediu pra não
seguir por esse caminho — nesse meio-tempo, apareceu um mockup SVG que
Rhoney já tinha aprovado em outra conversa (embutido em
`Mental App - Claude_files/saved_resource.html`, um artifact "visualize"
salvo do navegador), com um estilo mais simples e elegante: esfera com
gradiente radial de 2 cores, anel elíptico, sem ilustração bitmap
nenhuma. Esse mockup virou a referência final, e a Fase 3 foi
implementada 100% nativa (sem gerar/curar nenhuma imagem):

- `client/lib/screens/trajectory_map_screen.dart` foi reescrita:
  - Layout espacial de verdade (`_computePositions`), não lista vertical
    — planetas alternam esquerda/direita numa trilha que serpenteia,
    SubMundo ramifica logo abaixo do Mundo pai.
  - **Ordem da jornada de baixo pra cima** (pedido explícito de Rhoney,
    18/09/2026): o 1º Mundo fica na base do mapa, e a trilha sobe
    conforme o jogador avança — mesma metáfora do mockup original.
  - Caminho de constelação pontilhado (`_ConstellationBackgroundPainter`,
    `CustomPainter`) conectando os planetas em curva.
  - Esfera com gradiente radial por Mundo (`_kPlanetPalette`, cor de
    identidade própria por Mundo/SubMundo) + anel elíptico
    (`_RingPainter`).
  - **"Fog of war"**: Mundo `not_started` sempre aparece cinza neutro com
    cadeado — a cor de identidade só se revela quando o jogador começa a
    explorar (`in_progress`/`completed`).
  - **Ícone temático por Mundo** dentro da esfera (`_kPlanetIcons` —
    pedido de Rhoney, 18/09/2026, "elementos que remetam às
    características desse mundo"): livro pra Linguagem, bola pra
    Esportes, chip pra Tecnologia etc. Em `in_progress` o ícone fica como
    marca d'água atrás do texto de %; em `completed` é o conteúdo
    principal da esfera (sem % pra mostrar).
  - % dentro do próprio planeta (`in_progress`) e badge de estrela
    (círculo dourado com a contagem) quando `stars > 0`.
  - Texto (nome, status, %) continua em `Text` widgets normais, nunca
    desenhado no canvas — só o fundo decorativo (estrelas + linha de
    constelação) e o anel usam `CustomPainter`, pra manter a tela
    testável via `find.text`.
- **Ponto de entrada muda de Progresso pra Home** (pedido de Rhoney,
  18/09/2026): não é mais um botão dentro da tela de Progresso — é um
  ícone (✨) ao lado do nome/nível do usuário, no card principal da Home
  (`_ProgressCard` em `home_screen.dart`), mais visível e sem precisar
  entrar em outra tela primeiro.
- Testado num build real instalado por USB num Android físico (Moto
  G22), apontando pro backend local (nunca produção) via
  `--dart-define=API_BASE_URL` + `adb reverse` — validado visualmente
  antes de qualquer commit.
- Testes: `client/test/trajectory_map_screen_test.dart` (4 testes —
  lista vazia, Mundo em andamento com %/status, Mundo não iniciado com
  cadeado, SubMundo conquistado com estrelas).

## Próximos passos

Nenhum pendente — as 3 fases estão completas e validadas num dispositivo
real. Evolução futura (não solicitada ainda): permitir tocar num planeta
pra abrir direto o Mundo/SubMundo correspondente.

---

## 1. Entendimento da solicitação

Uma nova tela/visualização dentro do MENTAL, no formato de **mapa de trajetória** (estilo "mapa de jogo", com pontos representando cada Mundo conectados por um caminho), mostrando:

1. **Todos os Mundos** disponíveis no app, como pontos ao longo do percurso.
2. **Status de conquista** de cada Mundo — visualmente diferenciado entre: conquistado (100% completo), em andamento (parcialmente completo) e não iniciado.
3. Para o Mundo em que o usuário está posicionado/navegando no momento, exibir a **porcentagem exata de progresso** daquele Mundo.
4. Todos os dados exibidos devem ser **fiéis ao progresso real do usuário** — refletindo exatamente o que ele já respondeu (Desafios/Blocos concluídos), não uma estimativa ou placeholder.
5. **Identidade visual temática por Mundo** (refinamento adicional de Rhoney): cada ponto do mapa não deve ser um marcador genérico — precisa remeter visualmente ao tema daquele Mundo. Exemplos citados: o ponto do Mundo da Tecnologia deve ter uma cena/ilustração que remeta a tecnologia (circuitos, elementos digitais); o ponto do Mundo dos Esportes deve remeter a um cenário esportivo (estádio, jogadores, bola). Cada Mundo — e, no futuro, cada SubMundo — precisa de uma ilustração própria e reconhecível, nunca um símbolo neutro reaproveitado entre todos. O padrão visual geral deve transmitir uma sensação **profissional**, não um mapa genérico de template.
6. **Riqueza visual (reforçado por Rhoney após primeira prévia)**: o padrão de qualidade esperado é o de mapas de progressão de grandes jogos mobile (estilo Candy Crush, Duolingo) — cada Mundo é uma **cena ilustrada rica**, não um ícone simples dentro de um círculo. O mapa como um todo deve comunicar visualmente os conceitos de **desafio, conquista e evolução** (ex.: elementos como estrelas/troféus de conquista, cenário de fundo elaborado remetendo ao tema, sensação de "terreno" percorrido, não apenas pontos abstratos numa linha). Isso é, na prática, um trabalho de **ilustração de jogo (game art)**, não apenas um componente de UI simples — precisa ser tratado com esse nível de investimento de design.
7. **Metáfora conceitual definitiva (reformulação de Rhoney, substitui a ideia de "trilha/terreno" das versões anteriores)**: como cada etapa do mapa representa um **Mundo**, o contexto visual geral que os une deve ser um **Universo/Galáxia** — não um mapa de terreno terrestre com trilha de fases. Cada Mundo passa a ser representado como um **planeta/corpo celeste** dentro dessa galáxia, cada um com identidade visual própria (cor, textura, "atmosfera" remetendo ao tema daquele Mundo — ex.: um planeta com anéis tecnológicos/circuitos para o Mundo da Tecnologia, um planeta com textura de campo/estádio para o Mundo dos Esportes). A conexão entre os planetas (equivalente à antiga "trilha") deve ser repensada nesse novo contexto — pode ser uma rota espacial, constelação de linhas conectando os planetas, ou trajetória orbital, a definir com Rhoney antes da produção final da arte.
8. **Localização definida (decidido por Rhoney)**: o mapa deve ficar dentro do menu **Progresso** já existente no app — não é uma nova aba/ícone isolado na Home, e sim uma seção/tela acessada a partir do menu Progresso.

## 2. Perguntas em aberto (Claude Code deve levar a Rhoney antes de decidir sozinho)

- **Nível de profundidade**: o mapa mostra apenas os Mundos de primeiro nível, ou também precisa refletir a estrutura interna (SubMundos, Blocos) para os Mundos que já usam a arquitetura de SubMundos (ex.: Mundo da Tecnologia → SubMundo Internet)?
- **Cálculo de porcentagem**: a % de progresso de um Mundo é calculada por Desafios concluídos, por perguntas respondidas corretamente, ou por Blocos completos? Isso muda a fórmula e a granularidade do dado a ser consultado.
- **Ordem dos Mundos no mapa**: existe uma ordem fixa/recomendada de progressão (ex.: sugerindo que o usuário siga determinada sequência), ou o mapa é meramente informativo, sem sugerir ordem?
- **Origem das ilustrações temáticas**: as cenas de cada Mundo (estádio para Esportes, circuitos para Tecnologia etc.) serão encomendadas como arte original (ilustração customizada por Mundo), ou existe um banco de assets/referência visual que Rhoney já tem em mente? Isso muda drasticamente o esforço e o prazo — arte customizada por Mundo é trabalho de design significativo, não apenas código.
- **Fornecimento das ilustrações (crítico, dado o padrão de qualidade solicitado)**: como o padrão de referência agora é nível "mapa de jogo mobile" (Candy Crush, Duolingo), Claude Code sozinho, como agente de código, não produz esse tipo de arte final com qualidade profissional. Rhoney precisa decidir a origem dessas ilustrações antes de qualquer estimativa de prazo: (a) ilustrador/designer contratado, (b) geração via ferramenta de IA de imagem com curadoria/ajuste manual posterior, ou (c) banco de assets prontos (ex.: pacotes de ilustração de jogos, licenciados) adaptados à identidade visual do MENTAL. Essa decisão deve ser tomada e comunicada antes do início da implementação técnica.
- **Elementos de "conquista/evolução"**: quais elementos concretos devem aparecer para comunicar isso — estrelas por desempenho (ex.: 1 a 3 estrelas por Mundo concluído, como em jogos de fases), troféus, insígnias, efeito de "terreno desbloqueado" no cenário de fundo? Vale Rhoney indicar referências visuais específicas (prints de outros apps/jogos) que sirvam de inspiração direta, para alinhar expectativa antes da produção da arte.
- **Forma da conexão entre os planetas**: dentro da metáfora de Universo/Galáxia, como deve ser visualmente a "trilha" que liga um Mundo (planeta) ao outro — uma rota espacial pontilhada, linhas de constelação, um traçado orbital? Isso é puramente uma decisão de arte/UX a validar com Rhoney antes da produção final.
- **Nível de fidelidade astronômica**: os planetas devem ter aparência realista (textura tipo NASA) ou estilizada/cartunizada (mais alinhada à identidade visual gamificada já usada no resto do app)? Isso influencia diretamente qual abordagem de produção de arte (ilustrador, IA de imagem, assets prontos) é mais adequada.

## 3. Escopo técnico (a propor em detalhe por Claude Code)

**Pré-requisito imediato — conexão com Canva via MCP:** Claude Code deve, como primeiro passo prático, configurar a conexão do Canva ao ambiente de trabalho via MCP (Model Context Protocol) — seguindo o fluxo padrão: adicionar o servidor MCP do Canva (via Composio ou provedor equivalente), autenticar via OAuth com a conta Canva de Rhoney, e confirmar que a conexão está funcional (criar, buscar e exportar designs de teste). Essa conexão é o que viabiliza produzir as cenas temáticas de cada planeta/Mundo usando os elementos gráficos e templates do Canva, servindo de ferramenta prática para a produção de arte discutida na seção 2, em vez de depender de ilustração 100% codificada em SVG. Rhoney já solicitou explicitamente essa conexão — não é uma opção a avaliar, é uma tarefa a executar.

- Consultar a estrutura de progresso já existente no banco de dados (por Mundo, Bloco, Desafio) para calcular corretamente o status de cada Mundo e a % do Mundo atual.
- Desenhar a tela de mapa no Flutter, com identidade visual própria (trilha conectando os pontos dos Mundos, ícones/cores diferenciando conquistado / em andamento / não iniciado).
- Produzir ou integrar a ilustração temática de cada Mundo (cena reconhecível do tema — estádio para Esportes, circuitos para Tecnologia, e assim por diante), mantendo consistência de estilo visual entre todas elas (mesma paleta, mesmo nível de detalhe, mesmo enquadramento), para que o conjunto pareça uma coleção coesa e profissional, não ilustrações desencontradas.
- Garantir que a tela sempre reflita dados atualizados (não cacheados de forma desatualizada) no momento em que o usuário a acessa.
- Considerar performance: se o número de Mundos crescer muito (o app já está expandindo para dezenas de SubMundos), o mapa precisa ser navegável/scrollável sem perder clareza visual.

## 4. Critério de aceite

- Mapa exibe corretamente todos os Mundos disponíveis, com status visual (conquistado / em andamento / não iniciado) fiel ao progresso real do usuário.
- Mundo atual do usuário exibe a % de progresso correta, calculada com base em dados reais.
- Rhoney validou as respostas às perguntas em aberto da seção 2 antes da implementação ser finalizada.
