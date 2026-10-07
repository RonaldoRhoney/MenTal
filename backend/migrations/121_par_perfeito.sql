-- Mundo dos Idiomas — Par Perfeito de Inglês (formato "Complete a frase")
-- (MUNDO_IDIOMAS_INGLES_PAR_PERFEITO_V1.md, aprovado 05/10/2026;
-- MUNDO_IDIOMAS_INGLES_PAR_PERFEITO_DIAGNOSTICO_TECNICO_V1.md §4, decisão
-- confirmada por Rhoney 06/10/2026). Fase A: só o formato "Complete a
-- frase" (lacuna com to/too/two, their/there etc.) — estruturalmente
-- idêntico ao MCQ já usado em Preposições e Artigos, reaproveita 100% o
-- pipeline existente. Os outros 6 formatos (Pares de cards, Ouça e
-- ligue, Qual soa diferente, Ouça e escolha, Pronúncia por sentido,
-- Compare os sotaques) usam a tabela nova `par_perfeito_items`
-- (migration 122), ainda sem território/conteúdo nesta entrega.
--
-- Mesmo padrão de block_id "ingles" direto + território normal e
-- Relâmpago por nível, formato MCQ normal (timed via
-- ALWAYS_TIMED_TERRITORIES, igual Preposições/Discurso Indireto/Gírias/
-- AmE-BrE).
--
-- display_order 133-138 (contíguo, logo depois de AmE/BrE em 127-132,
-- ANTES de Espanhol/Francês) — Espanhol/Francês empurrados de 133-138
-- pra 139-144, mesmo motivo de sempre.
--
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/idiomas_ingles_parperfeito_<nivel>[_relampago].json (revisão
-- de Rhoney, em lotes).

update mental.territories set display_order = 139 where id = 'espanhol_basico';
update mental.territories set display_order = 140 where id = 'espanhol_intermediario';
update mental.territories set display_order = 141 where id = 'espanhol_avancado';
update mental.territories set display_order = 142 where id = 'frances_basico';
update mental.territories set display_order = 143 where id = 'frances_intermediario';
update mental.territories set display_order = 144 where id = 'frances_avancado';

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('ingles_parperfeito_basico', 'idiomas', true, 3, 133, 'idiomas', 'ingles'),
    ('ingles_parperfeito_intermediario', 'idiomas', true, 3, 134, 'idiomas', 'ingles'),
    ('ingles_parperfeito_avancado', 'idiomas', true, 3, 135, 'idiomas', 'ingles'),
    ('ingles_parperfeito_relampago_basico', 'idiomas', true, 3, 136, 'idiomas', 'ingles'),
    ('ingles_parperfeito_relampago_intermediario', 'idiomas', true, 3, 137, 'idiomas', 'ingles'),
    ('ingles_parperfeito_relampago_avancado', 'idiomas', true, 3, 138, 'idiomas', 'ingles')
on conflict (id) do nothing;
