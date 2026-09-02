-- MENTAL — V4: Astronomia e Espaço (V4/V4_NOVOS_TERRITORIOS.md §5,
-- aprovado). Terceiro dos 5 territórios novos da V4. Reaproveita 100% a
-- arquitetura de Challenge já existente, nenhuma coluna/tabela nova.
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 052_v4_veiculos.sql.

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id) values
    ('astronomia', 'astronomia', true, 2, 37, 'cultura_geral')
on conflict (id) do nothing;
