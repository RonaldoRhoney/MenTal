-- SubMundos "Pontuação", "Ortografia" e "Acentuação Gráfica" no Mundo da Linguagem
-- (MUNDO_LINGUAGEM_ARQUITETURA_V1.md, 25/09/2026): 7º item da ordem de produção (seção 5).
-- 3 SubMundos (blocos lg_pontuacao, lg_ortografia, lg_acentuacao_grafica), cada um com
-- 1 território de 50 perguntas (25 nível 1 + 15 nível 2 + 10 nível 3). Mesmo padrão da 088-098.
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/linguagem_tema_<slug>.json (lotes fonte em MUNDO/Mundo_da_Linguagem/temas/, revisão de Rhoney).

insert into mental.blocks (id, name, display_order) values
    ('lg_pontuacao', 'Pontuação', 40),
    ('lg_ortografia', 'Ortografia', 41),
    ('lg_acentuacao_grafica', 'Acentuação Gráfica', 42)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('linguagem_pontuacao', 'linguagem_tema', true, 2, 106, 'linguagem', 'lg_pontuacao'),
    ('linguagem_ortografia', 'linguagem_tema', true, 2, 107, 'linguagem', 'lg_ortografia'),
    ('linguagem_acentuacao_grafica', 'linguagem_tema', true, 2, 108, 'linguagem', 'lg_acentuacao_grafica')
on conflict (id) do nothing;
