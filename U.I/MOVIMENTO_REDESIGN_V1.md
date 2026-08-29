# MENTAL — Redesign da Tela Movimento (Conquista + Meta Configurável)

**Status:** Aprovado para implementação.
**Referência visual:** mental-movimento-v3.html (protótipo estático em HTML/CSS — reproduzir estrutura, hierarquia, cores, proporções e animações abaixo em Flutter; o HTML é referência de layout, não para embutir/rodar como WebView).
**Escopo:** Tela Movimento apenas. Não altera lógica de negócio do contador de passos em si (leitura do sensor, persistência), exceto onde explicitamente indicado na seção 6 (meta configurável influenciando XP).

---

## 1. Objetivo

A tela Movimento atual tem hierarquia fraca (aviso de ciclo pendente em amarelo competindo com mensagem de erro do sensor), paleta neutra/apagada que não comunica "conquista", nenhuma relação visível entre passos e XP, e falta visualização de tendência (nem gráfico semanal, nem intraday). Este documento especifica a correção completa, com uma paleta vibrante voltada a sensação de progresso/vitória, layout que cabe inteiro na tela sem scroll, e uma meta diária configurável pelo usuário que passa a alimentar a gamificação.

## 2. Paleta e tipografia (aplicam-se a toda a tela)

**Cores base:**
- Fundo: gradiente radial roxo-escuro profundo (de `#241640` no canto superior esquerdo para `#0A0710`), não mais preto neutro.
- Cor de "vitória/conquista": âmbar/dourado — `#FFB238` (principal) e `#FF8A3D` (ember, secundário), usados em elementos de destaque, badges de meta batida, marcador de pico nos gráficos.
- Cor de "energia/vida": teal elétrico — `#3FE8C4` (principal) e `#22B8A0` (secundário), usado no indicador "LIVE", nas barras do gráfico semanal, no valor de XP.
- Cards em `#191228` sobre o fundo gradiente, bordas sutis translúcidas (`rgba(255,255,255,0.08)`).
- Texto: branco quente `#FFFDF8` para valores/títulos, `#B8AFC9` para labels secundários, `#756D89` para texto terciário/apagado.

**Tipografia:**
- Números de destaque (percentual do anel, contagem de passos, XP, valores de meta): fonte **Space Grotesk**, peso 700 — dá o impacto geométrico que a fonte serif/monoespaçada anterior não tinha.
- Títulos de seção (ex: "Movimento" no header): manter **Fraunces** (serif, mesma família da marca).
- Texto corrido/labels: **Inter**.

**Efeitos:** uso de glow sutil (`box-shadow`/`filter: drop-shadow`) em cores douradas e teal atrás de elementos-chave (anel, linha do gráfico de hoje) para reforçar a sensação de energia — não usar glow em elementos secundários, senão perde o destaque.

## 3. Estrutura da tela (topo → base, ordem exata)

A tela é uma coluna flex vertical, cada seção com altura proporcional definida (ver seção 7), **sem scroll** — tudo deve caber na viewport padrão de um Android médio (~390x844 lógicos, descontando status bar).

1. **Header** — botão voltar circular + título "Movimento" (serif) à esquerda; chip de streak ("🔥 X dias") à direita, fundo gradiente âmbar translúcido.
2. **Chip de ciclo pendente** (condicional — só aparece se houver passos de um ciclo anterior não coletados) — uma única linha: ícone + texto curto + botão "Coletar" em dourado sólido. Nunca ocupar mais de uma linha de texto.
3. **Bloco Hero** (anel + estatísticas) — ver seção 4.
4. **Seletor de meta diária** — ver seção 6.
5. **Gráfico "Últimos 7 dias"** — ver seção 5.1.
6. **Gráfico "Hoje, hora a hora"** — ver seção 5.2.
7. **Rodapé** — status do sensor à esquerda, link "Desativar" à direita, uma única linha.

## 4. Bloco Hero (anel de progresso + XP)

Card compacto (não mais um bloco grande dominando a tela), com **anel + estatísticas lado a lado horizontalmente**, dentro do mesmo card:

- **Anel de progresso** (~78x78): trilho de fundo translúcido, preenchimento em gradiente dourado→ember, animação de preenchimento suave ao carregar (de 0 até o valor real, ~1.2s, easing suave, com leve delay inicial). Badge pequeno "LIVE" com ponto pulsante em teal elétrico sobreposto no canto superior direito do anel — indica que o valor atualiza em tempo real conforme o usuário anda. No centro do anel: percentual da meta em destaque (Space Grotesk, gradiente de texto dourado→ember) + label pequeno "da meta".
- **Coluna de estatísticas** ao lado do anel:
  - Linha 1: número de passos hoje, em dourado (`#FFB238`), com label "passos hoje".
  - Linha 2: XP conquistado hoje, em teal (`#3FE8C4`), com label "XP conquistado".
  - Linha 3: texto pequeno explicando a conversão — "A cada **100 passos** = **+2 XP**" (valores em negrito dourado) — esta é a relação passos→XP explícita que não existia antes; deve **sempre** estar visível neste bloco.

## 5. Gráficos (empilhados verticalmente, cada um em seu próprio card de largura total)

**Regra geral:** os dois gráficos NUNCA ficam lado a lado — cada um ocupa a largura total da tela, um abaixo do outro, evitando competição visual e espremimento. O espaço vertical entre eles é dividido proporcionalmente (o gráfico de hoje recebe fração ligeiramente maior de altura que o semanal, por carregar mais elementos: linha, marcadores de pico/vale, eixo de horas).

### 5.1 Gráfico "Últimos 7 dias"
- Cabeçalho do card: ponto indicador teal + label "Últimos 7 dias" à esquerda; texto pequeno "média X" à direita (média de passos da semana).
- Gráfico de barras, 7 colunas (Seg a Hoje), cada barra com gradiente teal (dias passados) exceto a barra do dia atual, que usa gradiente dourado/ember com leve glow — destacando visualmente "hoje" dentro da semana.
- Barras animam crescendo de baixo pra cima ao carregar a tela (stagger entre elas, ~40ms de delay entre cada uma).
- Fonte dos dados: histórico diário de passos já registrado no backend (mesma fonte usada em Estatísticas/Progresso, se já existir endpoint; caso não exista agregação diária pronta, criar endpoint simples de série de 7 dias).

### 5.2 Gráfico "Hoje, hora a hora"
- Cabeçalho do card: ponto indicador ember + label "Hoje, hora a hora" à esquerda; texto pequeno "a cada 6h" à direita.
- Gráfico de linha (não barras) mostrando a evolução intraday, com área preenchida abaixo da linha em gradiente ember translúcido (opacidade decrescente até transparente).
- Linha desenha-se da esquerda pra direita ao carregar (animação de `stroke-dashoffset`, ~0.9s).
- Marcador circular dourado destacando o ponto de **pico** (maior número de passos no intervalo).
- Ao lado do gráfico (coluna estreita à direita, dentro do mesmo card): dois mini-cards de resumo — "🔥 [hora] · pico · [valor]" e "💤 [hora] · vale · [valor]" — mostrando o horário e valor exatos do pico e do vale do dia.
- Eixo de horas abaixo do gráfico: 00h / 06h / 12h / 18h / 24h.
- Fonte de dados: os checkpoints de passos a cada 6 horas já registrados no backend (mesma infraestrutura mencionada nas correções de bug anteriores de Movimento).

## 6. Seletor de meta diária (novo — influencia gamificação)

Card entre o Hero e os gráficos, com:
- Cabeçalho: ponto dourado + label "Sua meta diária" à esquerda; texto pequeno "define seu ritmo de XP" à direita.
- Quatro opções em linha, cada uma um chip selecionável: **5k (leve)**, **10k (padrão)**, **15k (intenso)**, **20k (elite)**. A opção ativa tem fundo em gradiente dourado translúcido e borda dourada sólida; as inativas ficam neutras.

**Regras de negócio (novas — requerem trabalho de backend):**
- A meta escolhida pelo usuário substitui o valor fixo de 10.000 passos usado até hoje como "meta diária" em todo o app (anel de progresso, cálculo de "meta batida", bônus de conquista).
- Metas mais altas devem gerar **XP proporcionalmente maior** ao bater a meta (ex: bônus de conquista escalona com a dificuldade escolhida — a definir fórmula exata: sugestão inicial é bônus fixo por faixa, não multiplicador linear, para não criar incentivo de escolher sempre a meta mais alta apenas por XP sem relação com esforço real).
- A conversão base de **100 passos = +2 XP** (seção 4) permanece constante independente da meta escolhida — o que muda com a meta é apenas o **bônus por completar o dia**, não a taxa de conversão contínua.
- Alterar a meta não deve resetar o progresso do dia corrente — só passa a valer para o cálculo de "% da meta" e "bônus ao bater a meta" a partir do momento da mudança.
- Adicionar campo de meta diária editável ao perfil/configuração do usuário no backend (se não existir), com valor padrão 10.000 para não quebrar usuários existentes.

## 7. Motion / animação de entrada

Cascata suave ao carregar a tela, mais rápida que a da Home (menos elementos, entrada mais compacta):
1. Header: fade + translação leve, ~400ms, delay ~30ms.
2. Chip de ciclo pendente (se visível): fade + rise, ~400ms, delay ~80ms.
3. Bloco Hero: fade + rise, ~450ms, delay ~130ms. Anel preenche de 0% ao valor real em paralelo, ~1.2s, delay ~400ms.
4. Seletor de meta: fade + rise, ~450ms, delay ~200ms.
5. Gráfico 7 dias: fade + rise, delay ~280ms; barras crescem em stagger logo em seguida (delay base ~440ms, +40ms por barra).
6. Gráfico hoje: fade + rise, delay ~360ms; linha desenha-se (~480ms delay), área preenche (~900ms delay), marcador de pico aparece por último (~1.1s delay).
7. Rodapé: fade, delay ~780ms.

Em Flutter, mesma abordagem já usada na Home (seção de motion do HOME_REDESIGN_V1.md): `AnimatedOpacity` + `AnimatedSlide` orquestrados por delays incrementais no primeiro `build` da tela, sem scroll-trigger. Respeitar `reduced motion` do sistema — pular direto pro estado final se ativado.

## 8. Garantia de "sem scroll"

Este é um requisito funcional, não só estético: a tela deve ser construída como uma coluna flex onde cada seção tem altura fixa ou proporcional (`flex: valor`), de forma que a soma sempre caiba na viewport disponível, sem depender de `SingleChildScrollView`. Testar especificamente em:
- Tela pequena (altura reduzida, ex: dispositivos com aspect ratio mais "quadrado").
- Cenário com chip de ciclo pendente visível (linha extra) e sem ele (usuário sem ciclo pendente) — o layout deve se ajustar graciosamente em ambos os casos, redistribuindo o espaço liberado para os gráficos, não deixando um vão vazio.

## 9. O que NÃO muda nesta entrega

- Lógica de leitura do sensor de passos (frequência, permissões, fallback quando indisponível).
- Estrutura de rotas/navegação de entrada e saída da tela.
- Persistência dos checkpoints de 6h — só passam a ser consumidos visualmente, não mudam de formato.
- Bottom navigation do app (não faz parte desta tela).

## 10. Critério de aceite

- Nenhum scroll necessário para ver todas as informações da tela, em telas de tamanho padrão Android.
- Gráfico de 7 dias e gráfico de hoje aparecem um abaixo do outro, nunca lado a lado.
- Relação "100 passos = +2 XP" sempre visível no bloco Hero.
- Seletor de meta diária funcional, persistindo a escolha do usuário e refletindo no cálculo de % da meta e no anel de progresso.
- Bônus de XP ao bater a meta escala com a meta escolhida, conforme regra definida em conjunto com o backend (seção 6).
- Paleta aplicada consistentemente (roxo-escuro de fundo, dourado/ember para conquista, teal para energia/live) — sem reaproveitar a paleta neutra anterior.
- `flutter analyze` limpo e testes existentes da tela Movimento continuam passando (ajustar apenas os que dependiam da estrutura visual/valor fixo de meta antigos, sem alterar cobertura funcional).
