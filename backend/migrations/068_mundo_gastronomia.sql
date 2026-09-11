-- Mundo_da_Gastronomia/README.md (07/09/2026) — mesma arquitetura de
-- Valores/Trânsito: "cápsula de texto + perguntas" (reading_passage já
-- existe, sem ALTER necessário). 5 territórios, do todo pro específico:
-- Mundo, Brasil, Norte+Nordeste, Centro-Oeste+Sudeste, Sul+fusão regional.

insert into mental.worlds (id, name, display_order) values
    ('gastronomia', 'Mundo da Gastronomia', 14)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id) values
    ('gastro_mundo', 'gastronomia', true, 2, 58, 'gastronomia'),
    ('gastro_brasil', 'gastronomia', true, 2, 59, 'gastronomia'),
    ('gastro_norte_nordeste', 'gastronomia', true, 2, 60, 'gastronomia'),
    ('gastro_centrooeste_sudeste', 'gastronomia', true, 2, 61, 'gastronomia'),
    ('gastro_sul_fusao', 'gastronomia', true, 2, 62, 'gastronomia')
on conflict (id) do nothing;

-- Conteúdo em si (120 perguntas) é carregado DEPOIS desta migração,
-- via scripts/append_production_content.py (mesmo padrão de idiomas/
-- valores/trânsito), a partir de backend/content/gastronomia_*.json.
