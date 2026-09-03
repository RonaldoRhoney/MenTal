-- MENTAL — Mundo da Descoberta (PROMPT_CLAUDE_CODE_MUNDO_DESCOBERTA.md).
-- Mundo Cultura Geral ficou extenso demais pra navegar — os 5
-- territórios novos da V4 saem dele e ganham um Mundo próprio. Pura
-- reorganização de agrupamento visual: "mundo completo" nunca é
-- armazenado (é sempre derivado de mental.user_territory_progress),
-- então isso não move/reseta XP, progresso nem estatística nenhuma —
-- só o campo territories.world_id dessas 5 linhas.
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 055_v4_ouvido_afiado.sql.

insert into mental.worlds (id, name, display_order) values
    ('descoberta', 'Mundo da Descoberta', 4)
on conflict (id) do nothing;

update mental.territories
set world_id = 'descoberta'
where id in ('invencoes', 'veiculos', 'astronomia', 'detetive_mental', 'ouvido_afiado');
