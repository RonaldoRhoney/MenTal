-- Achado de auditoria de segurança M2 (05/09/2026): POST
-- /learning-pauses/{id}/complete concedia XP sem NENHUMA prova de que a
-- Pausa foi de fato lida — um script podia chamar /complete direto,
-- sem nunca ter chamado /next, e ganhar o XP fixo. Piso de tempo mínimo
-- exige um registro de "serviu esta Pausa a este usuário agora",
-- análogo a Attempt.served_at / WordPuzzleResult.started_at, criado em
-- GET /learning-pauses/next e checado em /complete.

create table if not exists mental.learning_pause_serves (
    user_id uuid not null,
    learning_pause_id uuid not null references mental.learning_pauses(id),
    served_at timestamptz not null default now(),
    primary key (user_id, learning_pause_id)
);
