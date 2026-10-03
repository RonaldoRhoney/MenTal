-- Mundo dos Idiomas — Variação Regional (American English vs. British English)
-- (MUNDO_IDIOMAS_INGLES_VARIACAO_AME_BRE_V1.md, aprovado 03/10/2026, prioridade 4 da
-- análise de lacunas do Inglês de 02/10/2026). Opção A confirmada por Rhoney (03/10/2026):
-- território dedicado, mesmo padrão de Falsos Cognatos — nunca editar conteúdo já
-- publicado/auditado (Opção B descartada).
--
-- Mesmo padrão de block_id "ingles" direto + território normal e Relâmpago por nível,
-- formato MCQ normal (não é cápsula de texto, não precisa de NEVER_TIMED).
--
-- Volume igual Falsos Cognatos (§3 do doc): 25 Desafios + 25 Relâmpagos por nível.
--
-- display_order 133-138 (contíguo, logo depois de Gírias de Internet em 121-126, ANTES de
-- Espanhol/Francês) — Espanhol/Francês empurrados de 127-132 pra 133-138, mesmo motivo de
-- sempre (evitar o bloco "ingles" aparecer partido em dois lugares da tela).
--
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/idiomas_ingles_amebre_<nivel>[_relampago].json (revisão de Rhoney, em lotes).
-- Nunca apresentar uma variante como "errada" (§5 do doc) — critério de aceite.

update mental.territories set display_order = 133 where id = 'espanhol_basico';
update mental.territories set display_order = 134 where id = 'espanhol_intermediario';
update mental.territories set display_order = 135 where id = 'espanhol_avancado';
update mental.territories set display_order = 136 where id = 'frances_basico';
update mental.territories set display_order = 137 where id = 'frances_intermediario';
update mental.territories set display_order = 138 where id = 'frances_avancado';

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('ingles_amebre_basico', 'idiomas', true, 3, 127, 'idiomas', 'ingles'),
    ('ingles_amebre_intermediario', 'idiomas', true, 3, 128, 'idiomas', 'ingles'),
    ('ingles_amebre_avancado', 'idiomas', true, 3, 129, 'idiomas', 'ingles'),
    ('ingles_amebre_relampago_basico', 'idiomas', true, 3, 130, 'idiomas', 'ingles'),
    ('ingles_amebre_relampago_intermediario', 'idiomas', true, 3, 131, 'idiomas', 'ingles'),
    ('ingles_amebre_relampago_avancado', 'idiomas', true, 3, 132, 'idiomas', 'ingles')
on conflict (id) do nothing;
