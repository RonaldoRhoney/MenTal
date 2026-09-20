-- SubMundo "Morfologia" no Mundo da Linguagem (MUNDO_LINGUAGEM_ARQUITETURA_V1.md,
-- 20/09/2026): 1º tema na ordem de produção (seção 5). 1 SubMundo (bloco lg_morfologia)
-- com 1 território de 50 perguntas (25 nível 1 + 15 nível 2 + 10 nível 3).
-- Mesmo padrão da 088 (Crase). CONTEÚDO carregado DEPOIS, via
-- scripts/append_production_content.py content/linguagem_tema_morfologia.json
-- (gerado por scripts/convert_linguagem_tema_content.py morfologia; lote fonte em
-- MUNDO/Mundo_da_Linguagem/temas/morfologia_lote1.json, revisão de Rhoney).

insert into mental.blocks (id, name, display_order) values
    ('lg_morfologia', 'Morfologia', 30)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('linguagem_morfologia', 'linguagem_tema', true, 2, 96, 'linguagem', 'lg_morfologia')
on conflict (id) do nothing;
