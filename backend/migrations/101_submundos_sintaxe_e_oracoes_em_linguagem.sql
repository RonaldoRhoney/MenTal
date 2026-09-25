-- SubMundos Sintaxe, Orações Coordenadas e Subordinadas no Mundo da Linguagem
-- (MUNDO_LINGUAGEM_ARQUITETURA_V1.md, 25/09/2026): 9º item da ordem de produção (seção 5).
-- Cada SubMundo (bloco lg_<slug>) tem 1 território de 50 perguntas (25 nível 1 + 15 nível 2 + 10 nível 3).
-- Mesmo padrão da 088-100. CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/linguagem_tema_<slug>.json (lotes em MUNDO/Mundo_da_Linguagem/temas/, revisão de Rhoney).

insert into mental.blocks (id, name, display_order) values
    ('lg_sintaxe', 'Sintaxe', 45),
    ('lg_oracoes_coordenadas_e_subordinadas', 'Orações Coordenadas e Subordinadas', 46)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('linguagem_sintaxe', 'linguagem_tema', true, 2, 111, 'linguagem', 'lg_sintaxe'),
    ('linguagem_oracoes_coordenadas_e_subordinadas', 'linguagem_tema', true, 2, 112, 'linguagem', 'lg_oracoes_coordenadas_e_subordinadas')
on conflict (id) do nothing;
