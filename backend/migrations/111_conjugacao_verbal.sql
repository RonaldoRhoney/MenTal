-- Mundo dos Idiomas — Conjugação Verbal de Inglês
-- (MUNDO_IDIOMAS_CONJUGACAO_VERBAL_V1.md, já aprovado, 29/09/2026).
-- Mesmo padrão do Phrasal Verbs/Expressões Idiomáticas (migrations 107-108, 110):
-- block_id "ingles" direto (Conjugação Verbal é conteúdo do idioma Inglês, não um
-- idioma novo), nunca um bloco próprio. Território normal + Relâmpago (sempre
-- cronometrado, conteúdo distinto) por nível. Espanhol/Francês ficam FORA desta
-- entrega (escopo revisado por Rhoney em 26/09/2026) — arquitetura genérica
-- pronta pra expansão futura, mas nenhuma produção de conteúdo agora.
--
-- display_order 55-60 (contíguo, logo depois de Expressões Idiomáticas em
-- 49-54, ANTES de Espanhol/Francês) — Espanhol/Francês são empurrados de
-- 55-60 pra 61-66, mesmo motivo das migrations 109/110 (evitar o bloco
-- "ingles" aparecer partido em dois lugares da tela).
--
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/idiomas_ingles_conjugacao_<nivel>[_relampago].json (revisão de
-- Rhoney, em lotes por nível).

update mental.territories set display_order = 61 where id = 'espanhol_basico';
update mental.territories set display_order = 62 where id = 'espanhol_intermediario';
update mental.territories set display_order = 63 where id = 'espanhol_avancado';
update mental.territories set display_order = 64 where id = 'frances_basico';
update mental.territories set display_order = 65 where id = 'frances_intermediario';
update mental.territories set display_order = 66 where id = 'frances_avancado';

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('ingles_conjugacao_basico', 'idiomas', true, 3, 55, 'idiomas', 'ingles'),
    ('ingles_conjugacao_intermediario', 'idiomas', true, 3, 56, 'idiomas', 'ingles'),
    ('ingles_conjugacao_avancado', 'idiomas', true, 3, 57, 'idiomas', 'ingles'),
    ('ingles_conjugacao_relampago_basico', 'idiomas', true, 3, 58, 'idiomas', 'ingles'),
    ('ingles_conjugacao_relampago_intermediario', 'idiomas', true, 3, 59, 'idiomas', 'ingles'),
    ('ingles_conjugacao_relampago_avancado', 'idiomas', true, 3, 60, 'idiomas', 'ingles')
on conflict (id) do nothing;
