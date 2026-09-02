-- MENTAL — V4: Ouvido Afiado (V4/V4_NOVOS_TERRITORIOS.md §3,
-- aprovado). Quinto e último dos 5 territórios novos da V4 — primeiro
-- bloco a mudar a MODALIDADE SENSORIAL do desafio: o jogador ouve um
-- som (em vez de ler/ver) e identifica o que é, em múltipla escolha.
-- Extensão do formato Challenge já existente (3 colunas opcionais:
-- audio_url, audio_source_name, audio_source_url — mesmo padrão
-- "tudo-ou-nada" já usado em video_url/source_name/source_url da
-- Pausa para Aprender de Libras, V3.4_LIBRAS.md §3.2).
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 054_v4_detetive_mental.sql.

alter table mental.challenges add column if not exists audio_url text;
alter table mental.challenges add column if not exists audio_source_name text;
alter table mental.challenges add column if not exists audio_source_url text;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id) values
    ('ouvido_afiado', 'ouvido_afiado', true, 2, 39, 'cultura_geral')
on conflict (id) do nothing;
