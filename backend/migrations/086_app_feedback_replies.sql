-- Mural de Feedback aberto (decisão de Rhoney, 20/09/2026): TODOS os usuários
-- podem responder a um comentário, não só o admin. A "Resposta da equipe"
-- (app_feedback.admin_reply) continua como resposta oficial destacada.

create table if not exists mental.app_feedback_replies (
    id uuid primary key default gen_random_uuid(),
    feedback_id uuid not null references mental.app_feedback(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    comment text not null,
    created_at timestamp not null default now()
);

create index if not exists idx_app_feedback_replies_feedback on mental.app_feedback_replies (feedback_id, created_at);
create index if not exists idx_app_feedback_replies_user on mental.app_feedback_replies (user_id, created_at);
