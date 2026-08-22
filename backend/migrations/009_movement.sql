-- MENTAL — V2 item 9: Contador de passos & movimento (STEP_COUNTER_MOVIMENTO.md)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 008_notifications.sql.
--
-- movement_cycle_anchor_at nunca muda depois de setado uma vez (define o
-- horário-âncora pessoal do ciclo de 24h do usuário, §2). Uma linha em
-- movement_cycles por janela de 24h — histórico completo fica registrado,
-- mesmo raciocínio já usado para attempts (nunca sobrescrever, só somar).

alter table mental.profiles
    add column if not exists movement_enabled boolean not null default false,
    add column if not exists movement_cycle_anchor_at timestamptz;

create table if not exists mental.movement_cycles (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references mental.profiles(user_id),
    cycle_start_at timestamptz not null,
    cycle_end_at timestamptz not null,
    steps_collected integer not null default 0,
    xp_awarded integer not null default 0,
    report_sent boolean not null default false
);

create index if not exists idx_movement_cycles_user_id on mental.movement_cycles(user_id);
