-- MENTAL — V2 item 2: Enigmas/charadas (V2_KICKOFF.md §6A)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 004_badges.sql.
-- Nenhuma tabela nova — reaproveita 100% do schema de desafio existente
-- (mental.challenges, mental.challenge_hints). Só o território novo.
-- Conteúdo dos desafios (charadas) não é migrado via SQL, mesmo padrão
-- de 001_initial_schema.sql — ver backend/app/seed.py como referência de
-- formato para popular mental.challenges quando o conteúdo real for
-- carregado em produção.

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order) values
    ('enigmas', 'enigmas', true, 2, 5)
on conflict (id) do nothing;
