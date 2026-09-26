-- Mundo dos Concursos — Municipais (1º lote, 26/09/2026): bloco + 4 territórios (Português,
-- Raciocínio Lógico e Matemática, Informática, Constituição e Administração Pública).
-- NÃO altera nem apaga os territórios atuais concursos_*. CONTEÚDO carregado DEPOIS, via
-- scripts/append_production_content.py content/concursos_municipal_<slug>.json (revisão de Rhoney).

insert into mental.blocks (id, name, display_order) values
    ('concursos_municipais', 'Concursos Municipais', 50)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('concursos_municipal_portugues', 'concursos_municipal', true, 2, 115, 'concursos', 'concursos_municipais'),
    ('concursos_municipal_raciocinio', 'concursos_municipal', true, 2, 116, 'concursos', 'concursos_municipais'),
    ('concursos_municipal_informatica', 'concursos_municipal', true, 2, 117, 'concursos', 'concursos_municipais'),
    ('concursos_municipal_constituicao', 'concursos_municipal', true, 2, 118, 'concursos', 'concursos_municipais')
on conflict (id) do nothing;
