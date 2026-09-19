-- MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md §3 (unifica com a spec anterior
-- MUNDO_IDIOMAS_BIBLIOTECA_VISUAL_V1.md) — reforço visual (foto/GIF)
-- para idiomas falados, e o PRÓPRIO conteúdo do sinal (vídeo/GIF) para
-- Libras. Schema agnóstico de idioma de propósito: os mesmos 4 campos
-- servem para os dois casos, só vocab_media_type muda ('image' | 'gif' |
-- 'video'). Tudo-ou-nada (mesma disciplina de audio_url), validado em
-- app/content_validation.py — nunca mídia sem atribuição de licença
-- rastreável. Todos NULL por padrão: nenhuma curadoria de conteúdo é
-- feita nesta migration, só a estrutura que a comporta.

alter table mental.challenges add column if not exists vocab_media_url text;
alter table mental.challenges add column if not exists vocab_media_type text;
alter table mental.challenges add column if not exists vocab_media_source_name text;
alter table mental.challenges add column if not exists vocab_media_source_url text;
