-- MENTAL — V2 item 3: Textos (interpretação/inferência) (V2_KICKOFF.md §6A)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 005_enigmas_territory.sql.
-- Nenhuma tabela/coluna nova — o parágrafo-base vive no campo "prompt" já
-- existente de mental.challenges. Mesmo padrão de 001/005: conteúdo dos
-- desafios não é migrado via SQL, só o território (ver backend/app/seed.py
-- como referência de formato para popular mental.challenges).

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order) values
    ('textos', 'textos', true, 2, 6)
on conflict (id) do nothing;
