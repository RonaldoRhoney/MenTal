-- V6 — Mundo dos Valores (05/09/2026, pedido de Rhoney). Formato novo
-- de conteúdo: "cápsula de texto + perguntas" (educação financeira/
-- economia — nunca aconselhamento de investimento, ver
-- FOUNDATION/POLITICA_CONTEUDO_SEGURO_QUALQUER_IDADE.md e o campo
-- `meta.principio` de cada arquivo fonte em Mundo_dos_Valores/*.json).
--
-- Decisão de arquitetura: reaproveita 100% o Challenge normal (nunca
-- cronometrado — não entra em nenhuma lista TIMED_*) em vez de criar
-- uma mecânica nova. Cada "pergunta" de uma cápsula vira um Challenge;
-- o texto da cápsula (lido ANTES da pergunta, mesmo espírito das
-- pistas de Detetive Mental/áudio de Ouvido Afiado) mora no novo campo
-- opcional `reading_passage` — nulo em todo o resto do app.

alter table mental.challenges add column if not exists reading_passage text;

insert into mental.worlds (id, name, display_order) values
    ('valores', 'Mundo dos Valores', 6)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id) values
    ('bolsa', 'valores', true, 2, 49, 'valores'),
    ('criptomoedas', 'valores', true, 2, 50, 'valores'),
    ('cenario_global', 'valores', true, 2, 51, 'valores'),
    ('financas_dia_a_dia', 'valores', true, 2, 52, 'valores')
on conflict (id) do nothing;

-- Conteúdo em si (159 perguntas) é carregado DEPOIS desta migração,
-- via scripts/append_production_content.py (mesmo padrão de idiomas,
-- ver Mundo_dos_Idiomas/README.md), a partir de backend/content/valores_*.json.
