-- MENTAL — V2 item 15: Palavras Relâmpago (PALAVRAS_RELAMPAGO.md)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 014_friendships.sql.
--
-- Nenhuma tabela nova, nenhum conteúdo novo — reaproveita 100% o banco
-- de desafios já curado do território Palavras (níveis médio/difícil).
-- Só campos adicionais no registro de tentativa, seguindo o padrão de
-- idempotência via attempt_id já em uso.

alter table mental.attempts
    add column if not exists response_time_ms integer,
    add column if not exists timed_out boolean not null default false,
    add column if not exists speed_bonus_xp integer not null default 0;
