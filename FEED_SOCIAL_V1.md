# MENTAL — Feed Social de Conquistas + Seguir/Fã (Piloto)

**Status:** Backend implementado (06/09/2026) — ver seção 10. Client (telas Flutter: Feed, botão seguir/fã no perfil público) ainda pendente.
**Contexto/justificativa:** Pedido espontâneo de múltiplos testadores durante o teste fechado. Pesquisa de mercado confirma que recursos sociais (feed de conquistas) são um dos fatores de maior impacto em retenção de apps gamificados — comparável ou superior a badges e pontos isolados. Essa possibilidade já estava registrada como ideia de longo prazo antes do app se tornar 18+; a mudança de público (MENTAL-DIR-001) remove a restrição original que motivava adiar esse recurso.
**Documentos relacionados:** PERFIL_PUBLICO_E_TORCIDA_V1.md, TORCIDA_MULTIPLA_V2.md, RANKING_ENRIQUECIDO_V1.md (o Feed se conecta a esses três recursos sociais já existentes), APROVACAO_CORRECOES_PRE_AAB_V1.md (item A1 — bloqueio efetivo, requisito obrigatório aqui também).

---

## 1. Princípio central: eventos automáticos, nunca texto livre

Para reduzir ao mínimo o risco de moderação e manter a mesma disciplina já aplicada em toda a plataforma, esta primeira versão do Feed é estritamente **gerada pelo sistema** — nunca por texto digitado pelo usuário. O usuário não escreve posts; o app gera automaticamente uma entrada no feed quando um evento relevante acontece. Isso elimina praticamente todo o risco de conteúdo impróprio, discurso ofensivo ou necessidade de moderação de texto livre, que é a principal fonte de risco em recursos sociais desse tipo.

## 2. O que aparece no Feed (eventos automáticos)

Exemplos de eventos que geram uma entrada automática no Feed, visível aos amigos/comunidade do usuário (escopo de visibilidade detalhado na seção 4):
- Conclusão de um Mundo inteiro (ex.: "Fulano completou o Mundo dos Idiomas!").
- Alcance de um marco relevante de streak (ex.: 30, 60, 100 dias de sequência).
- Subida de nível significativa (ex.: a cada 10 níveis, não em todo nível para não poluir o feed).
- Vitória em Batalha contra outro jogador.
- Conquista de um badge/troféu específico.
- Recorde pessoal em Movimento (ex.: maior contagem de passos em um dia).

Nenhum desses eventos exige digitação do usuário — todos são detectados e publicados automaticamente pelo backend no momento em que a condição é satisfeita.

## 3. Interação permitida no Feed

- Mesmos ícones de incentivo já usados em Torcida (vibração, balão, coraçãozinho, joinha) — reaproveitando integralmente o que já está especificado em TORCIDA_MULTIPLA_V2.md, sem criar mecânica nova de reação.
- Nenhum campo de comentário em texto livre nesta versão piloto — reforça o princípio da seção 1.
- Toque no nome/avatar de quem gerou o evento leva ao perfil público completo, reaproveitando o fluxo já existente.

## 4. Seguir outro jogador (virar fã)

Além da relação de amizade (mútua, já existente), esta versão introduz a possibilidade de **seguir** outro jogador — uma relação de mão única, sem exigir aceite da outra parte, na mesma lógica de "seguir" já familiar em redes sociais. Quem segue um jogador se torna, na linguagem do app, um "fã" daquele jogador.

- Seguir alguém é uma ação unilateral: o usuário A pode seguir o usuário B sem que B precise aceitar ou ser notificado de forma intrusiva — diferente do pedido de amizade, que exige aceite mútuo.
- Um jogador pode ver, de forma simples, sua contagem de fãs (quantos o seguem) — dado público, no mesmo espírito de nível e XP, que já são públicos por padrão.
- Deixar de seguir também é livre e não notifica a outra parte.
- Seguir alguém não implica amizade nem abre nenhum canal adicional de contato além do que já existe hoje (Torcida, visita a perfil) — é estritamente um mecanismo de acompanhar eventos no Feed.

## 5. Escopo de visibilidade

- O Feed do usuário passa a exibir eventos de duas origens: (a) **amigos** (relação mútua já existente, mesma base usada no Ranking modo "Amigos") e (b) **jogadores que o usuário segue** (relação de mão única descrita na seção 4).
- Ainda não é um feed global de todos os usuários do app — a relevância continua vindo de uma relação estabelecida pelo próprio usuário (amizade ou "seguir"), reduzindo volume e mantendo o feed pessoal e significativo.
- Avaliação de expandir para um feed mais amplo (ex.: comunidade/global, sem exigir seguir) fica registrada como possível evolução futura, não faz parte deste piloto.

## 6. Bloqueio deve valer também no Feed e em Seguir

Reaproveitando o mesmo princípio já corrigido (ou em correção) em Perfil Público e Torcida: um usuário bloqueado por outro não deve ver os eventos desse outro usuário no Feed, e vice-versa, em nenhum dos dois sentidos do bloqueio. Isso deve usar a mesma função `is_blocked_either_way()` já validada em outros pontos do sistema.

Adicionalmente: bloquear um usuário deve automaticamente desfazer qualquer relação de "seguir" existente entre as duas partes, nos dois sentidos, e impedir que uma nova relação de "seguir" seja criada entre elas enquanto o bloqueio estiver em vigor.

## 7. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Nova tabela/estrutura de "eventos de feed", populada automaticamente pelos mesmos pontos do backend que já detectam essas condições hoje (conclusão de Mundo, marco de streak, level up, vitória em Batalha, badge, recorde de Movimento) — não é necessário criar nova lógica de detecção, apenas registrar o evento já detectado também como uma entrada de feed.
- Nova tabela/estrutura de "seguidores" (relação unilateral usuário → usuário), distinta da tabela de amizade já existente (relação mútua) — a query de listagem do Feed deve unir as duas fontes (amigos + seguidos).
- Query de listagem do Feed deve filtrar por relação de amizade e aplicar a checagem de bloqueio (seção 5) antes de retornar os eventos.
- Reaproveitar a lógica de envio/registro de Torcida já existente para a interação de reação dentro do Feed.
- Avaliar paginação/scroll para o Feed, já que o volume de eventos cresce com o tempo de uso da comunidade.

## 8. Critério de aceite do piloto

- Feed exibe automaticamente eventos gerados pelo sistema, sem exigir nenhuma digitação do usuário.
- Nenhum campo de texto livre existe nesta versão.
- Usuários conseguem reagir aos eventos do feed com os mesmos 4 ícones de Torcida já existentes.
- Feed respeita o escopo de amigos e seguidos, e a checagem de bloqueio, sem exceção.
- Usuário consegue seguir e deixar de seguir outro jogador livremente, sem necessidade de aceite, e consegue ver sua própria contagem de fãs.
- Rhoney valida o piloto com o grupo de testadores antes de decidir se o recurso expande (feed global, comentários, mais tipos de evento) ou permanece no escopo atual.

## 9. Fora de escopo neste piloto

- Comentários em texto livre.
- Feed global/público (fora do círculo de amigos).
- Compartilhamento externo do feed em redes sociais (distinto do botão de compartilhar já especificado em COMPARTILHAR_CONVIDAR_E_PUSH_TORCIDA.md, que continua funcionando à parte).

## 10. Implementação (06/09/2026) — backend

- `migrations/064_feed_social.sql` — tabelas `feed_events` (`user_id`,
  `event_type`, `payload` jsonb, `created_at`) e `follows`
  (`follower_user_id`, `followed_user_id`, únicos por par).
- `app/feed.py` (novo módulo, mesmo espírito de extração de
  `social.py`/`movement.py`): `create_feed_event`, `build_feed_event_text`,
  `follow_user`, `unfollow_user`, `is_following`, `get_fan_count`,
  `get_following_user_ids`, `list_feed` — nenhuma depende de
  `services.py`, só de `models`/`config`/`notification_copy`/`social`.
- `notification_copy.FEED_EVENT_TEMPLATES` — texto de cada evento
  montado no SERVIDOR (nunca no client, evita duplicar formatação/
  pluralização em Flutter).
- Endpoints: `GET /feed` (paginado por cursor `before`),
  `POST/DELETE /profile/{id}/follow` (mesma área de Torcida/convite de
  Movimento em `public_profile.py`). Reação a um evento do feed
  reaproveita 100% `POST /profile/{id}/torcida` já existente (§7) —
  nenhum endpoint novo de reação.
- `PublicProfileOut` ganhou `fan_count`/`is_following_by_me`.
- Eventos automáticos (§2) registrados nos MESMOS pontos que já
  detectavam cada condição (§7, nenhuma lógica de detecção nova):
  - `world_completed` — `routers/challenges.py::submit_answer`.
  - `streak_milestone` (30/60/100 dias, `config.FEED_STREAK_MILESTONES`)
    — idem, só no dia exato do marco.
  - `level_up_milestone` (a cada 10 níveis,
    `config.FEED_LEVEL_UP_MILESTONE_INTERVAL`) — idem, só ao cruzar um
    múltiplo de 10.
  - `badge_earned` — idem, um evento por badge concedido na resposta.
  - `battle_won` — `services.maybe_resolve_battle_side` (nunca em
    empate).
  - `movement_record` — `movement.collect_steps`, captura a TRANSIÇÃO
    exata de cruzar o recorde pessoal anterior (nunca repete no mesmo
    dia, nunca dispara no primeiríssimo dia de uso sem histórico).
- Bloqueio (§6): `social.block_user` agora também desfaz qualquer
  `Follow` existente nos dois sentidos; `feed.follow_user` impede nova
  relação enquanto o bloqueio existir.
- Testes: `backend/tests/test_feed_social.py` (14 testes — seguir/fã,
  bloqueio desfazendo/impedindo seguir, escopo de visibilidade do feed,
  texto montado no servidor, e cada tipo de evento automático
  disparando no momento certo e só nesse momento). Suíte backend
  completa: 357/357.

**Pendente**: telas Flutter (Feed, botão seguir/contagem de fãs no
Perfil Público) — ver próximo passo.
