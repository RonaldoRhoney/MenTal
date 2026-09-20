-- SubMundo "Crase" no Mundo da Linguagem (MUNDO_LINGUAGEM_ARQUITETURA_V1.md,
-- pedido de Rhoney, 20/09/2026): 1º dos 19 temas de gramática (plano em
-- backend/content/plano_temas_linguagem.json). 1 SubMundo (bloco lg_crase) com 1
-- território de 50 perguntas (25 nível 1 + 15 nível 2 + 10 nível 3).
-- Mesmo mecanismo de Bloco do SubMundo Internet — sem entidade nova.
--
-- CONTEÚDO carregado DEPOIS desta migração, via
-- scripts/append_production_content.py content/linguagem_tema_crase.json
-- (gerado por scripts/convert_linguagem_tema_content.py crase). Só depois da
-- revisão de Rhoney do lote (MUNDO/Mundo_da_Linguagem/temas/crase_lote1.json).

insert into mental.blocks (id, name, display_order) values
    ('lg_crase', 'Crase', 36)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('linguagem_crase', 'linguagem_tema', true, 2, 102, 'linguagem', 'lg_crase')
on conflict (id) do nothing;
