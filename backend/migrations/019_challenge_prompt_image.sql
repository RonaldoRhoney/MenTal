-- MENTAL — CONHECIMENTO_CONTEUDO_GERAL_E_IMAGEM.md §3 (aprovado)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 018_user_profile.sql.

alter table mental.challenges
    add column if not exists prompt_image text;
