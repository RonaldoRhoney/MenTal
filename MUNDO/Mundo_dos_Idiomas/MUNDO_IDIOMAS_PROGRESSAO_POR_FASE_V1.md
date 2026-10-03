# MENTAL — Progressão por Fase (desbloqueio sequencial por família de território)

**Arquitetura genérica (qualquer Mundo com territórios em família Básico/Intermediário/Avançado); hoje só o Mundo dos Idiomas tem essa estrutura, então é o único afetado na prática.**

**Status:** PROPOSTO (03/10/2026) — aguardando aprovação de Rhoney antes de qualquer implementação. Nasceu de uma observação direta testando o app: a aba Inglês hoje mostra 15+ territórios de uma vez (Básico a Avançado de cada frente, mais Relâmpago de cada um), todos simultaneamente navegáveis — sobrecarga de opção que o modelo do Duolingo evita de propósito.

**Escopo ampliado (03/10/2026):** este documento passou a ser também a resposta às seções §4 e §5.1 de `MENTAL_ESPECIFICACAO_FLUXO_PROGRESSAO_MAPA_RANKING_FEEDBACK_V1.1.md` (progressão sequencial por Mundo + progresso visível dentro do próprio Mundo) — diagnóstico confirmou que, como só o Mundo dos Idiomas tem territórios separados por nível (Básico/Intermediário/Avançado), a proposta já escrita aqui cobre inteiramente o que aquele documento pede em §4, sem precisar generalizar pra mais nenhum Mundo (decisão de escopo de Rhoney). §6 e §7 abaixo são a parte nova, cobrindo especificamente §5.1 daquele documento (indicador de progresso dentro da tela do Mundo + celebração de Mundo conquistado no próprio contexto), que a versão anterior deste doc não cobria.

---

## 1. Objetivo

Hoje `is_territory_unlocked` só decide acesso por **assinatura** (amostra grátis + status de assinatura) — nunca por progresso em outro território. Dentro do Mundo dos Idiomas, isso significa que um usuário pode pular direto pro Inglês Avançado sem nunca ter tocado no Básico, e a tela de territórios expõe toda a extensão de cada frente de uma vez, mesmo a parte que não faz sentido tentar ainda.

Este documento propõe um desbloqueio sequencial **dentro de cada "família" de território** (ex.: Phrasal Verbs Básico → Intermediário → Avançado), inspirado no modelo de fase do Duolingo — sem copiar o modelo inteiro, que é pensado pra uma trilha linear única, incompatível com a estrutura de Mundos independentes do MENTAL (ver §2 sobre o porquê do escopo ser restrito a Idiomas).

## 2. Escopo — hoje só se aplica a Idiomas, mas o mecanismo é genérico por desenho

Levantamento real no `app/seed.py`: o padrão de território dividido em Básico/Intermediário/Avançado **existe hoje exclusivamente dentro do Mundo dos Idiomas** — 19 famílias ao todo (Inglês base, Espanhol, Francês, e as 8 frentes de Inglês: Phrasal Verbs, Expressões, Conjugação, Compostas, Contrações, Compreensão de Texto, Falsos Cognatos, Preposições e Artigos — cada uma com variante Relâmpago). Nenhum outro Mundo (Trânsito, Mitologia, Lógica, etc.) usa essa estrutura — são territórios únicos com dificuldade adaptativa interna, não níveis separados.

**Decisão de arquitetura (03/10/2026, pedido de Rhoney): o mecanismo não deve ficar restrito a Idiomas no código** — a implementação (§3) detecta "família sequencial" pelo **padrão de nomenclatura do `territory_id`** (sufixo `_basico`/`_intermediario`/`_avancado`, com ou sem o infixo `_relampago_`), nunca por uma checagem explícita de `world_id == "idiomas"` ou `block_id == "ingles"`. Na prática, isso significa: **se algum Mundo futuro adotar essa mesma estrutura de níveis (ex.: Trânsito ganhar `transito_basico`/`transito_intermediario`/`transito_avancado`), o desbloqueio sequencial, a trilha interna (§6) e a celebração de Mundo (§7) passam a valer pra ele automaticamente, só com a curadoria de conteúdo — sem precisar tocar de novo nesse mecanismo.**

Hoje, na prática, a mudança só é visível no Mundo dos Idiomas (único que tem essa estrutura agora) — fora dele, a navegação continua 100% livre, exatamente como é hoje. Mas é uma consequência do estado atual do conteúdo, não de uma restrição deliberada no código.

## 3. Mecanismo de desbloqueio

- **Detecção de família por nomenclatura, não por Mundo/Bloco hardcoded**: dado um `territory_id`, a "família" é o prefixo antes do sufixo de nível (`_basico`/`_intermediario`/`_avancado`, ignorando o infixo opcional `_relampago_` — ex.: `ingles_phrasal_basico` e `ingles_phrasal_relampago_basico` pertencem à mesma família `ingles_phrasal`). Território cujo id não termina num desses três sufixos simplesmente não participa do mecanismo — continua liberado como hoje, em qualquer Mundo.
- Dentro de cada família (ex.: `ingles_phrasal_basico` → `ingles_phrasal_intermediario` → `ingles_phrasal_avancado`), o nível seguinte só fica desbloqueado depois que o nível anterior é **conquistado** (`UserTerritoryProgress.conquered_at` preenchido — o mesmo marco que já dispara a celebração "Território conquistado!" hoje, baseado em XP acumulado naquele território, não em ranking/detentor, que é relativo e pode regredir).
- **Famílias diferentes continuam independentes entre si** — terminar Phrasal Verbs não é pré-requisito pra começar Expressões Idiomáticas, por exemplo. O gate é só DENTRO da progressão Básico→Intermediário→Avançado de uma mesma frente, nunca entre frentes diferentes.
- **Relâmpago de um nível desbloqueia junto com o normal do mesmo nível** — é o mesmo conteúdo em modo mais difícil/cronometrado, não um passo extra na sequência.
- **Usuários que já têm progresso real não são retroativamente trancados**: um território com qualquer tentativa já registrada (`Attempt` existente) conta como desbloqueado, independente da ordem em que foi jogado antes desta mudança existir — a regra nova vale só daqui pra frente, nunca tranca de volta o que a pessoa já estava jogando.

## 4. Onde aparece para o usuário

**Ajuste de escopo (03/10/2026, pedido de Rhoney):** diferente da primeira versão deste documento (que mostrava o nível bloqueado com cadeado, só pra dar visão do caminho completo), a decisão final é mais enxuta — **o nível ainda não alcançado nem aparece na lista**, não só fica desabilitado. Só ficam visíveis: o nível **atual** (o que o usuário está jogando agora) e os níveis **já conquistados** daquela família (pra poder voltar e revisar/rejogar — nunca perde acesso ao que já destravou). Quando o nível atual é conquistado, o próximo nível da família aparece na lista — ele não existia visualmente ali antes disso.

Exemplo prático: dentro do Mundo dos Idiomas, se o usuário está no Inglês Phrasal Verbs Básico, só esse nível aparece na lista de Phrasal Verbs — Intermediário e Avançado **nem aparecem ainda**. Ao conquistar o Básico, o Intermediário passa a aparecer (e o Básico continua visível, já conquistado, disponível pra rejogar).

Isso vale **por família**, não pro Mundo inteiro — cada frente (Phrasal Verbs, Expressões, Conjugação etc.) revela seu próprio nível atual de forma independente, reduzindo de fato o tamanho da lista exibida a cada momento, em vez de só esconder visualmente o que já estava ali.

## 5. Integração com as mecânicas já formalizadas do Mundo dos Idiomas

- Não interfere em Imersão Progressiva, Constelação de Palavras, Repetição Espaçada — todas continuam operando normalmente sobre o conteúdo já desbloqueado.
- `is_territory_unlocked` ganha uma checagem adicional, baseada só no padrão de nomenclatura (§3) — território sem o sufixo de nível não é afetado, não importa o Mundo.

## 6. Progresso visível dentro da tela do Mundo (cobre §5.1 de MENTAL_ESPECIFICACAO...)

- **Componente genérico, por Mundo**: qualquer Mundo que tenha pelo menos uma família sequencial (§2/§3) ganha, na própria tela daquele Mundo, um indicador compacto de trilha por família — 3 marcadores (Básico/Intermediário/Avançado), preenchido conforme `conquered_at`: conquistado (preenchido), atual (destacado), e os ainda não alcançados representados só como ponto neutro na trilha (não como card cheio — isso já foi resolvido em §4, que tira o card da lista; a trilha é só um resumo visual compacto de "onde você está" dentro daquela família, complementar à lista de cards, não duplicando a mesma informação do mesmo jeito). Mundo sem nenhuma família sequencial simplesmente não ganha esse componente — nada muda pra ele.
- A trilha usa o mesmo dado já consumido por §3/§4 (`UserTerritoryProgress.conquered_at` por território) — nenhuma estrutura de estado nova, como o próprio `MENTAL_ESPECIFICACAO...md` §10 exige.
- Reaproveita a linguagem visual já estabelecida no Mapa de Trajetória (`MAPA_TRAJETORIA_MUNDOS_V1.md` — cor de identidade, estrelas, "fog of war" pro que ainda não foi alcançado) em escala local da família, em vez de inventar um estilo novo.
- Hoje, na prática, só a tela do Mundo dos Idiomas mostra isso (único Mundo com famílias sequenciais) — ver §2.

## 7. Celebração de Mundo conquistado + sincronização com o mapa externo

- **Detecção, genérica por Mundo**: reaproveita 100% `services.is_world_completed(db, user_id, world_id)`, a mesma função já usada hoje pra pagar `WORLD_COMPLETION_BONUS_XP` (100 XP) no resultado do Desafio (`challenges.py`, `world_just_completed`) — nunca um cálculo novo e paralelo, e nunca restrita a um `world_id` fixo no código. Pra Idiomas hoje: `world_id="idiomas"` inclui Inglês **e** Espanhol **e** Francês — conquistar só as famílias de Inglês não fecha o Mundo inteiro enquanto Espanhol/Francês não tiverem território próprio conquistado também (hoje eles têm só os territórios-base, sem as frentes extras do Inglês).
- **Onde aparece**: quando o jogador está dentro da tela de um Mundo no momento exato em que a última conquista fecha aquele Mundo, uma celebração aparece ali, no contexto — não só como modal "flutuante" vindo do resultado do Desafio (que já existe) e nunca mais é visto de novo se o jogador não estava olhando pra Home naquele instante.
- **Sincronização obrigatória com o mapa externo** (exigência explícita de `MENTAL_ESPECIFICACAO...md` §5.1): o mesmo evento de "Mundo conquistado" que dispara a celebração aqui dentro é o que já atualiza o planeta daquele Mundo pra `status=completed` no Mapa de Trajetória (`get_trajectory_map`) — não dois eventos separados, o mesmo dado (`is_world_completed`) lido nos dois lugares, nunca podendo divergir.
- **Som**: reaproveita a categoria `celebration` já existente em `FeedbackService`, mas esta é justamente uma das lacunas que `MENTAL_ESPECIFICACAO...md` §7 aponta — vale um som distinto/mais elaborado pra esse marco específico (ver nota de risco da tabela §7 daquele documento). Decisão de escopo pra Rhoney: incluir esse som novo agora, ou aceitar reaproveitar o `celebration` genérico por ora e tratar sons distintos por evento como uma entrega separada (ligada ao restante de `MENTAL_ESPECIFICACAO...md` §7, que cobre bem mais do que só este caso).
- Hoje, na prática, só o Mundo dos Idiomas pode disparar essa celebração internamente, já que é o único com famílias sequenciais fazendo parte do critério — mas o mecanismo em si (`is_world_completed` + celebração no contexto) já funciona pra qualquer Mundo que o backend reporte como completo, independente de ter ou não famílias sequenciais.

## 8. Critério de aceite

- Dentro de uma família sequencial (qualquer Mundo), o nível N+1 **nem aparece na lista** até o nível N ser conquistado (`conquered_at` preenchido) — não é só "aparece bloqueado", é ausente da tela.
- Níveis já conquistados continuam visíveis e jogáveis (nunca somem depois de destravados).
- Famílias diferentes continuam navegáveis de forma independente — nenhuma trava cruzada entre frentes diferentes.
- A detecção de família sequencial é só por padrão de nomenclatura do `territory_id` (§3) — **nenhum `world_id`/`block_id` hardcoded no mecanismo**, verificável lendo o código: um Mundo novo com territórios `_basico`/`_intermediario`/`_avancado` passa a ter desbloqueio sequencial, trilha interna e celebração de Mundo automaticamente, só com curadoria de conteúdo.
- A tela de um Mundo com família sequencial mostra, por família, um indicador de trilha refletindo `conquered_at` real (§6) — nunca um estado paralelo que pode divergir do que os cards já mostram.
- Ao conquistar um Mundo inteiro (via `is_world_completed`, genérico por `world_id`), uma celebração aparece dentro da própria tela do Mundo, no momento em que acontece — não só como modal vindo de um Desafio específico (§7).
- O planeta correspondente no Mapa de Trajetória e a celebração interna nunca mostram estados divergentes — mesmo evento, mesma fonte de dado (§7).
- Relâmpago desbloqueia junto do normal do mesmo nível.
- Usuário com progresso real já registrado antes da mudança não perde acesso a nada que já tinha jogado.
- Hoje, na prática, só o Mundo dos Idiomas é afetado (único com famílias sequenciais) — qualquer outro Mundo sem essa estrutura continua 100% livre, sem nenhuma mudança de comportamento.
- Revisão e aprovação de Rhoney antes de qualquer implementação, dado que isso muda um comportamento já em produção pra usuários reais (MENTAL em teste fechado ativo).
