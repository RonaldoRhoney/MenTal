-- MENTAL LINGO — sugestões de fonte aberta (Wikcionário) com revisão humana
-- (aprovado por Rhoney, 25/09/2026, "fonte aberta + sua aprovação"). Uma
-- resposta vinda da fonte externa NASCE 'pending' (servida com o aviso
-- "ainda não revisado"); só vira resposta oficial quando Rhoney aprova
-- (scripts/review_mental_lingo_suggestions.py). 'rejected' nunca é servida.
-- Sem user_id: votos de utilidade são só contadores agregados.

create table if not exists mental.mental_lingo_suggestions (
    word text not null,
    target_language text not null default '',
    answer_text text not null,
    source text not null default 'wiktionary',
    status text not null default 'pending',
    useful_votes integer not null default 0,
    wrong_votes integer not null default 0,
    fetched_at timestamp not null default (now() at time zone 'utc'),
    primary key (word, target_language)
);

alter table mental.mental_lingo_suggestions enable row level security;
