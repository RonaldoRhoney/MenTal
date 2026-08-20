-- MENTAL — schema inicial, schema Postgres "mental"
-- Espelha backend/app/models.py e docs/01_FOUNDATION/DATA_MODEL.md.
-- Rodar no SQL Editor do projeto Supabase (Rhoney) DEPOIS de criar o
-- projeto — não roda sozinho, precisa do projeto existir primeiro.
--
-- user_id em cada tabela referencia auth.users(id) — o schema de
-- identidade central do Supabase Auth compartilhado da RhoneyInc
-- (MENTAL_KICKOFF.md §2). Nenhuma tabela aqui duplica dado de identidade
-- (email, nome) que já vive em auth.users.

create schema if not exists mental;

create extension if not exists pgcrypto; -- gen_random_uuid()

create table mental.profiles (
    user_id uuid primary key references auth.users(id) on delete cascade,
    nickname text not null,
    nickname_is_system_generated boolean not null default true,
    age_mode text not null default 'unknown' check (age_mode in ('unknown', 'child', 'adult')),
    child_safe_mode boolean not null default true,
    xp_total integer not null default 0,
    level integer not null default 1,
    parental_gate_passed_at timestamptz,
    created_at timestamptz not null default now()
);

create table mental.territories (
    id text primary key,
    challenge_type text not null,
    requires_subscription boolean not null default false,
    free_sample_count integer not null default 0,
    display_order integer not null default 0
);

create table mental.user_territory_progress (
    user_id uuid not null references auth.users(id) on delete cascade,
    territory_id text not null references mental.territories(id),
    xp_in_territory integer not null default 0,
    conquered_at timestamptz,
    primary key (user_id, territory_id)
);

create table mental.challenges (
    id uuid primary key default gen_random_uuid(),
    territory_id text not null references mental.territories(id),
    difficulty_level integer not null default 1,
    prompt text not null,
    options jsonb,
    correct_answer text not null,
    explanation text not null,
    age_reviewed boolean not null default false
);

create table mental.challenge_hints (
    id uuid primary key default gen_random_uuid(),
    challenge_id uuid not null references mental.challenges(id) on delete cascade,
    hint_level integer not null,
    content text not null
);

-- attempt_id é gerado pelo CLIENTE (idempotência, MENTAL_KICKOFF.md §9.5)
-- — nunca default gen_random_uuid() aqui, o valor sempre vem do insert.
create table mental.attempts (
    attempt_id uuid primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    challenge_id uuid not null references mental.challenges(id),
    submitted_answer text,
    is_correct boolean,
    hints_used integer not null default 0,
    xp_base integer,
    xp_awarded integer,
    created_at timestamptz not null default now()
);

create index idx_attempts_user_challenge on mental.attempts (user_id, challenge_id);
create index idx_attempts_created_at on mental.attempts (created_at);

create table mental.streaks (
    user_id uuid primary key references auth.users(id) on delete cascade,
    current_streak integer not null default 0,
    last_played_date date,
    freeze_available boolean not null default true,
    freeze_used_this_week boolean not null default false,
    week_anchor date
);

create table mental.subscriptions (
    user_id uuid primary key references auth.users(id) on delete cascade,
    status text not null default 'none' check (status in ('none', 'active', 'expired', 'cancelled')),
    google_play_purchase_token text,
    validated_at timestamptz,
    expires_at timestamptz
);

create table mental.daily_challenge_usage (
    user_id uuid not null references auth.users(id) on delete cascade,
    usage_date date not null,
    challenges_consumed integer not null default 0,
    primary key (user_id, usage_date)
);

create table mental.invites (
    id uuid primary key default gen_random_uuid(),
    inviter_user_id uuid not null references auth.users(id) on delete cascade,
    invite_code text not null unique,
    created_at timestamptz not null default now()
);

create table mental.invite_conversions (
    id uuid primary key default gen_random_uuid(),
    invite_id uuid not null references mental.invites(id),
    invited_user_id uuid not null references auth.users(id) on delete cascade,
    converted_at timestamptz not null default now(),
    constraint uq_invite_conversion_user unique (invited_user_id)
);

-- Seed dos 4 territórios (conteúdo dos desafios é populado à parte —
-- ver backend/app/seed.py como referência de formato, não rodar o seed
-- Python contra produção sem curadoria de conteúdo real,
-- RISKS_AND_OPEN_DECISIONS.md §2).
insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order) values
    ('palavras', 'palavras', false, 0, 1),
    ('numeros', 'numeros', false, 0, 2),
    ('logica', 'logica', true, 2, 3),
    ('conhecimento', 'conhecimento', true, 2, 4)
on conflict (id) do nothing;
