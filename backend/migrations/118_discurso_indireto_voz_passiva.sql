-- Mundo dos Idiomas — Discurso Indireto (Reported Speech) e Voz Passiva de Inglês
-- (MUNDO_IDIOMAS_INGLES_DISCURSO_INDIRETO_VOZ_PASSIVA_V1.md, aprovado 03/10/2026,
-- prioridade 2 da análise de lacunas do Inglês de 02/10/2026). Mesmo padrão de block_id
-- "ingles" direto + território normal e Relâmpago por nível, formato MCQ normal (não é
-- cápsula de texto, não precisa de NEVER_TIMED) — igual Preposições e Artigos.
--
-- Família "discursoindireto" (um só território por nível cobre voz passiva E discurso
-- indireto juntos, conforme §2 do doc — a transformação gramatical específica varia
-- item a item dentro do mesmo território, não são duas frentes separadas).
--
-- display_order 115-120 (contíguo, logo depois de Listening Ativo em 109-114, ANTES de
-- Espanhol/Francês) — Espanhol/Francês empurrados de 115-120 pra 121-126, mesmo motivo
-- de sempre (evitar o bloco "ingles" aparecer partido em dois lugares da tela).
--
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/idiomas_ingles_discursoindireto_<nivel>[_relampago].json (revisão de Rhoney,
-- em lotes).

update mental.territories set display_order = 121 where id = 'espanhol_basico';
update mental.territories set display_order = 122 where id = 'espanhol_intermediario';
update mental.territories set display_order = 123 where id = 'espanhol_avancado';
update mental.territories set display_order = 124 where id = 'frances_basico';
update mental.territories set display_order = 125 where id = 'frances_intermediario';
update mental.territories set display_order = 126 where id = 'frances_avancado';

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('ingles_discursoindireto_basico', 'idiomas', true, 3, 115, 'idiomas', 'ingles'),
    ('ingles_discursoindireto_intermediario', 'idiomas', true, 3, 116, 'idiomas', 'ingles'),
    ('ingles_discursoindireto_avancado', 'idiomas', true, 3, 117, 'idiomas', 'ingles'),
    ('ingles_discursoindireto_relampago_basico', 'idiomas', true, 3, 118, 'idiomas', 'ingles'),
    ('ingles_discursoindireto_relampago_intermediario', 'idiomas', true, 3, 119, 'idiomas', 'ingles'),
    ('ingles_discursoindireto_relampago_avancado', 'idiomas', true, 3, 120, 'idiomas', 'ingles')
on conflict (id) do nothing;
