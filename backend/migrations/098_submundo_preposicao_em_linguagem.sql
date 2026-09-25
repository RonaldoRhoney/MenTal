-- SubMundo "Preposição" no Mundo da Linguagem (MUNDO_LINGUAGEM_ARQUITETURA_V1.md,
-- 25/09/2026): 5º item da ordem de produção (seção 5), junto da Crase (088).
-- 1 SubMundo (bloco lg_preposicao) com 1 território de 50 perguntas
-- (25 nível 1 + 15 nível 2 + 10 nível 3). Mesmo padrão da 088-097.
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/linguagem_tema_preposicao.json (lote fonte em
-- MUNDO/Mundo_da_Linguagem/temas/preposicao_lote1.json, revisão de Rhoney).

insert into mental.blocks (id, name, display_order) values
    ('lg_preposicao', 'Preposição', 37)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('linguagem_preposicao', 'linguagem_tema', true, 2, 103, 'linguagem', 'lg_preposicao')
on conflict (id) do nothing;
