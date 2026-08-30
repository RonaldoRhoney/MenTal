-- MENTAL — V3.0.1 (Cores) e V3.1 (Mitologia/ENEM/Concursos)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 038_user_blocks.sql.
--
-- Achado real (29/08/2026): tanto V3.0.1 quanto V3.1 já tinham chegado
-- em app/seed.py (usado só por SQLite/dev, create_all()) sem a migration
-- correspondente pra produção (Postgres/Supabase) — mesmo padrão de
-- 036_v3_cultura_geral.sql, só o território/bloco/mundo é migrado aqui;
-- o conteúdo dos desafios (mental.challenges/challenge_hints) continua
-- sendo curadoria manual via backend/content/*.json +
-- scripts/append_production_content.py (backend/content/README.md,
-- RISKS_AND_OPEN_DECISIONS.md §2: nunca gerado por IA).

-- V3.0.1 (V3/V3.0.1_DESAFIO_CORES.md) — entra no Mundo da Mente Lógica
-- junto de lógica/visual/conhecimento.
insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('cores', 'cores', true, 2, 11, 'mente_logica', null)
on conflict (id) do nothing;

-- V3.1 (V3/V3.1_MITOLOGIA_ENEM_CONCURSOS.md) — bloco novo "mitologia";
-- "enem" e "concursos" já existiam vazios desde 020_blocks.sql.
insert into mental.blocks (id, name, display_order) values
    ('mitologia', 'Mitologia', 6)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('mitologia_grega', 'mitologia_grega', true, 2, 12, 'cultura_geral', 'mitologia'),
    ('mitologia_nordica', 'mitologia_nordica', true, 2, 13, 'cultura_geral', 'mitologia'),
    ('mitologia_indigena', 'mitologia_indigena', true, 2, 14, 'cultura_geral', 'mitologia'),
    ('enem_linguagens', 'enem_linguagens', true, 2, 15, 'cultura_geral', 'enem'),
    ('enem_humanas', 'enem_humanas', true, 2, 16, 'cultura_geral', 'enem'),
    ('enem_natureza', 'enem_natureza', true, 2, 17, 'cultura_geral', 'enem'),
    ('enem_matematica', 'enem_matematica', true, 2, 18, 'cultura_geral', 'enem'),
    ('concursos_portugues', 'concursos_portugues', true, 2, 19, 'cultura_geral', 'concursos'),
    ('concursos_raciocinio', 'concursos_raciocinio', true, 2, 20, 'cultura_geral', 'concursos'),
    ('concursos_direito', 'concursos_direito', true, 2, 21, 'cultura_geral', 'concursos')
on conflict (id) do nothing;
