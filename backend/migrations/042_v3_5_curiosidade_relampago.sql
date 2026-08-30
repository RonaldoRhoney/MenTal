-- MENTAL — V3.5: Curiosidade Relâmpago (V3/V3.5_CURIOSIDADE_RELAMPAGO.md)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de
-- 041_v3_3_vida_pratica_pensamento.sql.
--
-- Só território/bloco — reaproveita 100% a arquitetura de Challenge já
-- existente (o "fato de revelação" do doc é o campo `explanation`, já
-- sempre exibido pós-resposta; nenhuma coluna/tabela nova). Sempre
-- cronometrado (config.ALWAYS_TIMED_TERRITORIES, alterado no código,
-- não no banco). Conteúdo é curadoria manual via backend/content/*.json
-- — nunca inserido aqui.

insert into mental.blocks (id, name, display_order) values
    ('curiosidade_relampago', 'Curiosidade Relâmpago', 12)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('curiosidade_relampago', 'curiosidade_relampago', true, 2, 30, 'cultura_geral', 'curiosidade_relampago')
on conflict (id) do nothing;
