-- SubMundos "Colocação Pronominal" e "Pronomes" no Mundo da Linguagem
-- (MUNDO_LINGUAGEM_ARQUITETURA_V1.md, 25/09/2026): 6º item da ordem de produção
-- (seção 5). 2 SubMundos (blocos lg_colocacao_pronominal e lg_pronomes), cada um com
-- 1 território de 50 perguntas (25 nível 1 + 15 nível 2 + 10 nível 3). Mesmo padrão da 088-094.
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/linguagem_tema_colocacao_pronominal.json e content/linguagem_tema_pronomes.json
-- (lotes fonte em MUNDO/Mundo_da_Linguagem/temas/, revisão de Rhoney).

insert into mental.blocks (id, name, display_order) values
    ('lg_colocacao_pronominal', 'Colocação Pronominal', 38),
    ('lg_pronomes', 'Pronomes', 39)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('linguagem_colocacao_pronominal', 'linguagem_tema', true, 2, 104, 'linguagem', 'lg_colocacao_pronominal'),
    ('linguagem_pronomes', 'linguagem_tema', true, 2, 105, 'linguagem', 'lg_pronomes')
on conflict (id) do nothing;
