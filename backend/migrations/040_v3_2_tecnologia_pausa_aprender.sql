-- MENTAL — V3.2: Tecnologia em Profundidade (V3/V3.2_TECNOLOGIA.md)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de
-- 039_v3_0_1_e_v3_1_territorios.sql.
--
-- Território/bloco (mesmo padrão de 036_v3_cultura_geral.sql e
-- 039_v3_0_1_e_v3_1_territorios.sql) + as duas tabelas novas da
-- mecânica "Pausa para Aprender" (§3 do documento — estrutura de
-- conteúdo NOVA, sem options/correct_answer/timer, por isso não cabe
-- em mental.challenges). Conteúdo (Relâmpago e Pausa para Aprender) é
-- curadoria manual via backend/content/*.json — nunca inserido aqui.

insert into mental.blocks (id, name, display_order) values
    ('tecnologia', 'Tecnologia', 7)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('tecnologia_fundamentos', 'tecnologia_fundamentos', true, 2, 22, 'cultura_geral', 'tecnologia'),
    ('tecnologia_programacao', 'tecnologia_programacao', true, 2, 23, 'cultura_geral', 'tecnologia'),
    ('tecnologia_seguranca', 'tecnologia_seguranca', true, 2, 24, 'cultura_geral', 'tecnologia'),
    ('tecnologia_fronteira', 'tecnologia_fronteira', true, 2, 25, 'cultura_geral', 'tecnologia')
on conflict (id) do nothing;

create table if not exists mental.learning_pauses (
    id uuid primary key default gen_random_uuid(),
    territory_id text not null references mental.territories(id),
    difficulty_level integer not null default 1,
    text text not null,
    prompt_image text,
    age_reviewed boolean not null default false,
    language_code text not null default 'pt-BR'
);

create index if not exists idx_learning_pauses_territory on mental.learning_pauses (territory_id, language_code);

create table if not exists mental.learning_pause_reads (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    learning_pause_id uuid not null references mental.learning_pauses(id) on delete cascade,
    read_at timestamptz not null default now(),
    unique (user_id, learning_pause_id)
);
