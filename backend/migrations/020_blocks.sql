-- MENTAL — Blocos (BLOCOS_MENUS.md, aprovado 2026-08-23)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 019_challenge_prompt_image.sql.
--
-- Bloco é puramente organização de menu — nunca progressão/conquista
-- (isso continua em mental.worlds). Mesmo padrão de mental.worlds
-- (tabela simples com display_order), só sem qualquer coluna ou lógica
-- de "completo".

create table if not exists mental.blocks (
    id text primary key,
    name text not null,
    display_order integer not null default 0
);

alter table mental.territories
    add column if not exists block_id text references mental.blocks(id);

insert into mental.blocks (id, name, display_order) values
    ('matematica', 'Matemática', 1),
    ('enem', 'ENEM', 2),
    ('concursos', 'Concursos', 3),
    ('regioes', 'Regiões', 4),
    ('mundo', 'Mundo', 5)
on conflict (id) do nothing;

-- Únicos territórios já existentes que entram num Bloco agora
-- (BLOCOS_MENUS.md §3) — os demais (Palavras, Textos, Enigmas, Visual,
-- Conhecimento) ficam sem block_id (NULL), acessíveis normalmente fora
-- de qualquer Bloco, como o documento define.
update mental.territories set block_id = 'matematica' where id in ('numeros', 'logica');
