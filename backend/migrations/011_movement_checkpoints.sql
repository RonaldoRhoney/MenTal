-- MENTAL — V2 item 9 (extensão): Checkpoints intradiários (STEP_COUNTER_MOVIMENTO.md §4)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 010_movement_goal.sql.
--
-- As 24h do ciclo são divididas em partes iguais (config.
-- MOVEMENT_CHECKPOINT_PARTS); cada fechamento intradiário (exceto o
-- último, que coincide com o fim do próprio ciclo) paga um bônus extra
-- se o total acumulado até ali já bate a faixa proporcional de passos.
-- Bitmask evita pagar o mesmo checkpoint mais de uma vez.

alter table mental.movement_cycles
    add column if not exists checkpoint_bonus_mask integer not null default 0;
