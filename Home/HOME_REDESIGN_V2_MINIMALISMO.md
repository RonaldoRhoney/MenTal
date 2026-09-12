# MENTAL — Home Redesign V2: Redução de Toques, Sem Redundância de Marca

**Status:** Aprovado para implementação imediata.
**Substitui/expande:** HOME_REDESIGN_V1.md, no que diz respeito ao cabeçalho de marca e ao grid de atalhos. As demais decisões daquele documento (card de identidade, Mundos, animação de entrada) permanecem válidas.
**Referência visual:** mental-home-v3-watermark.html (protótipo estático HTML/CSS, versão final revisada — reproduzir estrutura, hierarquia, cores, proporções e o alinhamento do grid de atalhos).

---

## 1. Princípio central desta mudança

O usuário deve gastar o mínimo de toques e o mínimo de tempo de leitura possível entre abrir o app e começar a jogar. Toda tela — especialmente a Home, que é vista em praticamente toda sessão — deve ser avaliada por esse critério: cada elemento nela precisa justificar sua presença, ou é removido/consolidado.

## 2. Justificativa: por que remover "MENTAL" + slogan como bloco de texto da Home

O nome do aplicativo e o slogan já são apresentados ao usuário na Splash Screen, no primeiro instante de abertura do app — antes mesmo de qualquer navegação. Repeti-los como bloco de texto na Home, a primeira tela de navegação real, é redundância pura: o usuário já sabe que app está usando, o ícone na tela inicial do celular já carrega essa informação, e a Splash já reforça isso a cada abertura. Esse bloco de texto ocupava espaço vertical valioso e adiava visualmente o que realmente importa (identidade do jogador, progresso, atalhos de ação).

**Solução adotada — marca d'água, não remoção total da identidade visual:** em vez de eliminar a marca da Home por completo, a palavra "MENTAL" passa a existir como uma textura de fundo (marca d'água), presente em toda a tela, mas em opacidade muito baixa, numa camada que fica atrás de todo o conteúdo e nunca recebe toque. Isso preserva a identidade visual do app sem repetir informação de forma redundante — o mesmo recurso usado por apps de banco e produtividade para reforçar marca sem gastar espaço de UI.

## 3. Mudanças aplicadas

### 3.1 Wordmark vira marca d'água de fundo
- "MENTAL" e o slogan, como bloco de texto de destaque, são removidos da Home.
- Em seu lugar, "MENTAL" passa a existir como marca d'água: texto em opacidade muito baixa (~4.5%), levemente rotacionado, ocupando uma camada de fundo (z-index inferior a todo o conteúdo).
- Essa camada nunca intercepta toque — nenhum risco de capturar cliques destinados aos cards acima dela.
- Cards, grid de atalhos e barra de busca recebem leve transparência e desfoque (blur) para que a marca d'água "respire" através deles, sem prejudicar a legibilidade do conteúdo principal.
- O card de identidade do jogador (avatar, nome, nível, XP, MentalCoins, streak) passa a ser o primeiro elemento de conteúdo visível ao abrir a tela, com a marca d'água apenas como textura por trás dele.

### 3.2 Remoção do banner de coleta de Movimento
- O banner "Colete seus bônus de Movimento" (e qualquer alerta equivalente sobre passos/ciclo pendente) deixa de aparecer na Home.
- Esse tipo de alerta passa a existir exclusivamente dentro da tela Movimento.
- O badge numérico (ex.: "966") no ícone de Movimento no grid de atalhos já cumpre a função de sinalizar "há algo pendente aqui", sem precisar de um banner de texto ocupando espaço vertical adicional.

### 3.3 Grid de atalhos: de 4 para 5 cards, com proporção idêntica entre todos
- O grid de atalhos passa a ter 5 cards: Progresso, Ranking, Amigos, Movimento, e um novo 5º card (rotulado "Mais").
- **Requisito explícito de alinhamento:** os 5 cards devem ter exatamente a mesma largura, altura, padding interno e estrutura de layout — nenhum card pode ter proporção diferente dos demais. O 5º card segue rigorosamente o mesmo padrão visual dos outros 4 (mesmo container, mesmo espaçamento, mesmo tamanho de fonte no rótulo).
- O 5º card consolida dois ícones no espaço onde os outros cards têm um único ícone: o ícone de **compartilhar/convidar** e o ícone de **alternar tema claro/escuro**, lado a lado, separados por uma linha divisória vertical fina e curta — sem alterar a altura ou padding do card em relação aos demais.
- Abaixo dos dois ícones, um único rótulo curto ("Mais"), no mesmo tamanho de fonte e mesmo estilo dos rótulos dos outros 4 cards — sem quebra de linha estranha, sem texto maior que o espaço disponível.
- Isso remove dois elementos que antes "flutuavam" soltos no cabeçalho (fora do fluxo de navegação principal) e os integra à mesma grade visual dos demais atalhos, com paridade total de tamanho.

## 4. O que NÃO muda

- Estrutura do card de identidade, animação de entrada em cascata, e listagem de Mundos abaixo do grid de atalhos — tudo conforme já definido em HOME_REDESIGN_V1.md.
- Paleta de cores padrão do app — nenhuma mudança de cor nesta entrega.
- O conteúdo/funcionalidade de compartilhar e de alternar tema não muda — apenas a localização visual dos dois ícones na tela.

## 5. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Substituir o widget de wordmark/slogan por uma camada de marca d'água: texto "MENTAL" renderizado com opacidade baixa (~0.045), leve rotação, posicionado atrás de todo o conteúdo da tela (camada de fundo, sem interceptar gestos de toque).
- Aplicar leve transparência + blur nos containers de card (identidade, grid de atalhos, busca, itens de Mundo) para que a marca d'água seja perceptível através deles sem comprometer legibilidade.
- Remover o banner de Movimento da árvore de widgets da Home — sem necessidade de nova lógica de dado, é remoção de UI.
- Grid de atalhos: implementar como 5 colunas de largura/altura idênticas (ex.: `GridView` ou `Row` com `Expanded`/`flex: 1` igual em todos os itens) — garantir que nenhum item do grid receba padding, altura ou estrutura de layout diferente dos demais.
- O novo 5º card reaproveita os handlers de ação já existentes para compartilhar e para alternar tema — apenas muda onde esses botões estão posicionados na árvore de widgets, não a lógica por trás de cada ação. Cada um dos dois ícones dentro do card deve manter sua própria área de toque reconhecível (não é preciso que o card inteiro dispare as duas ações ao mesmo tempo — cada ícone aciona sua própria função).
- Garantir que o badge de Movimento (contador de passos pendentes) continua funcionando exatamente como antes.

## 6. Critério de aceite

- Home não exibe mais "MENTAL" nem o slogan como bloco de texto de destaque — a palavra "MENTAL" aparece apenas como marca d'água de fundo, em opacidade baixa, sem interceptar toque.
- Home não exibe mais o banner "Colete seus bônus de Movimento" — esse alerta só aparece dentro da tela Movimento.
- Grid de atalhos exibe 5 cards com largura, altura e padding **idênticos entre si** — nenhuma assimetria visual entre o 5º card e os outros 4.
- O 5º card exibe dois ícones (compartilhar e tema) lado a lado com divisor fino, e um único rótulo curto abaixo, no mesmo estilo dos demais cards.
- Toque no ícone de compartilhar aciona a mesma função de compartilhamento já existente; toque no ícone de tema aciona a mesma função de alternância de tema já existente — cada ícone com sua própria área de toque.
- Nenhuma cor padrão do app foi alterada nesta entrega.
- Número de toques necessários para sair da Home e chegar a qualquer uma das 5 ações do grid permanece o mesmo de antes (1 toque).

## 7. Prioridade de implementação

Esta entrega está com o protótipo visual já validado e ajustado (mental-home-v3-watermark.html) — pronta para implementação e teste ainda hoje, sem necessidade de nova rodada de aprovação de design.
