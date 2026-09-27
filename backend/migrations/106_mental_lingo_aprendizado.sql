-- MENTAL LINGO — aprendizado com o uso (pedido de Rhoney, 26/09/2026: "deixe a variação de forma
-- expansível, onde o Mental Lingo possa aprender com o usuário"). Custo zero, sem IA generativa:
--  1) lingo_padroes: modos de perguntar APROVADOS, carregados do banco (sem novo deploy). Cada linha
--     é uma regex (grupo 1 = termo; grupo 2 opcional = idioma) ligada a uma intenção.
--  2) lingo_perguntas_nao_entendidas: o que os jogadores perguntaram e o Lingo não entendeu, só
--     AGREGADO (texto normalizado + contador), sem usuário — é a fila que alimenta novos padrões.

create table if not exists mental.lingo_padroes (
    id uuid primary key default gen_random_uuid(),
    intencao text not null check (intencao in ('traducao', 'exemplo')),
    regex text not null,
    exemplo text,
    status text not null default 'approved',
    created_at timestamp not null default (now() at time zone 'utc')
);

create table if not exists mental.lingo_perguntas_nao_entendidas (
    texto text primary key,
    vezes integer not null default 1,
    primeira_vez timestamp not null default (now() at time zone 'utc'),
    ultima_vez timestamp not null default (now() at time zone 'utc'),
    status text not null default 'aberta'
);

alter table mental.lingo_padroes enable row level security;
alter table mental.lingo_perguntas_nao_entendidas enable row level security;
