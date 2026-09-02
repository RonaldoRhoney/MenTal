-- MENTAL — V4: Invenções, Grandes Construções e Como Surge uma Ideia
-- (V4/V4_NOVOS_TERRITORIOS.md §1, aprovado). Primeiro dos 5 territórios
-- novos da V4 — rollout sequencial, mesmo princípio já usado na V3
-- (cada bloco só avança depois do anterior estar validado).
-- Reaproveita 100% a arquitetura de Challenge já existente (múltipla
-- escolha, modo Relâmpago com janela universal de 20s), nenhuma coluna/
-- tabela nova.
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 050_v4_redacao.sql.

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id) values
    ('invencoes', 'invencoes', true, 2, 35, 'cultura_geral')
on conflict (id) do nothing;
