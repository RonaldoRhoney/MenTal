-- MENTAL LINGO — fila de lacunas de vocabulário (aprovada por Rhoney,
-- 25/09/2026): palavra/frase perguntada por voz que o vocabulário curado
-- ainda não tem. Só agregado (palavra, idioma, quantas vezes) — NENHUM
-- user_id, nenhum áudio, nenhuma transcrição completa. Serve de fila de
-- curadoria: as mais pedidas viram conteúdo revisado; nada entra no app
-- sem revisão (regra: só informação verdadeira, custo zero).

create table if not exists mental.mental_lingo_gaps (
    word text not null,
    target_language text not null default '',
    times_asked integer not null default 1,
    first_asked_at timestamp not null default (now() at time zone 'utc'),
    last_asked_at timestamp not null default (now() at time zone 'utc'),
    primary key (word, target_language)
);

alter table mental.mental_lingo_gaps enable row level security;
