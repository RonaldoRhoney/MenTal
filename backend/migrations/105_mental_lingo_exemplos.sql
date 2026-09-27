-- MENTAL LINGO fase 2 — frases-exemplo curadas por palavra (aprovado por Rhoney, 26/09/2026).
-- Uma frase curta com tradução por palavra, escrita e revisada por humanos (nunca gerada em
-- tempo real). Só 'approved' é servida. A fala da tradução em português vale só para o nível
-- 'basico' (decisão de Rhoney: no Intermediário/Avançado só a frase em inglês).

create table if not exists mental.lingo_exemplos (
    id uuid primary key default gen_random_uuid(),
    idioma text not null default 'ingles',
    nivel text not null check (nivel in ('basico', 'intermediario', 'avancado')),
    palavra text not null,
    palavra_pt text,
    frase text not null,
    traducao text not null,
    review_status text not null default 'approved',
    created_at timestamp not null default (now() at time zone 'utc'),
    unique (idioma, palavra, frase)
);
create index if not exists idx_lingo_exemplos_palavra on mental.lingo_exemplos (idioma, lower(palavra));

alter table mental.lingo_exemplos enable row level security;
