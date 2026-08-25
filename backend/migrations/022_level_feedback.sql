-- MENTAL — FEEDBACK_POS_NIVEL.md (aprovado, 25/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 021_majority_confirmation.sql.
--
-- Coleta pura de opinião pós-nível (ação escolhida + avaliação de
-- dificuldade + comentário livre opcional), associada a usuário,
-- território e desafio ("nível"). Nunca lida por hint_penalty_factor
-- nem qualquer mecânica adaptativa — só um endpoint admin read-only
-- (role=admin) consulta esta tabela.

create table if not exists mental.level_feedback (
    id uuid primary key,
    user_id uuid not null,
    territory_id text not null references mental.territories(id),
    challenge_id uuid not null references mental.challenges(id),
    action text not null,
    difficulty_rating text not null,
    comment text,
    created_at timestamptz not null default now()
);

create index if not exists level_feedback_user_id_idx on mental.level_feedback(user_id);
create index if not exists level_feedback_territory_id_idx on mental.level_feedback(territory_id);
