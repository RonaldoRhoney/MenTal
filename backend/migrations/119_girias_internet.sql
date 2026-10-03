-- Mundo dos Idiomas — Gírias e Inglês Informal de Internet
-- (MUNDO_IDIOMAS_INGLES_GIRIAS_INTERNET_V1.md, aprovado 03/10/2026, prioridade 3 da
-- análise de lacunas do Inglês de 02/10/2026). Mesmo padrão de block_id "ingles" direto +
-- território normal e Relâmpago por nível, formato MCQ normal (não é cápsula de texto,
-- não precisa de NEVER_TIMED) — igual Preposições/Discurso Indireto.
--
-- Volume menor que as frentes de gramática (§2 do doc): 30 Desafios + 30 Relâmpagos por
-- nível (não 100+100) — universo de gírias relevantes e didaticamente estáveis é menor.
--
-- display_order 121-126 (contíguo, logo depois de Discurso Indireto em 115-120, ANTES de
-- Espanhol/Francês) — Espanhol/Francês empurrados de 121-126 pra 127-132, mesmo motivo de
-- sempre (evitar o bloco "ingles" aparecer partido em dois lugares da tela).
--
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/idiomas_ingles_girias_<nivel>[_relampago].json (revisão de Rhoney, em lotes).
-- Risco conhecido de desatualização (§8 do doc) — registrado, sem mecanismo de revisão
-- periódica automática nesta entrega.

update mental.territories set display_order = 127 where id = 'espanhol_basico';
update mental.territories set display_order = 128 where id = 'espanhol_intermediario';
update mental.territories set display_order = 129 where id = 'espanhol_avancado';
update mental.territories set display_order = 130 where id = 'frances_basico';
update mental.territories set display_order = 131 where id = 'frances_intermediario';
update mental.territories set display_order = 132 where id = 'frances_avancado';

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('ingles_girias_basico', 'idiomas', true, 3, 121, 'idiomas', 'ingles'),
    ('ingles_girias_intermediario', 'idiomas', true, 3, 122, 'idiomas', 'ingles'),
    ('ingles_girias_avancado', 'idiomas', true, 3, 123, 'idiomas', 'ingles'),
    ('ingles_girias_relampago_basico', 'idiomas', true, 3, 124, 'idiomas', 'ingles'),
    ('ingles_girias_relampago_intermediario', 'idiomas', true, 3, 125, 'idiomas', 'ingles'),
    ('ingles_girias_relampago_avancado', 'idiomas', true, 3, 126, 'idiomas', 'ingles')
on conflict (id) do nothing;
