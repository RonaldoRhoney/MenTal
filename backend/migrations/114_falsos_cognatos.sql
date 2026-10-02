-- Mundo dos Idiomas — Falsos Cognatos (False Friends) de Inglês
-- (MUNDO_IDIOMAS_INGLES_FALSOS_COGNATOS_V1.md, já aprovado, 30/09/2026). Mesmo padrão de
-- Phrasal Verbs/Expressões/Conjugação/Compostas/Contrações: block_id "ingles" direto (não
-- é idioma novo), nunca um bloco próprio. Território normal + Relâmpago (sempre
-- cronometrado, conteúdo distinto) por nível — volta ao padrão normal de "frase +
-- pergunta" (não é cápsula de texto como Compreensão de Texto, migration 113).
--
-- display_order 91-96 (contíguo, logo depois de Compreensão de Texto em 79-84, ANTES de
-- Espanhol/Francês) — Espanhol/Francês são empurrados de 85-90 pra 97-102, mesmo motivo
-- das migrations 109/110/111/112/113 (evitar o bloco "ingles" aparecer partido em dois
-- lugares da tela).
--
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/idiomas_ingles_falsoscognatos_<nivel>[_relampago].json (revisão de Rhoney, em
-- lotes).

update mental.territories set display_order = 97 where id = 'espanhol_basico';
update mental.territories set display_order = 98 where id = 'espanhol_intermediario';
update mental.territories set display_order = 99 where id = 'espanhol_avancado';
update mental.territories set display_order = 100 where id = 'frances_basico';
update mental.territories set display_order = 101 where id = 'frances_intermediario';
update mental.territories set display_order = 102 where id = 'frances_avancado';

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('ingles_falsoscognatos_basico', 'idiomas', true, 3, 91, 'idiomas', 'ingles'),
    ('ingles_falsoscognatos_intermediario', 'idiomas', true, 3, 92, 'idiomas', 'ingles'),
    ('ingles_falsoscognatos_avancado', 'idiomas', true, 3, 93, 'idiomas', 'ingles'),
    ('ingles_falsoscognatos_relampago_basico', 'idiomas', true, 3, 94, 'idiomas', 'ingles'),
    ('ingles_falsoscognatos_relampago_intermediario', 'idiomas', true, 3, 95, 'idiomas', 'ingles'),
    ('ingles_falsoscognatos_relampago_avancado', 'idiomas', true, 3, 96, 'idiomas', 'ingles')
on conflict (id) do nothing;
