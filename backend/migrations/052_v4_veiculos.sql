-- MENTAL — V4: Carros, Motos e Aviões (V4/V4_NOVOS_TERRITORIOS.md §2,
-- aprovado). Segundo dos 5 territórios novos da V4. Reaproveita 100% a
-- arquitetura de Challenge já existente, nenhuma coluna/tabela nova.
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 051_v4_invencoes.sql.

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id) values
    ('veiculos', 'veiculos', true, 2, 36, 'cultura_geral')
on conflict (id) do nothing;
