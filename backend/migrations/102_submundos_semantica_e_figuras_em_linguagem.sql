-- SubMundos Semântica, Figuras de Linguagem no Mundo da Linguagem
-- (MUNDO_LINGUAGEM_ARQUITETURA_V1.md, 25/09/2026): 10º item da ordem de produção (seção 5).
-- Cada SubMundo (bloco lg_<slug>) tem 1 território de 50 perguntas (25 nível 1 + 15 nível 2 + 10 nível 3).
-- Mesmo padrão da 088-100. CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/linguagem_tema_<slug>.json (lotes em MUNDO/Mundo_da_Linguagem/temas/, revisão de Rhoney).

insert into mental.blocks (id, name, display_order) values
    ('lg_semantica', 'Semântica', 47),
    ('lg_figuras_de_linguagem', 'Figuras de Linguagem', 48)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('linguagem_semantica', 'linguagem_tema', true, 2, 113, 'linguagem', 'lg_semantica'),
    ('linguagem_figuras_de_linguagem', 'linguagem_tema', true, 2, 114, 'linguagem', 'lg_figuras_de_linguagem')
on conflict (id) do nothing;
