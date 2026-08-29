-- MENTAL — Resposta do admin ao feedback geral (pedido de Rhoney, 29/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 032_mentalcoins.sql.
--
-- "Deve haver... campos que eu possa responder, discutir e interagir com
-- o usuário" — resposta única do admin por feedback (não uma thread
-- completa; se precisar de mais trocas, o usuário manda outro feedback
-- novo, que vira outra linha nesta mesma tabela).
alter table mental.app_feedback
    add column if not exists admin_reply text,
    add column if not exists admin_reply_at timestamptz,
    add column if not exists reply_read_by_user boolean not null default false;
