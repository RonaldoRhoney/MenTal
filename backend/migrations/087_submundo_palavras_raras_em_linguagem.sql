-- SubMundo "Palavras Raras" no Mundo da Linguagem (pedido de Rhoney, 20/09/2026).
-- Fonte: MUNDO/Mundo_da_Linguagem/100_palavras_raras_portugues.json (100 palavras em 10 áreas).
-- Mesmo mecanismo de Bloco do SubMundo Internet (ARQUITETURA_SUBMUNDOS_V1.md): sem
-- entidade nova — um Bloco + 10 territórios (um por área, 10 desafios cada, nível 3).
--
-- O CONTEÚDO em si é carregado DEPOIS desta migração, via
-- scripts/append_production_content.py (backend/content/linguagem_palavras_raras_*.json,
-- gerados por scripts/convert_palavras_raras_content.py).

insert into mental.blocks (id, name, display_order) values
    ('palavras_raras', 'Palavras Raras', 21)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('palavras_raras_filosofia', 'palavras_raras', true, 2, 86, 'linguagem', 'palavras_raras'),
    ('palavras_raras_psicologia', 'palavras_raras', true, 2, 87, 'linguagem', 'palavras_raras'),
    ('palavras_raras_medicina', 'palavras_raras', true, 2, 88, 'linguagem', 'palavras_raras'),
    ('palavras_raras_fisica_quimica', 'palavras_raras', true, 2, 89, 'linguagem', 'palavras_raras'),
    ('palavras_raras_matematica', 'palavras_raras', true, 2, 90, 'linguagem', 'palavras_raras'),
    ('palavras_raras_linguistica', 'palavras_raras', true, 2, 91, 'linguagem', 'palavras_raras'),
    ('palavras_raras_historia', 'palavras_raras', true, 2, 92, 'linguagem', 'palavras_raras'),
    ('palavras_raras_geografia', 'palavras_raras', true, 2, 93, 'linguagem', 'palavras_raras'),
    ('palavras_raras_direito', 'palavras_raras', true, 2, 94, 'linguagem', 'palavras_raras'),
    ('palavras_raras_eruditas', 'palavras_raras', true, 2, 95, 'linguagem', 'palavras_raras')
on conflict (id) do nothing;
