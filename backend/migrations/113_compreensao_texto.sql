-- Mundo dos Idiomas — Compreensão de Texto Corrido de Inglês
-- (MUNDO_IDIOMAS_INGLES_COMPREENSAO_TEXTO_V1.md, já aprovado, 30/09/2026). Mesmo padrão
-- de Phrasal Verbs/Expressões/Conjugação/Compostas/Contrações: block_id "ingles" direto
-- (não é idioma novo), nunca um bloco próprio.
--
-- Diferente das frentes anteriores: os 6 territórios (normal + "relâmpago") são
-- NUNCA cronometrados (ver NEVER_TIMED_TERRITORY_IDS em app/config.py) — reaproveita o
-- mesmo mecanismo de "cápsula de texto + perguntas" já usado em Valores/Trânsito/
-- Gastronomia/Oceanos/Espaço, cujo motivo (ler contra o relógio contraria o propósito de
-- compreensão de leitura) se aplica igualmente aqui. "Relâmpago" nesta frente significa
-- só "texto mais curto, menos perguntas por unidade", nunca timer.
--
-- display_order 79-84 (contíguo, logo depois de Contrações Informais em 73-78, ANTES de
-- Espanhol/Francês) — Espanhol/Francês são empurrados de 79-84 pra 85-90, mesmo motivo
-- das migrations 109/110/111/112 (evitar o bloco "ingles" aparecer partido em dois
-- lugares da tela).
--
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_content.py
-- content/idiomas_ingles_compreensao_<nivel>[_relampago].json (revisão de Rhoney, em
-- lotes).

update mental.territories set display_order = 85 where id = 'espanhol_basico';
update mental.territories set display_order = 86 where id = 'espanhol_intermediario';
update mental.territories set display_order = 87 where id = 'espanhol_avancado';
update mental.territories set display_order = 88 where id = 'frances_basico';
update mental.territories set display_order = 89 where id = 'frances_intermediario';
update mental.territories set display_order = 90 where id = 'frances_avancado';

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('ingles_compreensao_basico', 'idiomas', true, 3, 79, 'idiomas', 'ingles'),
    ('ingles_compreensao_intermediario', 'idiomas', true, 3, 80, 'idiomas', 'ingles'),
    ('ingles_compreensao_avancado', 'idiomas', true, 3, 81, 'idiomas', 'ingles'),
    ('ingles_compreensao_relampago_basico', 'idiomas', true, 3, 82, 'idiomas', 'ingles'),
    ('ingles_compreensao_relampago_intermediario', 'idiomas', true, 3, 83, 'idiomas', 'ingles'),
    ('ingles_compreensao_relampago_avancado', 'idiomas', true, 3, 84, 'idiomas', 'ingles')
on conflict (id) do nothing;
