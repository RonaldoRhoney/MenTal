-- MENTAL — V2 item 14: Batalha assíncrona (ASYNC_BATTLE.md)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 016_share_reward.sql.

create table if not exists mental.battles (
    id uuid primary key,
    challenger_user_id uuid not null,
    opponent_user_id uuid not null,
    territory_id text not null references mental.territories(id),
    difficulty_level integer not null,
    challenger_challenge_id uuid not null references mental.challenges(id),
    opponent_challenge_id uuid not null references mental.challenges(id),
    status text not null default 'pending',
    challenger_served_at timestamp not null,
    opponent_served_at timestamp,
    challenger_is_correct boolean,
    opponent_is_correct boolean,
    challenger_response_ms integer,
    opponent_response_ms integer,
    winner_user_id uuid,
    created_at timestamp not null,
    resolved_at timestamp
);

create index if not exists ix_battles_challenger_user_id on mental.battles (challenger_user_id);
create index if not exists ix_battles_opponent_user_id on mental.battles (opponent_user_id);
