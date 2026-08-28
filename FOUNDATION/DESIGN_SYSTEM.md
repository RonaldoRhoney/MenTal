# MENTAL — DESIGN_SYSTEM.md

Status: aprovado por Rhoney (dono). Parte oficial da Foundation. Baseado em
pesquisa de tendências de UI mobile/gamificação 2026 e nos princípios já
definidos em `BRAND.md` e `PRODUCT_PRINCIPLES.md` (Clareza Imediata,
não-humilhação). Este documento é a fonte de verdade visual — qualquer tela
nova deve ser avaliada contra ele antes de ser considerada pronta.

## 1. Paleta de cores

| Token | Hex | Uso |
|---|---|---|
| `bg` | `#111013` | Fundo principal. Grafite quente, não preto puro. |
| `bg-2` | `#17161A` | Fundo de cards/superfícies elevadas. |
| `gold` | `#E2BE6E` | Cor de marca primária — CTA principal, destaque de XP/conquista. |
| `teal` | `#3FA796` | Cor de marca secundária — usada em conjunto com gold em gradiente de identidade. |
| `ink` | `#3A3560` | Acento de profundidade — texturas de mapa/território, nunca texto. |
| `bone` | `#EDE7DA` | Texto principal (nunca branco puro — mais suave, reduz fadiga visual). |
| `muted` | `#8A8578` | Texto secundário, metadados, timestamps. |
| `success` | `#3FA796` (reutiliza teal) | Acerto, progresso, confirmação. |
| `warning` | `#E2BE6E` (reutiliza gold) | Atenção sem ser erro (ex: "última tentativa"). |
| `error` | `#C96A5A` (terracota, não vermelho puro) | Erro/limite atingido — tom suave, alinhado ao princípio de não-humilhação. |

**Regra vinculante de uso semântico:** cor não é decoração, é significado.
- Verde/teal **sempre** significa acerto ou progresso positivo — nunca usado
  em elemento neutro só porque "combina".
- A cor de erro é deliberadamente **terracota, não vermelho vivo** — vermelho
  puro sinaliza urgência/perigo (pesquisa de cor confirma essa associação),
  o que contradiz o princípio de não-humilhação do produto. Errar um
  desafio não deve visualmente "assustar".
- Gold é reservado para conquista/CTA principal — usar em excesso dilui o
  destaque que ele deveria comunicar.

## 2. Tipografia

| Família | Uso |
|---|---|
| **Fraunces** (serifada, variável) | Wordmark, títulos de tela, nome de território, número de nível — carrega personalidade de marca. |
| **Inter** (sans-serif) | Corpo de texto, botões, labels de UI — legibilidade em qualquer tamanho de tela. |
| **JetBrains Mono** | Metadados técnicos apenas (streak, XP numérico, coordenadas de território) — nunca em texto de leitura corrida. |

**Requisito de acessibilidade (não-negociável, dado o público misto):**
- Tamanho de fonte mínimo de corpo: 16px equivalente — nunca menor, mesmo
  em elemento secundário.
- Suporte a escala de texto do sistema operacional (usuário que aumenta
  fonte do Android deve ver o app se adaptar, não quebrar layout).
- Contraste mínimo AA (WCAG) entre texto e fundo em todas as combinações
  de cor da paleta — a beleza tipográfica nunca compromete a leitura para
  idoso ou pessoa com baixa visão.

## 3. Princípio de Clareza Imediata — aplicação prática

(Reafirma o princípio já definido em `MENTAL_KICKOFF.md` §7, aqui como
regra de composição visual.)

- Uma ação primária por tela, com prioridade visual clara (tamanho, cor
  gold, posição inferior fixa).
- Máximo de 2 níveis de hierarquia de informação visível ao mesmo tempo
  (ex.: "título da tela" + "conteúdo principal" — não title + subtítulo +
  badge + timer + progress bar todos competindo).
- Espaço em branco é elemento de design, não ausência de conteúdo.

## 4. Componentes de gamificação

Baseado em padrão validado (progress bar, níveis, badges como prova de
mastery — confirmado pela pesquisa como mecanismo comprovado de motivação):

- **Barra de XP**: sempre visível no topo da Home, gradiente gold→teal,
  nunca cor sólida neutra (progresso deve parecer vivo).
- **Território**: tratado como lugar com nome próprio (ex.: "Mente
  Brilhante"), nunca como "Categoria N" — reforça a mecânica de conquista
  em vez de progressão numérica fria.
- **Celebração de acerto**: feedback imediato e positivo (cor teal,
  microanimação leve), nunca apenas texto plano "Correto".
- **Feedback de erro**: tom terracota suave (não vermelho), linguagem de
  encorajamento (já definida em `PRODUCT_PRINCIPLES.md`), nunca acompanhado
  de som ou visual que produza sensação de punição.
- **Separação visual nível × desbloqueio** (requisito já definido em
  `RISKS_AND_OPEN_DECISIONS.md`): a barra de XP/nível e o indicador de
  território desbloqueado devem ser elementos visualmente distintos, nunca
  a mesma barra ou métrica — para não confundir progresso cosmético com
  acesso a conteúdo.

## 5. Splash screen

Já formalizado em `BRAND.md` §3 — este documento não substitui, apenas
referencia: sequência wordmark → slogan → transição direta, sem tela extra.

## 6. Compartilhamento social

Já formalizado em `MENTAL_KICKOFF.md` §6 — reforço visual aqui: o card de
conquista gerado para compartilhamento deve seguir a mesma paleta e
tipografia deste documento (gold/teal sobre fundo escuro, wordmark Fraunces),
para que qualquer compartilhamento espontâneo já funcione como peça de
marca reconhecível, mesmo fora do app.

## 7. Campo de feedback do usuário — posicionamento (novo)

Pesquisa de padrão mobile mostra que ícone fixo no canto inferior — comum
em desktop — é problemático em Android: conflita com navegação do sistema,
botões de ação flutuantes, e a zona de toque do polegar (toques acidentais).
Decisão de posicionamento:

- **Acesso permanente**: item discreto dentro da tela de Perfil ("Enviar
  feedback"), sempre disponível, nunca como elemento flutuante sobre o
  conteúdo do jogo.
- **Prompt contextual pontual**: aparece uma vez, de forma opcional e
  dispensável, após um marco relevante (ex.: primeira conquista de
  território) — nunca como pop-up modal forçado, nunca interrompendo um
  desafio em andamento.
- **Formato**: bottom sheet (desliza da base da tela), não modal central
  — é o padrão mobile mais seguro contra sobreposição de navegação nativa.
- **Sem fricção**: campo de texto livre + opção de nota (1-5), sem
  obrigatoriedade de preencher tudo antes de fechar.

## 8. Critério de aceite

Uma tela está pronta quando: (a) usa exclusivamente os tokens de cor desta
tabela, (b) respeita a hierarquia tipográfica de 3 famílias definida, (c)
tem uma ação primária clara identificável em menos de 2 segundos, (d) passa
em teste de contraste AA, (e) se envolver erro/limite, usa tom terracota
e linguagem de encorajamento — nunca vermelho vivo ou linguagem de bloqueio.

## 9. Papel de cada parte

- **Rhoney**: aprova qualquer desvio deste sistema antes de implementado.
- **Claude (arquitetura)**: garante que toda tela entregue é avaliada
  contra a Seção 8 antes de aprovação técnica.
- **Claude Code**: implementa os tokens de cor/tipografia como constantes
  centralizadas no tema do Flutter (`ThemeData` único) — nunca cor ou fonte
  hardcoded tela por tela.
