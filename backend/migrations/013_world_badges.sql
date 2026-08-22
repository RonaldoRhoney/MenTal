-- MENTAL — V2 item 11: Conquista territorial aprofundada (V2_KICKOFF.md §6A)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 012_worlds.sql.
--
-- Reaproveita 100% o sistema de badges já existente (item 1) — nenhuma
-- tabela nova, nenhum campo novo. `criteria_value` guarda o
-- display_order do mundo (1=Linguagem, 2=Mente Lógica) em vez de um
-- world_id novo no schema de Badge, mesmo padrão já usado por
-- streak_days/total_correct_answers (campo numérico existente).
-- "Todos os mundos completos" não ganha badge próprio de propósito —
-- já é coberto pelo badge "Colecionador" (all_territories_conquered),
-- matematicamente equivalente já que os mundos particionam 100% dos
-- territórios.

insert into mental.badges (code, name, description, criteria_type, criteria_value, display_order) values
    ('world_master_linguagem', 'Mestre da Linguagem', 'Complete todos os territórios do Mundo da Linguagem.', 'world_completed_by_display_order', 1, 6),
    ('world_master_mente_logica', 'Mestre da Mente Lógica', 'Complete todos os territórios do Mundo da Mente Lógica.', 'world_completed_by_display_order', 2, 7)
on conflict (code) do nothing;
