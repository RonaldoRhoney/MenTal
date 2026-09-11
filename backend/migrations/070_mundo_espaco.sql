-- Mundo_Acima_de_Nos/README.md (07/09/2026) — "Mundo Acima de Nós
-- (Espaço)" é o nome OFICIAL exibido; mesma arquitetura de Valores/
-- Trânsito/Gastronomia/Oceanos: "cápsula de texto + perguntas"
-- (reading_passage já existe, sem ALTER necessário). 5 territórios:
-- Universo, Planetas, Estrelas, Exploração, Brasil no Espaço.

insert into mental.worlds (id, name, display_order) values
    ('espaco', 'Mundo Acima de Nós (Espaço)', 16)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id) values
    ('espaco_universo', 'espaco', true, 2, 68, 'espaco'),
    ('espaco_planetas', 'espaco', true, 2, 69, 'espaco'),
    ('espaco_estrelas', 'espaco', true, 2, 70, 'espaco'),
    ('espaco_exploracao', 'espaco', true, 2, 71, 'espaco'),
    ('espaco_brasil', 'espaco', true, 2, 72, 'espaco')
on conflict (id) do nothing;

-- Conteúdo em si (119 perguntas — 1 duplicata entre blocos fonte foi
-- excluída na conversão) é carregado DEPOIS desta migração, via
-- scripts/append_production_content.py (mesmo padrão de idiomas/
-- valores/trânsito/gastronomia/oceanos), a partir de
-- backend/content/espaco_*.json.
