-- MENTAL — V4 item 1: Perfil Público + Torcida
-- (PERFIL_PUBLICO_E_TORCIDA_V1.md + TORCIDA_MULTIPLA_V2.md, aprovados).
-- Rodar no SQL Editor do projeto Supabase.
--
-- Perfil público em si não precisa de tabela nova — reaproveita 100%
-- dado já existente (profiles, user_badges, user_territory_progress,
-- streaks), sempre lido em tempo real (GET /profile/{id}/public), nunca
-- persistido separadamente. Só a Torcida (reação visual, TORCIDA_
-- MULTIPLA_V2.md) precisa de uma tabela nova.

create table if not exists mental.torcida_reactions (
    id uuid primary key default gen_random_uuid(),
    from_user_id uuid not null references auth.users(id) on delete cascade,
    to_user_id uuid not null references auth.users(id) on delete cascade,
    -- vibracao|balao|coracao|joinha (TORCIDA_MULTIPLA_V2.md §2) — check
    -- em vez de FK pra tabela de catálogo: conjunto pequeno e fixo,
    -- mesmo padrão já usado em reaction_type de app_feedback_reactions.
    reaction_type text not null check (reaction_type in ('vibracao', 'balao', 'coracao', 'joinha')),
    created_at timestamptz not null default now()
);

create index if not exists idx_torcida_reactions_to_user on mental.torcida_reactions(to_user_id);
-- Limite diário agregado por (remetente, destinatário) — TORCIDA_MULTIPLA_V2.md §3.
create index if not exists idx_torcida_reactions_from_to_created on mental.torcida_reactions(from_user_id, to_user_id, created_at);
