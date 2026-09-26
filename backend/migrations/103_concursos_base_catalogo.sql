-- Mundo dos Concursos — base do catálogo (decisão de Rhoney, 25/09/2026: ordem
-- Municipais -> Estaduais -> Federais; conteúdo atual NÃO é apagado).
-- Tudo ADITIVO: nenhuma tabela/linha existente é alterada. Só o que estiver com
-- review_status = 'approved' é servido ao app (revisão humana obrigatória).
-- Fichas de concursos reais só entram com fonte oficial verificável (fonte_url).

create table if not exists mental.concurso_bancas (
    id text primary key,
    nome text not null,
    perfil text,
    review_status text not null default 'pending',
    created_at timestamp not null default (now() at time zone 'utc')
);

create table if not exists mental.concursos (
    id text primary key,
    esfera text not null check (esfera in ('municipal', 'estadual', 'federal')),
    uf text,
    municipio text,
    orgao text not null,
    banca_id text references mental.concurso_bancas(id),
    status text not null check (status in ('encerrado', 'em_andamento', 'em_analise')),
    edital_url text,
    fonte_url text not null,
    review_status text not null default 'pending',
    created_at timestamp not null default (now() at time zone 'utc'),
    updated_at timestamp not null default (now() at time zone 'utc')
);
create index if not exists idx_concursos_esfera_status on mental.concursos (esfera, status);

create table if not exists mental.concurso_dicas (
    id text primary key,
    concurso_id text references mental.concursos(id) on delete cascade,
    banca_id text references mental.concurso_bancas(id) on delete cascade,
    texto text not null,
    review_status text not null default 'pending'
);

create table if not exists mental.concurso_revisoes (
    id text primary key,
    concurso_id text references mental.concursos(id) on delete cascade,
    materia text not null,
    titulo text not null,
    conteudo text not null,
    review_status text not null default 'pending'
);

alter table mental.concurso_bancas enable row level security;
alter table mental.concursos enable row level security;
alter table mental.concurso_dicas enable row level security;
alter table mental.concurso_revisoes enable row level security;
