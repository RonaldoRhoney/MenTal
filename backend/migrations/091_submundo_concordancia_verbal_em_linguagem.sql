-- SubMundo "Concordância Verbal" no Mundo da Linguagem (MUNDO_LINGUAGEM_ARQUITETURA_V1.md,
-- 20/09/2026): 3º tema na ordem de produção (seção 5). 1 SubMundo (bloco lg_concordancia_verbal)
-- com 1 território de 50 perguntas (25 nível 1 + 15 nível 2 + 10 nível 3). Mesmo padrão da 088-090.
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/linguagem_tema_concordancia_verbal.json (lote fonte em
-- MUNDO/Mundo_da_Linguagem/temas/concordancia_verbal_lote1.json, revisão de Rhoney).

insert into mental.blocks (id, name, display_order) values
    ('lg_concordancia_verbal', 'Concordância Verbal', 32)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('linguagem_concordancia_verbal', 'linguagem_tema', true, 2, 98, 'linguagem', 'lg_concordancia_verbal')
on conflict (id) do nothing;
