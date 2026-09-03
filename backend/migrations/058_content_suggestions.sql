-- MENTAL — Busca na Home + sugestão de conteúdo (pedido de Rhoney):
-- quando a busca não encontra nada, o termo pesquisado fica registrado
-- aqui pra um agente de curadoria avaliar depois (Motor B, V4/
-- MENTAL_AI_AGENT_TEAM_V1.md §5.3 — ainda não implementado; por ora só
-- fica visível no painel admin in-app, ADMIN_PAINEL_IN_APP_V1.md).
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 057_app_invite_reward.sql.

create table if not exists mental.content_suggestions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references mental.profiles(user_id) on delete set null,
  query_text text not null,
  created_at timestamptz not null default now()
);

create index if not exists content_suggestions_created_at_idx on mental.content_suggestions (created_at desc);
