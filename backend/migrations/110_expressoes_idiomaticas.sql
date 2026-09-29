-- Mundo dos Idiomas — Expressões Idiomáticas de Inglês
-- (MUNDO_IDIOMAS_INGLES_EXPRESSOES_IDIOMATICAS_V1.md, já aprovado, 28/09/2026).
-- Mesmo padrão do Phrasal Verbs (migrations 107-108): block_id "ingles" direto
-- (Expressões Idiomáticas é conteúdo do idioma Inglês, não um idioma novo),
-- nunca um bloco próprio. Território normal + Relâmpago (sempre cronometrado,
-- conteúdo distinto) por nível.
--
-- display_order 49-54 (contíguo, logo depois de Phrasal Verbs em 43-48, ANTES
-- de Espanhol/Francês) — Espanhol/Francês são empurrados de 49-54 pra 55-60
-- pra abrir espaço, mesmo motivo da migration 109 (evitar o bloco "ingles"
-- aparecer partido em dois lugares da tela).
--
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/idiomas_ingles_expressoes_<nivel>[_relampago].json (revisão de
-- Rhoney, em lotes).

update mental.territories set display_order = 55 where id = 'espanhol_basico';
update mental.territories set display_order = 56 where id = 'espanhol_intermediario';
update mental.territories set display_order = 57 where id = 'espanhol_avancado';
update mental.territories set display_order = 58 where id = 'frances_basico';
update mental.territories set display_order = 59 where id = 'frances_intermediario';
update mental.territories set display_order = 60 where id = 'frances_avancado';

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('ingles_expressoes_basico', 'idiomas', true, 3, 49, 'idiomas', 'ingles'),
    ('ingles_expressoes_intermediario', 'idiomas', true, 3, 50, 'idiomas', 'ingles'),
    ('ingles_expressoes_avancado', 'idiomas', true, 3, 51, 'idiomas', 'ingles'),
    ('ingles_expressoes_relampago_basico', 'idiomas', true, 3, 52, 'idiomas', 'ingles'),
    ('ingles_expressoes_relampago_intermediario', 'idiomas', true, 3, 53, 'idiomas', 'ingles'),
    ('ingles_expressoes_relampago_avancado', 'idiomas', true, 3, 54, 'idiomas', 'ingles')
on conflict (id) do nothing;
