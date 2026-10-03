-- Mundo dos Idiomas — Listening Ativo de Inglês
-- (MUNDO_IDIOMAS_INGLES_LISTENING_ATIVO_V1.md, aprovado 03/10/2026, prioridade 1 da
-- análise de lacunas do Inglês de 02/10/2026). Mesmo padrão de block_id "ingles" direto
-- (não é idioma novo) + território normal e Relâmpago por nível, igual às demais frentes.
--
-- Decisão de escopo confirmada por Rhoney (03/10/2026, §8 do doc): áudio toca SÓ sob
-- toque explícito do usuário (nunca automático) — mesmo padrão já estabelecido em todo o
-- resto do app (MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md §2.2), sem introduzir um comportamento
-- novo de reprodução automática.
--
-- NEVER_TIMED (igual Compreensão de Texto): ouvir contra o relógio contraria o propósito
-- do exercício — "Relâmpago" aqui significa áudio mais curto/menos perguntas, nunca timer.
-- Aplicado em config.py NEVER_TIMED_TERRITORY_IDS, não nesta migration.
--
-- Novo campo Challenge.audio_script (migration abaixo + models.py): texto a ser lido via
-- TTS (flutter_edge_tts, já em produção), SEPARADO do `prompt` visível — `prompt` é a
-- pergunta de compreensão (sempre visível), `audio_script` é a frase/diálogo ouvido,
-- nunca mostrado como texto na tela (senão deixaria de ser teste de escuta).
--
-- display_order 109-114 (contíguo, logo depois de Preposições e Artigos em 103-108,
-- ANTES de Espanhol/Francês) — Espanhol/Francês empurrados de 109-114 pra 115-120, mesmo
-- motivo de sempre (evitar o bloco "ingles" aparecer partido em dois lugares da tela).
--
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/idiomas_ingles_listening_<nivel>[_relampago].json (revisão de Rhoney, em lotes).

alter table mental.challenges add column if not exists audio_script text;

update mental.territories set display_order = 115 where id = 'espanhol_basico';
update mental.territories set display_order = 116 where id = 'espanhol_intermediario';
update mental.territories set display_order = 117 where id = 'espanhol_avancado';
update mental.territories set display_order = 118 where id = 'frances_basico';
update mental.territories set display_order = 119 where id = 'frances_intermediario';
update mental.territories set display_order = 120 where id = 'frances_avancado';

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('ingles_listening_basico', 'idiomas', true, 3, 109, 'idiomas', 'ingles'),
    ('ingles_listening_intermediario', 'idiomas', true, 3, 110, 'idiomas', 'ingles'),
    ('ingles_listening_avancado', 'idiomas', true, 3, 111, 'idiomas', 'ingles'),
    ('ingles_listening_relampago_basico', 'idiomas', true, 3, 112, 'idiomas', 'ingles'),
    ('ingles_listening_relampago_intermediario', 'idiomas', true, 3, 113, 'idiomas', 'ingles'),
    ('ingles_listening_relampago_avancado', 'idiomas', true, 3, 114, 'idiomas', 'ingles')
on conflict (id) do nothing;
