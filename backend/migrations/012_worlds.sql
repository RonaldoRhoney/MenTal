-- MENTAL — V2 item 10: Mundos completos (V2_KICKOFF.md §2/§6A)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 011_movement_checkpoints.sql.
--
-- Agrupamento aprovado por Rhoney em 2026-08-22: Mundo da Linguagem
-- (palavras/textos/enigmas) e Mundo da Mente Lógica (números/lógica/
-- visual/conhecimento). "Mundo completo" nunca é armazenado — é sempre
-- derivado em tempo real a partir de mental.user_territory_progress
-- (conquered_at), mesma disciplina já usada em badges (nunca duas
-- fontes de verdade pro mesmo fato).

create table if not exists mental.worlds (
    id text primary key,
    name text not null,
    display_order integer not null default 0
);

insert into mental.worlds (id, name, display_order) values
    ('linguagem', 'Mundo da Linguagem', 1),
    ('mente_logica', 'Mundo da Mente Lógica', 2)
on conflict (id) do nothing;

alter table mental.territories
    add column if not exists world_id text references mental.worlds(id);

update mental.territories set world_id = 'linguagem' where id in ('palavras', 'textos', 'enigmas');
update mental.territories set world_id = 'mente_logica' where id in ('numeros', 'logica', 'visual', 'conhecimento');
