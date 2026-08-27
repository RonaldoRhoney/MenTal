-- MENTAL — Menu de feedback geral (26/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 024_mandatory_onboarding.sql.
--
-- Canal de comentário livre sobre o app, diferente de level_feedback
-- (associado a um nível/desafio específico) — acessível a qualquer
-- momento pelo usuário, sem estar amarrado a completar um nível.

create table if not exists mental.app_feedback (
    id uuid primary key,
    user_id uuid not null,
    comment text not null,
    created_at timestamptz not null default now()
);

create index if not exists app_feedback_user_id_idx on mental.app_feedback(user_id);
