-- MENTAL — attempt_id de cada lado da Batalha gravado no próprio registro
-- Achado de auditoria de segurança CRÍTICO (01/09/2026): o fluxo de
-- Batalha fazia o CLIENT inventar um attempt_id novo (uuid v4) porque
-- GET /battles/{id}/my-challenge não devolvia um — POST /challenges/{id}
-- /answer aceitava qualquer attempt_id novo e criava uma tentativa nova
-- pra ele, sem limite, permitindo responder o MESMO desafio repetidas
-- vezes (attempt_id novo a cada chamada) e ganhar XP sem fim. A correção
-- faz o SERVIDOR gerar e gravar o attempt_id de cada lado no momento em
-- que o desafio é de fato servido (criação da batalha pro desafiante,
-- primeira abertura pro desafiado) — mesmo padrão já usado em
-- GET /challenges/next. Rodar no SQL Editor do projeto Supabase.

alter table mental.battles
    add column if not exists challenger_attempt_id uuid,
    add column if not exists opponent_attempt_id uuid;
