-- FEED_SOCIAL_V1.md (06/09/2026) — Feed de conquistas (piloto) +
-- Seguir/Fã. Eventos gerados 100% pelo sistema (nunca texto livre do
-- usuário, §1) — reduz ao mínimo o risco de moderação. "Seguir" é
-- relação unilateral (§4), distinta de mental.friendships (mútua).

create table if not exists mental.feed_events (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null,
    event_type text not null,
    payload jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

create index if not exists idx_feed_events_user_created_at
    on mental.feed_events (user_id, created_at desc);

create table if not exists mental.follows (
    id uuid primary key default gen_random_uuid(),
    follower_user_id uuid not null,
    followed_user_id uuid not null,
    created_at timestamptz not null default now(),
    unique (follower_user_id, followed_user_id)
);

create index if not exists idx_follows_follower on mental.follows (follower_user_id);
create index if not exists idx_follows_followed on mental.follows (followed_user_id);
