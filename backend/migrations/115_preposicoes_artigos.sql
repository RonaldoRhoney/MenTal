-- Mundo dos Idiomas — Preposições e Artigos de Inglês
-- (MUNDO_IDIOMAS_INGLES_PREPOSICOES_ARTIGOS_V1.md, já aprovado, 30/09/2026). Mesmo padrão
-- de Phrasal Verbs/Expressões/Conjugação/Compostas/Contrações/Falsos Cognatos: block_id
-- "ingles" direto (não é idioma novo), nunca um bloco próprio. Território normal +
-- Relâmpago (sempre cronometrado, conteúdo distinto) por nível — formato normal de "frase
-- + pergunta" (não é cápsula de texto).
--
-- display_order 103-108 (contíguo, logo depois de Falsos Cognatos em 91-96, ANTES de
-- Espanhol/Francês) — Espanhol/Francês são empurrados de 97-102 pra 109-114, mesmo motivo
-- das migrations 109/110/111/112/113/114 (evitar o bloco "ingles" aparecer partido em
-- dois lugares da tela).
--
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/idiomas_ingles_preposicoes_<nivel>[_relampago].json (revisão de Rhoney, em
-- lotes).

update mental.territories set display_order = 109 where id = 'espanhol_basico';
update mental.territories set display_order = 110 where id = 'espanhol_intermediario';
update mental.territories set display_order = 111 where id = 'espanhol_avancado';
update mental.territories set display_order = 112 where id = 'frances_basico';
update mental.territories set display_order = 113 where id = 'frances_intermediario';
update mental.territories set display_order = 114 where id = 'frances_avancado';

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('ingles_preposicoes_basico', 'idiomas', true, 3, 103, 'idiomas', 'ingles'),
    ('ingles_preposicoes_intermediario', 'idiomas', true, 3, 104, 'idiomas', 'ingles'),
    ('ingles_preposicoes_avancado', 'idiomas', true, 3, 105, 'idiomas', 'ingles'),
    ('ingles_preposicoes_relampago_basico', 'idiomas', true, 3, 106, 'idiomas', 'ingles'),
    ('ingles_preposicoes_relampago_intermediario', 'idiomas', true, 3, 107, 'idiomas', 'ingles'),
    ('ingles_preposicoes_relampago_avancado', 'idiomas', true, 3, 108, 'idiomas', 'ingles')
on conflict (id) do nothing;
