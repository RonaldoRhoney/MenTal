-- MENTAL — Redesign da tela Movimento: gráfico intradiário real (26/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 022_level_feedback.sql.
--
-- checkpoint_bonus_mask (movement_cycles) só guarda SE um bônus de
-- checkpoint já foi pago, nunca QUANTOS passos existiam em cada ponto
-- do dia — sem isso não dá pra desenhar a curva de progressão
-- intradiária pedida no redesign. Um snapshot por coleta (POST
-- /movement/collect) resolve isso pra frente; ciclos já fechados antes
-- desta migration simplesmente não têm pontos intermediários (só o
-- total final), o que é aceitável.

create table if not exists mental.movement_snapshots (
    id uuid primary key,
    cycle_id uuid not null references mental.movement_cycles(id),
    recorded_at timestamptz not null default now(),
    steps_total integer not null
);

create index if not exists movement_snapshots_cycle_id_idx on mental.movement_snapshots(cycle_id);
