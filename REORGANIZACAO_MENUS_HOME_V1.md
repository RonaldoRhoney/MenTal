# MENTAL — Reorganização de Menus e Redução de Toques na Home

**Status:** Implementado (06/09/2026) — ver seção 9.
**Origem:** Revisão de 13 capturas de tela reais do app em uso, identificando sobrecarga visual na Home e necessidade de espaço para o Feed ganhar destaque próprio.
**Correção nesta versão:** a análise passa a ser guiada por afinidade real entre funções (agrupar o que é parecido em natureza), não apenas por "juntar dois menus para sobrar espaço". A fusão de Amigos+Batalhas deixa de ser a solução principal e passa a ser apenas uma sugestão adicional, condicionada a fazer sentido de verdade.

---

## 1. Diagnóstico do estado atual

### 1.1 Inventário de navegação hoje
- **Grid de atalhos (quicknav)**, 5 cards: Progresso, Ranking, Amigos, Movimento, Mais (compartilhar + alternar tema claro/escuro).
- **Barra inferior**, 5 itens: Início, Perfil, Ajuste, Batalhas, Feedback.
- **Lista de Mundos**, exibida com scroll e uma seta de "ver mais" para revelar Mundos além dos primeiros 5 visíveis.
- **Feed**, hoje sem entrada própria e visível na navegação principal — é preciso já saber que ele existe para chegar até ele.

### 1.2 Problema identificado
A Home tem 10 pontos de navegação de primeiro nível (5+5) mais a lista de Mundos, e nenhum espaço de destaque para o Feed — recurso que acabou de ganhar mecânica própria (eventos automáticos de conquista, sistema de seguir/fã) e merece a mesma visibilidade de Ranking ou Amigos, não ficar escondido.

## 2. A verdadeira oportunidade de consolidação: "Mais" pertence ao Ajuste

### 2.1 Por que compartilhar e tema não deveriam ter card próprio no grid principal
O card "Mais" reúne duas funções — compartilhar/convidar e alternar tema claro/escuro — que são, por natureza, **configurações do app**, não ações de jogo como Progresso, Ranking ou Movimento. Colocar uma função de configuração lado a lado com os atalhos de gameplay principal mistura duas categorias diferentes de ação, e ocupa um espaço nobre do grid principal com algo que o usuário toca raramente.

### 2.2 Proposta de consolidação
Mover as duas funções do card "Mais" para dentro da tela **Ajuste**, que já existe na barra inferior e já é o lugar natural onde o usuário espera encontrar esse tipo de opção — exatamente como você descreveu, no mesmo espírito de "abrir um menu no Chrome" e encontrar configurações do navegador ali, não espalhadas pela tela principal.

Isso libera, sozinho, uma posição inteira no grid de atalhos — sem precisar mexer em Amigos nem em Batalhas.

## 3. Onde o Feed ganha seu espaço

Com a posição liberada pela consolidação da seção 2, o **Feed** passa a ocupar esse lugar no grid de atalhos, ganhando entrada própria e visível na navegação principal, sem precisar mais ser descoberto por acaso.

### 3.1 Novo grid de atalhos proposto (mesma contagem de 5, sem o card "Mais")
Progresso · Ranking · Amigos · Movimento · **Feed**

### 3.2 Barra inferior permanece como está, com uma adição interna
Início · Perfil · **Ajuste** (agora também com compartilhar/convidar e alternar tema) · Batalhas · Feedback

## 4. Amigos + Batalhas: sugestão adicional, não obrigatória

Como você apontou, essa fusão só faz sentido se houver afinidade real, não apenas para "sobrar espaço" — e como o espaço para o Feed já foi resolvido pela consolidação da seção 2, essa fusão deixa de ser necessária.

**Ainda assim, fica registrada como sugestão de qualidade**, caso você queira avaliar depois: as duas telas já são etapas de uma mesma jornada (o botão "Desafiar" em Amigos leva direto à criação de uma Batalha, e o histórico de Batalhas mostra resultados contra esses mesmos amigos). Se decidir seguir com isso no futuro, a proposta seria uma única tela "Amigos" com duas abas internas (Amigos / Batalhas) — mas isso é opcional e independente do que já foi resolvido nas seções 2 e 3.

## 5. É plausível mostrar todos os Mundos sempre expandidos na Home?

**Análise: não é recomendável, e a resposta muda com o tempo.** O app já tem 6 Mundos hoje, com mais em roadmap (Trânsito, Gastronomia, Oceanos, Espaço) — o número de Mundos só tende a crescer. Mostrar todos sempre expandidos traria de volta o problema de "página carregada", só que pior a cada novo Mundo lançado.

### 5.1 Recomendação alternativa
- Transformar a lista vertical de Mundos num **carrossel horizontal compacto** de cards (ícone + nome), permitindo ver mais Mundos "de relance" sem depender da seta de expandir — sem crescer a altura da tela conforme novos Mundos forem adicionados.
- Adicionar um card de **"Continuar de onde parei"** no topo da Home, mostrando o último território/desafio jogado, com toque único para retomar — ataca diretamente o pedido de "menos toques até o jogador desfrutar do jogo".

## 6. Resumo do impacto

- **Card "Mais" eliminado do grid principal**, suas funções absorvidas pelo Ajuste, onde já pertencem por natureza.
- **Feed ganha lugar de destaque** no grid de atalhos, sem aumentar a contagem total de itens visíveis.
- **Amigos e Batalhas permanecem como estão hoje**, com a fusão registrada apenas como sugestão futura opcional.
- **Preparado para crescimento**: a solução de carrossel de Mundos não piora conforme novos Mundos forem lançados.
- **Menos toques para jogar**: o card "Continuar de onde parei" reduz a jornada até o próximo desafio.

## 7. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Mover as ações de compartilhar/convidar e alternar tema para dentro da tela Ajuste já existente, removendo o card "Mais" do grid de atalhos.
- Adicionar Feed como novo item do grid de atalhos, na posição liberada, com navegação direta para a tela já existente de Feed.
- Avaliar viabilidade de um card "Continuar de onde parei" — depende de o backend já registrar (ou passar a registrar) o último desafio/território acessado por usuário.
- Conversão da lista de Mundos para carrossel horizontal é uma mudança de layout, reaproveitando os mesmos dados já usados na lista atual.
- Fusão de Amigos+Batalhas (seção 4) fica registrada como item de backlog, não faz parte desta entrega.

## 8. Critério de aceite

- Card "Mais" não existe mais no grid de atalhos da Home; suas duas funções (compartilhar/convidar e tema) estão acessíveis dentro da tela Ajuste.
- Feed aparece com entrada própria no grid de atalhos da Home.
- Nenhuma funcionalidade existente é removida — apenas reorganizada.
- Amigos e Batalhas continuam funcionando exatamente como hoje, sem fusão nesta entrega.
- Lista de Mundos não obriga mais rolagem vertical extensa para ser vista por completo.

## 9. Implementação (06/09/2026)

- **§2 (Mais → Ajuste)**: `client/lib/screens/home_screen.dart` — card "Mais"
  removido do grid de atalhos junto com `_shareApp()`, `_coinsRise` e as
  classes `_MergedActionCard`/`_MiniIconAction`/`_ThemeModeMiniToggle`.
  `client/lib/screens/settings_screen.dart` — nova seção "Compartilhar e
  Aparência" no topo da lista: `ListTile` de convidar amigos (mesma
  função, mesmo `CoinsRiseOverlay` reaproveitado) + `SwitchListTile` de
  tema escuro/claro.
- **§3 (Feed no grid)**: 5º card do grid agora é Feed
  (`Icons.dynamic_feed_rounded`, `AppColors.purple`), navega pra
  `FeedScreen` — badge de eventos não vistos (`FeedActivityService`)
  migrou do card Amigos (implementação anterior, mesma sessão) pra este
  card, mais coerente agora que o Feed tem entrada própria.
- **§5/§7/§8 (carrossel de Mundos)**: lista vertical de `ExpansionTile`
  (`_WorldSection`) substituída por um carrossel horizontal
  (`_buildWorldCarousel`, `_WorldCarouselCard` — ícone por Mundo via
  `_worldIcon(world_id)`, com fallback genérico pra Mundos futuros ainda
  sem ícone definido). Ao tocar, abre uma tela dedicada
  (`_WorldDetailScreen`) só com os territórios daquele Mundo — decisão
  tomada com Rhoney de não expandir nada in-place na Home. A antiga seta
  "há mais Mundos abaixo" (`_MoreWorldsBelowHint`/`_worldsScrollController`)
  foi removida por ficar obsoleta: o problema que ela resolvia (rolagem
  vertical sem pista visual) deixa de existir com o carrossel.
- **"Continuar de onde parei" (§5.1/§7)**: não implementado nesta
  entrega — item hedged no próprio documento original ("depende de o
  backend já registrar"), fora do critério de aceite da seção 8.
- **Fusão Amigos+Batalhas (§4)**: não implementada, registrada como
  backlog opcional, conforme já previsto na seção 4.
- Testes: `client/test/home_screen_test.dart` (grid de 5 cards sem
  "Mais", carrossel mostra selo de completo e abre tela dedicada ao
  tocar), `client/test/settings_screen_test.dart` (nova seção de
  compartilhar/tema em Ajuste). Suíte client completa: 142/142.
