# MENTAL — Redesign da Home (Hierarquia Visual + Motion)

**Status:** Aprovado para implementação.
**Referência visual:** mental-home-redesign.html (protótipo estático em HTML/CSS — reproduzir a estrutura, hierarquia, cores e animações descritas abaixo em Flutter; o HTML é referência de layout, não para embutir/rodar como WebView).
**Escopo:** Home screen apenas. Não altera lógica de negócio, endpoints, nem os demais fluxos do app.

---

## 1. Objetivo

A Home atual carrega o branding completo (nome gigante + slogan) toda vez que é aberta, o card de perfil repete Nível e XP duas vezes sem hierarquia clara, os atalhos de navegação (Progresso/Ranking/Amigos/Movimento) competem visualmente com o card de identidade, MentalCoins não aparece em lugar nenhum, e os cards de Mundo surgem na tela sem transição (salto abrupto). Este documento especifica a correção completa.

---

## 2. Cabeçalho de marca (substitui o bloco "MENTAL" + slogan atual)

Remover o título grande "MENTAL" (font ~48px) e o slogan completo abaixo dele. Substituir por um cabeçalho compacto, fixo no topo do scroll da Home:

- Esquerda: logo pequeno (ícone "M" com sinapses, ~26x26) + wordmark "MENTAL" em caixa alta, letter-spacing largo, ~16px, peso 600, fonte serif (mesma família do logo/splash).
- Direita: pill de streak — ícone de chama + "X dias", fundo dourado translúcido (`rgba(226,190,110,0.14)`), borda dourada sutil, texto em fonte monoespaçada.
- Sem slogan nesta tela (o slogan já existe no Splash — repeti-lo na Home é redundante e ocupa espaço que deveria ir para o conteúdo).

## 3. Card de identidade (substitui o card de perfil atual)

Card único, com hierarquia clara e **sem nenhuma informação duplicada**:

**Linha superior:**
- Avatar (foto real do usuário) à esquerda, 56x56, borda dourada, com um badge circular pequeno sobreposto no canto inferior direito mostrando só o número do nível (ex: "44"), fundo teal.
- Ao lado: nome do usuário em destaque (fonte serif, ~19px, peso 600) e, abaixo dele, uma linha secundária "Nível X · Conquistador" (ou título equivalente de progressão, se existir) em teal, ~12px.
- À direita, alinhado: badge de **MentalCoins** — ícone de moeda circular (gradiente dourado) + valor numérico, em pill com fundo dourado translúcido. **Esta é a primeira vez que MentalCoins aparece na Home — adicionar mesmo que o valor venha zerado/mockado até a feature ter API própria.**

**Bloco de XP (abaixo, único lugar onde XP aparece):**
- Linha com label "Progresso do nível" à esquerda e valor "37 / 100 XP" à direita (estilo monoespaçado).
- Barra de progresso: trilho escuro com borda sutil, preenchimento em gradiente dourado→teal (esquerda para direita), cantos arredondados full-pill.

**Linha de metadados (abaixo da barra, separada por divisor horizontal sutil):**
- Três colunas: XP total acumulado ("XP total"), Mundos completos/total ("Mundos"), posição no ranking ("Ranking"). Cada uma com número em destaque (monoespaçado, ~13px) e label pequeno abaixo (~9.5px, uppercase, cor apagada).

**Remover:** a linha antiga "XP: 4337 · Nível 44 · Streak: 4 dias" — essa informação já está distribuída nos elementos acima (Nível no badge do avatar, XP total nos metadados, Streak no pill do cabeçalho). Repeti-la de novo era a causa da redundância.

## 4. Navegação rápida (Progresso / Ranking / Amigos / Movimento)

Manter os 4 atalhos, mas **reduzir seu peso visual** para deixar claro que são navegação secundária, não o foco da tela:
- Grid de 4 colunas, cards menores que os atuais (padding reduzido), fundo levemente mais escuro que o card de identidade, sem o mesmo destaque de borda/contraste.
- Ícone pequeno (~18px) + label (~10px). Sem a saturação de cor que competia com o card principal.

## 5. Cards de Mundo (Mundo da Linguagem / Mundo da Mente Lógica)

Cada card de Mundo passa a ter identidade visual própria, não mais uma linha genérica de lista:
- Fundo com leve gradiente diagonal, cor de identidade própria por mundo (ex: tons esverdeados para Mundo da Linguagem, tons dourados/terrosos para Mundo da Mente Lógica — ou seguir a paleta que já existir para cada mundo no app).
- Ícone circular à esquerda (emoji ou ícone customizado representando a temática do mundo) + nome do mundo (serif, ~16.5px) + subtítulo listando as categorias internas (ex: "Palavras · Textos · Enigmas") em texto pequeno apagado.
- Selo circular de "completo"/status à direita (mantém o check atual, mas redesenhado como círculo preenchido na cor do mundo, não mais um ícone solto).
- **Nova barra de progresso dentro do card**, abaixo do cabeçalho: trilho fino + preenchimento na cor do mundo + label percentual (ex: "78% concluído") em monoespaçado. Isso hoje não existe e é a principal adição funcional desta seção.

## 6. Card de Missão do Dia (novo — preenche o espaço vazio abaixo dos Mundos)

Adicionar um card novo abaixo dos Mundos, antes do fim do scroll:
- Cabeçalho pequeno: bolinha indicadora (dot teal) + label "Missão de hoje" em uppercase.
- Texto da missão com destaque em negrito/dourado nos números-chave (ex: "Complete **3 desafios** para manter seu streak vivo e ganhar **+15 MentalCoins**").
- Barra de progresso horizontal fina + contador (ex: "2/5") ao lado.
- Este card consome dados que já existem (contagem de desafios do dia, streak) — não requer nova tabela; se a lógica de "missão diária" com recompensa ainda não existir no backend, implementar como client-side por enquanto usando a contagem de desafios já disponível, e marcar como TODO a formalização server-side quando a arquitetura de MentalCoins for definida.

## 7. Motion / animação de entrada (resolve o "salto" reportado)

Toda a Home deve entrar em **cascata suave** ao carregar, não tudo de uma vez:
1. Cabeçalho de marca: fade + leve translação vertical (~8px), ~500ms, delay ~50ms.
2. Card de identidade: fade + rise (~10px), ~550ms, easing tipo `cubic-bezier(0.2, 0.8, 0.2, 1)`, delay ~120ms. A barra de XP interna anima o preenchimento (`width: 0% → valor real`) crescendo da esquerda, ~1s, delay ~400ms (depois do card já estar visível).
3. Navegação rápida: fade + translação, ~500ms, delay ~200ms.
4. Label de seção "Sua jornada": fade + translação, delay ~300ms.
5. Cards de Mundo: fade + rise mais pronunciado (~14px), easing tipo `cubic-bezier(0.16, 0.9, 0.3, 1)`, entrando em sequência — primeiro Mundo com delay ~380ms, segundo com delay ~460ms (stagger de ~80ms entre eles).
6. Card de Missão do Dia: mesmo estilo dos cards de Mundo, delay ~540ms (último a entrar).

Em Flutter, implementar com `AnimatedOpacity` + `AnimatedSlide` (ou `flutter_animate` se já for dependência do projeto) orquestrados por delays incrementais no `initState`/primeiro `build` da Home — sem depender de scroll-trigger, é uma sequência de carregamento único ao entrar na tela.

**Importante:** respeitar `reduced motion` do sistema operacional (se o Flutter/OS sinalizar preferência de movimento reduzido, pular direto para o estado final sem animação).

## 8. O que NÃO muda nesta entrega

- Bottom navigation (Início/Perfil/Configurações/Batalhas/Enviar feedback) — mantém como está.
- Lógica de dados (fonte de Nível, XP, Streak, Mundos) — só mudam onde/como são exibidos, não de onde vêm.
- Estrutura de rotas e navegação entre telas.
- MentalCoins: exibir o valor já existente se a API tiver campo pronto; caso não tenha, mockar com 0 e marcar como TODO visível no código (`// TODO: MentalCoins ainda sem arquitetura definida — ver V3/TRIAGEM_FEEDBACK_TESTE.md`) até a feature ser formalizada.

## 9. Critério de aceite

- Nenhuma informação (Nível, XP, Streak) aparece duplicada na tela.
- MentalCoins visível no card de identidade.
- Cards de Mundo com barra de progresso própria.
- Card de Missão do Dia presente, preenchendo o espaço antes vazio.
- Entrada da tela em cascata perceptível (sem "pop" instantâneo de todos os elementos ao mesmo tempo).
- `flutter analyze` limpo e testes existentes da Home continuam passando (ajustar apenas os que dependiam da estrutura visual antiga, sem alterar cobertura funcional).
