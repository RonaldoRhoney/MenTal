-- MENTAL — MENTAL-DIR-001 / MENTAL-POL-002 (24/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 020_blocks.sql.
--
-- MENTAL passa a ser exclusivo pra maiores de 18 anos — sem mais age
-- gate multi-público nem child_safe_mode. As colunas antigas
-- (age_mode, child_safe_mode) NÃO são removidas aqui de propósito —
-- ainda há testadores reais usando o app em produção (teste
-- fechado/informal em andamento); DROP COLUMN é destrutivo e
-- irreversível. Ficam deprecated, sem nenhum código lendo/escrevendo
-- nelas a partir de agora. Avaliar remoção de verdade depois que o
-- teste fechado estabilizar.

alter table mental.profiles
    add column if not exists age_confirmed_at timestamptz,
    add column if not exists terms_version_accepted text;
