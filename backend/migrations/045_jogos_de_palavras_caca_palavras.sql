-- MENTAL — V3.3 §6: Jogos de Palavras, Fase 1 (Caça-palavras)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de
-- 044_sequencia_sem_repeticao.sql.

insert into mental.blocks (id, name, display_order) values
    ('jogos_de_palavras', 'Jogos de Palavras', 14)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('caca_palavras', 'caca_palavras', true, 1, 32, 'cultura_geral', 'jogos_de_palavras')
on conflict (id) do nothing;

create table if not exists mental.word_puzzles (
    id uuid primary key,
    territory_id varchar not null references mental.territories(id),
    difficulty_level integer not null default 1,
    theme varchar not null,
    grid_size integer not null,
    grid json not null,
    words json not null,
    age_reviewed boolean not null default false,
    language_code varchar not null default 'pt-BR'
);

create table if not exists mental.word_puzzle_results (
    id uuid primary key,
    user_id uuid not null,
    word_puzzle_id uuid not null references mental.word_puzzles(id),
    started_at timestamp not null,
    completed_at timestamp,
    elapsed_ms integer,
    xp_awarded integer
);

create index if not exists ix_word_puzzle_results_user_id on mental.word_puzzle_results (user_id);
