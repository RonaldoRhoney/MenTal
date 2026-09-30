-- Mundo dos Idiomas — Palavras Compostas (Compound Words) e Contrações Informais
-- de Inglês (MUNDO_IDIOMAS_INGLES_PALAVRAS_COMPOSTAS_E_CONTRACOES_V1.md, já aprovado,
-- 29/09/2026). Mesmo padrão de Phrasal Verbs/Expressões/Conjugação Verbal (migrations
-- 107-108, 110-111): block_id "ingles" direto (não é idioma novo), nunca um bloco
-- próprio. Território normal + Relâmpago (sempre cronometrado, conteúdo distinto) por
-- nível e por mecânica. Espanhol/Francês fora desta entrega (mesmo escopo já usado nas
-- demais frentes — Rhoney concentra o esforço no Inglês primeiro).
--
-- display_order 67-78 (contíguo, logo depois de Conjugação Verbal em 55-60, ANTES de
-- Espanhol/Francês) — Espanhol/Francês são empurrados de 61-66 pra 79-84, mesmo motivo
-- das migrations 109/110/111 (evitar o bloco "ingles" aparecer partido em dois lugares
-- da tela).
--
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/idiomas_ingles_compostas_<nivel>[_relampago].json e
-- content/idiomas_ingles_contracoes_<nivel>[_relampago].json (revisão de Rhoney, em lotes).

update mental.territories set display_order = 79 where id = 'espanhol_basico';
update mental.territories set display_order = 80 where id = 'espanhol_intermediario';
update mental.territories set display_order = 81 where id = 'espanhol_avancado';
update mental.territories set display_order = 82 where id = 'frances_basico';
update mental.territories set display_order = 83 where id = 'frances_intermediario';
update mental.territories set display_order = 84 where id = 'frances_avancado';

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('ingles_compostas_basico', 'idiomas', true, 3, 67, 'idiomas', 'ingles'),
    ('ingles_compostas_intermediario', 'idiomas', true, 3, 68, 'idiomas', 'ingles'),
    ('ingles_compostas_avancado', 'idiomas', true, 3, 69, 'idiomas', 'ingles'),
    ('ingles_compostas_relampago_basico', 'idiomas', true, 3, 70, 'idiomas', 'ingles'),
    ('ingles_compostas_relampago_intermediario', 'idiomas', true, 3, 71, 'idiomas', 'ingles'),
    ('ingles_compostas_relampago_avancado', 'idiomas', true, 3, 72, 'idiomas', 'ingles'),
    ('ingles_contracoes_basico', 'idiomas', true, 3, 73, 'idiomas', 'ingles'),
    ('ingles_contracoes_intermediario', 'idiomas', true, 3, 74, 'idiomas', 'ingles'),
    ('ingles_contracoes_avancado', 'idiomas', true, 3, 75, 'idiomas', 'ingles'),
    ('ingles_contracoes_relampago_basico', 'idiomas', true, 3, 76, 'idiomas', 'ingles'),
    ('ingles_contracoes_relampago_intermediario', 'idiomas', true, 3, 77, 'idiomas', 'ingles'),
    ('ingles_contracoes_relampago_avancado', 'idiomas', true, 3, 78, 'idiomas', 'ingles')
on conflict (id) do nothing;
