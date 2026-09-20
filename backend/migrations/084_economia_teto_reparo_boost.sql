-- REGRA_OFICIAL_GAMIFICACAO_MENTAL.md Fase 3 (20/09/2026, aprovada por
-- Rhoney): teto diário de XP de resposta, reparo de streak (50 moedas)
-- e boost de +20% de XP por 24h (80 moedas).

alter table mental.streaks add column if not exists lost_streak integer;
alter table mental.streaks add column if not exists repair_until date;

create table if not exists mental.daily_answer_xp (
    user_id uuid not null references auth.users(id) on delete cascade,
    xp_date date not null,
    xp_earned integer not null default 0,
    primary key (user_id, xp_date)
);

create table if not exists mental.xp_boosts (
    user_id uuid primary key references auth.users(id) on delete cascade,
    expires_at timestamp not null
);
