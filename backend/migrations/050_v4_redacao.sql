-- MENTAL — V4 item 3: Redação
-- (V4/V3_ENCERRAMENTO_PENDENCIAS_PARA_V4.md §2.1 — mecânica nunca tinha
-- sido definida; decisão de Rhoney em 02/09/2026: múltipla escolha
-- sobre TÉCNICA de escrita, mesmo formato de todo o resto do app — sem
-- campo de texto livre do usuário, sem avaliação subjetiva de redação
-- alheia. Reaproveita 100% a arquitetura de Challenge já existente,
-- nenhuma coluna/tabela nova. Território no Mundo da Linguagem, ao
-- lado de Palavras/Textos/Enigmas.
-- Rodar no SQL Editor do projeto Supabase DEPOIS de
-- 049_public_profile_and_torcida.sql.

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id) values
    ('redacao', 'redacao', true, 2, 34, 'linguagem')
on conflict (id) do nothing;
