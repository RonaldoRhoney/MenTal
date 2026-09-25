-- SubMundos "Numerais" e "Interjeições" no Mundo da Linguagem
-- (MUNDO_LINGUAGEM_ARQUITETURA_V1.md, 25/09/2026): 8º item da ordem de produção (seção 5).
-- 2 SubMundos (blocos lg_numerais e lg_interjeicoes), cada um com 1 território de
-- 50 perguntas (25 nível 1 + 15 nível 2 + 10 nível 3). Mesmo padrão da 088-099.
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/linguagem_tema_numerais.json e content/linguagem_tema_interjeicoes.json
-- (lotes fonte em MUNDO/Mundo_da_Linguagem/temas/, revisão de Rhoney).

insert into mental.blocks (id, name, display_order) values
    ('lg_numerais', 'Numerais', 43),
    ('lg_interjeicoes', 'Interjeições', 44)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('linguagem_numerais', 'linguagem_tema', true, 2, 109, 'linguagem', 'lg_numerais'),
    ('linguagem_interjeicoes', 'linguagem_tema', true, 2, 110, 'linguagem', 'lg_interjeicoes')
on conflict (id) do nothing;
