# MENTAL — Painel Administrativo (ADMIN_DASHBOARD_V1)

**Status:** Aprovado para implementação.
**Referência visual:** mental-admin-panel.html (protótipo estático em HTML/CSS — reproduzir estrutura, hierarquia, cores e layout abaixo; pode ser servido como frontend estático real ou reconstruído em framework leve, ver seção 2).
**Documento relacionado:** ADMIN_PANEL_E_CREDITO_INSTITUCIONAL.md (decisão original que criou este item na Foundation — este documento substitui a Seção 1.4 daquele arquivo com o escopo detalhado, agora que a etapa foi formalmente priorizada).
**Escopo:** Painel de leitura de métricas, fora do app do jogador. Não inclui edição de dado de jogador (XP, progresso, saldo) nesta fase — apenas visualização.

---

## 1. Objetivo

Dar a Rhoney (dono/admin único nesta fase) visibilidade centralizada sobre o que está acontecendo no MENTAL — engajamento, progressão dos jogadores, saúde de conteúdo por território, atividade social — sem precisar consultar o Supabase manualmente ou abrir o app como jogador. Este painel é uma ferramenta de decisão de produto, não uma feature do jogo.

## 2. Onde vive e como se acessa

- **Não faz parte do bundle do app Flutter** — nenhuma tela, rota ou asset deste painel é compilado junto do MENTAL que os jogadores baixam.
- Implementado como **rota web separada servida pelo mesmo backend FastAPI já em produção no Render** (ex: `https://mental-api.onrender.com/admin`), reaproveitando a infraestrutura existente — sem novo serviço de hospedagem nesta fase.
- Frontend pode ser HTML/CSS/JS estático simples servido pela própria API (mais barato de manter) ou uma SPA leve, a critério do Claude Code — a complexidade da interface não justifica um framework pesado nesta fase.
- Acessado via navegador comum (desktop ou mobile), sem necessidade de instalar nada.
- **Trilha de evolução futura (fora de escopo agora):** se o produto crescer ou for necessário dar acesso a mais alguém, migrar para deploy separado (ex: Vercel, subdomínio próprio `admin.mental.app`) consumindo a mesma API via chamadas HTTP autenticadas. A lógica de negócio (queries, cálculo de métricas) não muda nessa migração — só onde o frontend é servido.

## 3. Autenticação e controle de acesso

- Login restrito a `role = admin` no Supabase (papel que já existe no schema desde a Foundation).
- Reaproveitar o mesmo mecanismo de autenticação já usado para proteger `/admin/profile-photos` — não criar um sistema de auth paralelo.
- Nenhuma rota deste painel pode ser acessível sem autenticação válida, incluindo tentativas de acesso direto por URL.
- Nesta fase, apenas uma conta admin existe (`rhoneyinc@gmail.com`) — o sistema de papéis já suporta múltiplos admins no futuro, mas não há necessidade de tela de gestão de admins agora.

## 4. Estrutura da interface

Layout desktop-first (sidebar fixa + área de conteúdo), navegação por seções. Ordem de prioridade de implementação: Dashboard (seção 5) primeiro; as demais seções da sidebar (Usuários, Progressão, Conteúdo & Territórios, Social & Batalhas, Moderação de Fotos) podem ser implementadas como visões dedicadas em etapas seguintes, reaproveitando os dados já expostos no Dashboard — não é necessário implementar tudo de uma vez.

**Sidebar:**
- Marca (logo pequeno + "MENTAL" + tag "admin").
- Navegação agrupada: Visão Geral (Dashboard, Usuários), Produto (Progressão, Conteúdo & Territórios, Social & Batalhas, Moderação de Fotos), Externo (link direto para o Google Play Console).
- Rodapé com identificação do admin logado.

**Topbar:** título da seção atual, seletor de período (ex: últimos 7 dias — deve ser alterável, não fixo), badge "AO VIVO" indicando que os KPIs principais atualizam em tempo real (ou em intervalo curto de refresh, ver seção 6).

## 5. Métricas do Dashboard (visão inicial, por camada)

### 5.1 Camada 1 — KPIs de visão geral (cards no topo)
- Usuários ativos hoje (com variação % vs. dia anterior).
- Usuários ativos na semana (com variação % vs. semana anterior).
- Novos cadastros no período selecionado (com variação absoluta).
- % de sessões com pelo menos 1 desafio completo.
- Streak médio dos usuários ativos (com variação vs. período anterior).

### 5.2 Camada 2 — Engajamento e progressão
- **Retenção D0/D1/D3/D7/D14**: % de usuários que retornam em cada marco, a partir do cadastro. Gráfico de barras.
- **Distribuição de nível dos jogadores**: % de usuários por faixa de nível (ex: 1-10, 11-25, 26-44, 45-70, 70+). Aponta se a progressão está bem calibrada ou se há acúmulo anômalo numa faixa.
- **Taxa de acerto por território** (Palavras, Lógica, Números, Enigmas, Visual, e demais conforme forem lançados pela V3): % de respostas corretas por categoria. Serve para identificar territórios com dificuldade mal calibrada (muito fácil ou muito difícil).
- **Distribuição do Feedback Pós-Nível**: % de respostas Fácil/Médio/Difícil/Muito Difícil no período — dado já coletado (FEEDBACK_POS_NIVEL.md) mas hoje sem lugar de leitura agregada.

### 5.3 Quem mais progrediu (tabela)
Ranking dos top usuários por XP ganho no período selecionado, com colunas: posição, usuário (avatar + nome), nível atual, XP ganho no período, streak atual, território onde tem melhor desempenho (maior taxa de acerto). Serve tanto para entender quem são os power users quanto para eventualmente contatá-los para feedback qualitativo.

### 5.4 Camada 3 — Social e aquisição
- Batalhas assíncronas ativas no momento + % concluídas em até 24h.
- Convites de amigos enviados no período + taxa de conversão em amizade efetiva.
- **Card de aquisição/downloads**: não replicar esse dado no painel — ele já vive no Google Play Console (Pre-launch Report, contagem de instalações, engajamento de testers). O painel deve conter apenas um card com explicação curta e um link direto para o Play Console, evitando duas fontes de verdade sobre a mesma métrica.

## 6. Fonte de dados e frequência de atualização

- Todo dado consumido já existe nas tabelas atuais (`attempts`, `profiles`, `subscriptions`, `daily_challenge_usage`, `friendships`, dados de batalha assíncrona, feedback pós-nível) — este painel é uma **camada de leitura**, não requer captura de dado nova.
- Endpoints novos em `/admin/metrics/*` (ou equivalente) para agregações que hoje não existem prontas (ex: retenção D0-D14, distribuição de nível, taxa de acerto por território) — Claude Code deve avaliar se essas agregações rodam em tempo real na query ou se compensa um job agendado que popula uma tabela de métricas pré-calculada, caso o volume cresça e queries diretas fiquem lentas. Nesta fase (poucas centenas de usuários), query direta deve ser suficiente.
- "AO VIVO" na topbar pode ser refresh automático a cada X minutos (ex: 5 min) em vez de websocket real — não há necessidade de infraestrutura de tempo real de fato nesta fase, apenas a percepção de atualidade.

## 7. Regras de segurança (mantidas da decisão original)

- **Somente leitura nesta fase** — nenhuma ação de escrita/edição direta de dado de jogador (XP, progresso, saldo de MentalCoins, etc.) a partir do painel. Qualquer necessidade futura de edição manual requer um ADR próprio antes de implementar, dado o risco de superfície de manipulação de dados de jogo.
- Exceção já existente e mantida: `/admin/profile-photos` (aprovação/rejeição de fotos) já é uma ação de escrita aprovada anteriormente — pode ser integrada como uma seção deste mesmo painel (item "Moderação de Fotos" na sidebar) sem contradizer a regra acima, já que é uma decisão já formalizada em USER_PROFILE.md, não uma nova superfície.

## 8. O que NÃO faz parte desta entrega

- Edição de dados de jogador.
- Gestão de múltiplos admins/papéis (sistema já suporta, mas sem tela dedicada agora).
- Métricas de aquisição/download (ficam no Google Play Console, apenas linkado).
- Exportação de relatórios (CSV/PDF) — pode ser avaliado em etapa futura se necessário.
- Alertas automáticos/notificações proativas a partir do painel (isso é escopo da automação via n8n discutida separadamente, não deste painel em si).

## 9. Critério de aceite

- Painel acessível apenas via login com `role = admin`, sem exposição de rota para usuário comum.
- Todas as métricas da seção 5 visíveis e corretas em relação ao dado real do Supabase.
- Seletor de período funcional (mínimo: últimos 7 dias, últimos 30 dias).
- Nenhuma ação de escrita disponível na interface, exceto a moderação de fotos já previamente aprovada.
- Card de aquisição linkando corretamente para o Google Play Console, sem duplicar métricas de download no painel.
- Performance aceitável mesmo com crescimento de usuários — queries de agregação não podem degradar a API de produção usada pelos jogadores (separar carga se necessário).
