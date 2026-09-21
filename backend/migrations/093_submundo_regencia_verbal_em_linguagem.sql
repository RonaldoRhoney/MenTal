-- SubMundo "Regência Verbal" no Mundo da Linguagem (MUNDO_LINGUAGEM_ARQUITETURA_V1.md,
-- 20/09/2026): 4º item da ordem de produção (seção 5). 1 SubMundo (bloco lg_regencia_verbal)
-- com 1 território de 50 perguntas (25 nível 1 + 15 nível 2 + 10 nível 3). Mesmo padrão da 088-092.
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/linguagem_tema_regencia_verbal.json (lote fonte em
-- MUNDO/Mundo_da_Linguagem/temas/regencia_verbal_lote1.json, revisão de Rhoney).

insert into mental.blocks (id, name, display_order) values
    ('lg_regencia_verbal', 'Regência Verbal', 34)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('linguagem_regencia_verbal', 'linguagem_tema', true, 2, 100, 'linguagem', 'lg_regencia_verbal')
on conflict (id) do nothing;
