-- MENTAL — Revisão de erros ao final da rodada (REGRA_REVISAO_ERROS_
-- FIM_RODADA.md): marca uma tentativa como "revisão" (nunca gera
-- XP/streak/badge/progresso — só confirma aprendizado). Gravado pelo
-- servidor em GET /challenges/{id}/reattempt, nunca por flag do client.
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 058_content_suggestions.sql.

alter table mental.attempts add column if not exists is_review boolean not null default false;
