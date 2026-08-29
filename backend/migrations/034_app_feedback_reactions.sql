-- MENTAL — Mural público de feedback com reações (pedido de Rhoney, 29/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 033_app_feedback_reply.sql.
--
-- Feedback deixa de ser privado (só autor + admin) e vira um mural
-- visível a todos os usuários, com reações de curtir/amei — "isso
-- ajudará mais usuários fazerem comentários sobre o app".
create table if not exists mental.app_feedback_reactions (
    id uuid primary key default gen_random_uuid(),
    feedback_id uuid not null references mental.app_feedback(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    reaction_type text not null, -- like | love
    created_at timestamptz not null default now(),
    unique (feedback_id, user_id, reaction_type)
);

create index if not exists idx_app_feedback_reactions_feedback on mental.app_feedback_reactions (feedback_id);
