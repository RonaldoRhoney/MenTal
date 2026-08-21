-- MENTAL — V2 item 1: Badges/Conquistas (V2_KICKOFF.md §6A)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 003_i18n_language_code.sql.

create table if not exists mental.badges (
    id uuid primary key default gen_random_uuid(),
    code text not null unique,
    name text not null,
    description text not null,
    criteria_type text not null,
    criteria_value integer not null default 0,
    display_order integer not null default 0
);

create table if not exists mental.user_badges (
    user_id uuid not null references auth.users(id) on delete cascade,
    badge_id uuid not null references mental.badges(id),
    earned_at timestamptz not null default now(),
    primary key (user_id, badge_id)
);

create index if not exists idx_user_badges_user on mental.user_badges (user_id);

-- Catálogo inicial (5 badges) — mesmo conteúdo do seed de desenvolvimento
-- (backend/app/seed.py, BADGES). Curadoria manual, sem geração automática
-- por IA (RISKS_AND_OPEN_DECISIONS.md §2 / V2_KICKOFF.md §3.5).
insert into mental.badges (code, name, description, criteria_type, criteria_value, display_order) values
    ('first_conquest', 'Primeira Conquista', 'Conquiste seu primeiro território.', 'territory_conquered_count', 1, 1),
    ('collector', 'Colecionador', 'Conquiste todos os territórios disponíveis.', 'all_territories_conquered', 0, 2),
    ('iron_streak', 'Sequência de Ferro', 'Mantenha uma sequência de 7 dias seguidos.', 'streak_days', 7, 3),
    ('sharp_mind', 'Mente Afiada', 'Responda corretamente 50 desafios no total.', 'total_correct_answers', 50, 4),
    ('no_help_needed', 'Sem Ajuda', 'Responda corretamente 10 desafios sem usar nenhuma dica.', 'hint_free_correct_answers', 10, 5)
on conflict (code) do nothing;
