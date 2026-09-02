-- MENTAL — V4: Detetive Mental (V4/V4_NOVOS_TERRITORIOS.md §4,
-- aprovado). Quarto dos 5 territórios novos da V4 — primeiro a mudar a
-- ESTRUTURA do desafio, não só o assunto: 2-3 pistas reveladas em
-- etapas antes da pergunta final de múltipla escolha. Extensão do
-- formato Challenge já existente (nova coluna opcional `clues`, nula
-- em todo o resto do app), não um mecanismo do zero.
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 053_v4_astronomia.sql.

alter table mental.challenges add column if not exists clues jsonb;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id) values
    ('detetive_mental', 'detetive_mental', true, 2, 38, 'cultura_geral')
on conflict (id) do nothing;
