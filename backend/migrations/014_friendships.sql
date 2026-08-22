-- MENTAL — V2 item 12: Amigos (V2_KICKOFF.md §6A)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 013_world_badges.sql.
--
-- N:N de verdade — deliberadamente uma tabela NOVA, não reaproveita
-- mental.invite_conversions (que tem 1 atribuição por usuário, pensado
-- pra métrica de crescimento, não pra amizade). Usa o MESMO invite_code
-- já existente como ponto de entrada — nenhuma tela nova de convite.
-- Par sempre canônico (user_id_a < user_id_b como texto), aplicado pelo
-- backend antes de gravar, não pelo banco.

create table if not exists mental.friendships (
    id uuid primary key default gen_random_uuid(),
    user_id_a uuid not null references mental.profiles(user_id),
    user_id_b uuid not null references mental.profiles(user_id),
    created_at timestamptz not null default now(),
    unique (user_id_a, user_id_b)
);

create index if not exists idx_friendships_user_a on mental.friendships(user_id_a);
create index if not exists idx_friendships_user_b on mental.friendships(user_id_b);
