-- V7 — Mundo do Trânsito (06/09/2026, pedido de Rhoney). Mesmo formato
-- "cápsula de texto + perguntas" já usado no Mundo dos Valores
-- (migration 063) — reaproveita 100% o Challenge normal, mesma coluna
-- `reading_passage` (já existe, não precisa de novo ALTER), nunca
-- cronometrado. 5 territórios: educação/legislação, história e
-- curiosidades, transportes terrestres, economia do trânsito,
-- prevenção e segurança viária (ver Mundo_do_Transito/*.json e
-- POLITICA_CONTEUDO_SEGURO_QUALQUER_IDADE.md — bloco de prevenção
-- revisado com rigor redobrado, nunca detalhe gráfico de acidente nem
-- estatística de mortes/feridos).

insert into mental.worlds (id, name, display_order) values
    ('transito', 'Mundo do Trânsito', 7)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id) values
    ('educacao_legislacao', 'transito', true, 2, 53, 'transito'),
    ('historia_curiosidades', 'transito', true, 2, 54, 'transito'),
    ('transportes_terrestres', 'transito', true, 2, 55, 'transito'),
    ('economia_transito', 'transito', true, 2, 56, 'transito'),
    ('prevencao_seguranca', 'transito', true, 2, 57, 'transito')
on conflict (id) do nothing;

-- Conteúdo em si (120 perguntas) é carregado DEPOIS desta migração,
-- via scripts/append_production_content.py (mesmo padrão de idiomas/
-- valores), a partir de backend/content/transito_*.json.
