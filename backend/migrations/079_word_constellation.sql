-- MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md (19/09/2026) — etapa
-- complementar automática ao final de todo Desafio do Mundo dos
-- Idiomas. Mesmo padrão anti-farm de learning_pause_serves (061): XP
-- (config.WORD_CONSTELLATION_XP_REWARD) só na primeira conclusão
-- correta por (usuário, desafio).

create table if not exists mental.word_constellation_completions (
    user_id uuid not null,
    challenge_id uuid not null references mental.challenges(id),
    completed_at timestamptz not null default now(),
    primary key (user_id, challenge_id)
);
