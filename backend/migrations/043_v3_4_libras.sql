-- MENTAL — V3.4: Libras (V3/V3.4_LIBRAS.md)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de
-- 042_v3_5_curiosidade_relampago.sql.
insert into mental.blocks (id, name, display_order) values
    ('libras', 'Libras', 13)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('libras', 'libras', true, 2, 31, 'cultura_geral', 'libras')
on conflict (id) do nothing;

-- Vídeo de referência institucional (INES/VLibras/UFSC/IFs) opcional em
-- Pausa para Aprender, com atribuição de fonte obrigatória quando
-- presente (V3.4_LIBRAS.md §2/§3.2) — tudo-ou-nada, validado em
-- app/content_validation.py, não no banco.
alter table mental.learning_pauses add column if not exists video_url varchar;
alter table mental.learning_pauses add column if not exists source_name varchar;
alter table mental.learning_pauses add column if not exists source_url varchar;
