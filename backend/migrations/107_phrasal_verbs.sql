-- Mundo dos Idiomas — Phrasal Verbs de Inglês (MUNDO_IDIOMAS_INGLES_PHRASAL_VERBS_V1.md,
-- aprovado por Rhoney, 27/09/2026). Bloco próprio "Phrasal Verbs" (não mistura no bloco
-- "Inglês", que o teste de organização visual espera com exatamente 3 territórios —
-- ORGANIZACAO_VISUAL_POR_SECAO_TODOS_MUNDOS_V1.md). 3 níveis x (território normal +
-- território Relâmpago, sempre cronometrado, conteúdo distinto) = 6 territórios novos.
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/ingles_phrasal_<nivel>[_relampago].json (revisão de Rhoney, em lotes).

insert into mental.blocks (id, name, display_order) values
    ('phrasal_verbs', 'Phrasal Verbs', 22)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('ingles_phrasal_basico', 'idiomas', true, 3, 119, 'idiomas', 'phrasal_verbs'),
    ('ingles_phrasal_intermediario', 'idiomas', true, 3, 120, 'idiomas', 'phrasal_verbs'),
    ('ingles_phrasal_avancado', 'idiomas', true, 3, 121, 'idiomas', 'phrasal_verbs'),
    ('ingles_phrasal_relampago_basico', 'idiomas', true, 3, 122, 'idiomas', 'phrasal_verbs'),
    ('ingles_phrasal_relampago_intermediario', 'idiomas', true, 3, 123, 'idiomas', 'phrasal_verbs'),
    ('ingles_phrasal_relampago_avancado', 'idiomas', true, 3, 124, 'idiomas', 'phrasal_verbs')
on conflict (id) do nothing;
