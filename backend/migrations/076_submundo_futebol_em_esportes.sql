-- MUNDO_ESPORTES_ARQUITETURA_V1.md — SubMundo "Futebol" dentro de
-- Mundo dos Esportes, mesmo mecanismo de Bloco já usado em Copa do
-- Mundo (migrations/074) e Internet (migrations/072). Curadoria
-- completa em 14/09/2026 (20/20 desafios, 4 blocos). difficulty_level
-- sempre 1 (sem trilha de dificuldade neste Mundo).

insert into mental.blocks (id, name, display_order) values
    ('futebol', 'Futebol', 17)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('futebol_origens', 'futebol', true, 2, 82, 'esportes', 'futebol'),
    ('futebol_grandes_nomes', 'futebol', true, 2, 83, 'esportes', 'futebol'),
    ('futebol_regras_curiosidades', 'futebol', true, 2, 84, 'esportes', 'futebol'),
    ('futebol_atualidade', 'futebol', true, 2, 85, 'esportes', 'futebol')
on conflict (id) do nothing;

-- Conteúdo em si é carregado DEPOIS desta migração, via
-- scripts/append_production_content.py, a partir de
-- backend/content/futebol_*.json (gerados por
-- scripts/convert_esportes_content.py). 100 desafios em 4 territórios,
-- 0 excluídos.
