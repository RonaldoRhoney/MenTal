-- MENTAL — V2 item 9 (extensão): Meta diária de passos (STEP_COUNTER_MOVIMENTO.md §4)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 009_movement.sql.
--
-- Meta é sempre definida pelo próprio usuário, nunca pelo sistema —
-- null significa "sem meta". Ultrapassar a meta paga um bônus extra,
-- separado do bônus escalonado por faixa de passos.

alter table mental.profiles
    add column if not exists movement_daily_goal_steps integer;

alter table mental.movement_cycles
    add column if not exists goal_bonus_awarded boolean not null default false;
