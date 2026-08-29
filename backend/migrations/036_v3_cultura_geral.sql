-- MENTAL — V3.0: Mundo da Cultura Geral (V3/V3.0_ESPORTES_REGIOES_CULTURA_POP.md)
-- Rodar no SQL Editor do projeto Supabase. Mesmo padrão de
-- 007_visual_territory.sql: só o mundo/território é migrado via SQL,
-- o conteúdo dos desafios (mental.challenges/challenge_hints) é
-- inserido depois por backend/scripts/seed_v3_cultura_geral_challenges.py
-- (mesmo motivo do README de scripts/: conteúdo curado nunca é gerado
-- automaticamente em produção).
--
-- O bloco "regioes" já existe em produção (inserido vazio antes da
-- V3.0, ver test_blocks.py) — este arquivo não recria ele.

insert into mental.worlds (id, name, display_order) values
    ('cultura_geral', 'Mundo da Cultura Geral', 3)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('esportes', 'esportes', true, 2, 8, 'cultura_geral', null),
    ('regioes', 'regioes', true, 2, 9, 'cultura_geral', 'regioes'),
    ('cultura_pop', 'cultura_pop', true, 2, 10, 'cultura_geral', null)
on conflict (id) do nothing;
