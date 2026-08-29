-- MENTAL — Bloqueio de usuário (auditoria de conformidade Google Play, 29/08/2026, item 6)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 037_attempt_timed.sql.
--
-- Achado: a denúncia (mental.reports, migration 031) já existia, mas
-- não havia mecanismo pra impedir a mesma pessoa de continuar mandando
-- pedido de amizade depois de denunciada/recusada. Direcional (A
-- bloqueia B não implica B bloqueia A) — o backend trata bloqueio em
-- qualquer direção como suficiente pra impedir novo contato
-- (app/services.py::is_blocked_either_way).
create table if not exists mental.user_blocks (
    id uuid primary key default gen_random_uuid(),
    blocker_user_id uuid not null references auth.users(id) on delete cascade,
    blocked_user_id uuid not null references auth.users(id) on delete cascade,
    created_at timestamptz not null default now(),
    unique (blocker_user_id, blocked_user_id)
);

create index if not exists idx_user_blocks_blocker on mental.user_blocks (blocker_user_id);
create index if not exists idx_user_blocks_blocked on mental.user_blocks (blocked_user_id);
