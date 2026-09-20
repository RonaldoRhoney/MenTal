-- REGRA_OFICIAL_GAMIFICACAO_MENTAL.md Fase 2 (19/09/2026, aprovada por
-- Rhoney). Anti-farm genérico das recompensas novas + distintivos dos
-- marcos de streak de 30 e 100 dias (o de 7 dias já existe: iron_streak).

create table if not exists mental.reward_claims (
    user_id uuid not null,
    claim_key text not null,
    claimed_at timestamp not null default now(),
    primary key (user_id, claim_key)
);

insert into mental.badges (code, name, description, criteria_type, criteria_value, display_order) values
    ('streak_30', 'Mês de Foco', 'Mantenha uma sequência de 30 dias seguidos.', 'streak_days', 30, 8),
    ('streak_100', 'Centenário da Sequência', 'Mantenha uma sequência de 100 dias seguidos — distintivo raro.', 'streak_days', 100, 9)
on conflict (code) do nothing;
