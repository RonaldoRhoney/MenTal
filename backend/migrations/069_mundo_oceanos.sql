-- Mundo_dos_Oceanos/README.md (07/09/2026) — mesma arquitetura de
-- Valores/Trânsito/Gastronomia: "cápsula de texto + perguntas"
-- (reading_passage já existe, sem ALTER necessário). 5 territórios, do
-- todo pro específico: Mundo, Vida Marinha, Profundezas, Clima, Brasil.

insert into mental.worlds (id, name, display_order) values
    ('oceanos', 'Mundo dos Oceanos', 15)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id) values
    ('oceano_mundo', 'oceanos', true, 2, 63, 'oceanos'),
    ('oceano_vida_marinha', 'oceanos', true, 2, 64, 'oceanos'),
    ('oceano_profundezas', 'oceanos', true, 2, 65, 'oceanos'),
    ('oceano_clima', 'oceanos', true, 2, 66, 'oceanos'),
    ('oceano_brasil', 'oceanos', true, 2, 67, 'oceanos')
on conflict (id) do nothing;

-- Conteúdo em si (120 perguntas) é carregado DEPOIS desta migração,
-- via scripts/append_production_content.py (mesmo padrão de idiomas/
-- valores/trânsito/gastronomia), a partir de backend/content/oceanos_*.json.
