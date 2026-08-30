-- MENTAL — Correção: sequência sem repetição de desafios
-- (BUG_PERGUNTAS_REPETINDO_SEQUENCIA.md)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 043_v3_4_libras.sql.

alter table mental.attempts add column if not exists was_last_of_batch boolean not null default false;

create table if not exists mental.challenge_batch_progress (
    user_id uuid not null,
    territory_id varchar not null references mental.territories(id),
    difficulty_level integer not null,
    timed boolean not null,
    remaining_challenge_ids json not null default '[]',
    updated_at timestamp not null default now(),
    primary key (user_id, territory_id, difficulty_level, timed)
);
