-- SubMundo "Interpretação de Texto" no Mundo da Linguagem (MUNDO_LINGUAGEM_ARQUITETURA_V1.md,
-- 20/09/2026): 2º tema na ordem de produção (seção 5). 1 SubMundo (bloco lg_interpretacao_de_texto)
-- com 1 território de 50 perguntas (25 nível 1 + 15 nível 2 + 10 nível 3): 10 textos curtos
-- originais, 5 perguntas cada, com o texto dentro do próprio prompt (mesmo padrão do território
-- "textos"). Mesmo padrão da 088/089. CONTEÚDO carregado DEPOIS, via
-- scripts/append_production_content.py content/linguagem_tema_interpretacao_de_texto.json.

insert into mental.blocks (id, name, display_order) values
    ('lg_interpretacao_de_texto', 'Interpretação de Texto', 31)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('linguagem_interpretacao_de_texto', 'linguagem_tema', true, 2, 97, 'linguagem', 'lg_interpretacao_de_texto')
on conflict (id) do nothing;
