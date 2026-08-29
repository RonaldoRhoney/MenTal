-- MENTAL — MentalCoins (U.I/MENTALCOINS_V1.md, aprovado)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 031_reports.sql.
--
-- Moeda de prestígio semanal, sem valor monetário. Saldo e histórico são
-- 100% autoridade do backend (mesmo princípio de XP/Score) — o client
-- nunca calcula nem decide saldo, só exibe o que a API devolve.
create table if not exists mental.mentalcoins_balances (
    user_id uuid primary key references auth.users(id) on delete cascade,
    balance integer not null default 0,
    updated_at timestamptz not null default now()
);

create table if not exists mental.mentalcoins_transactions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    amount integer not null,
    reason text not null,
    created_at timestamptz not null default now()
);

create index if not exists idx_mentalcoins_transactions_user on mental.mentalcoins_transactions (user_id, created_at desc);

-- Congelamento dos vencedores da semana fechada (MENTALCOINS_V1.md §6) —
-- nunca recalculado durante a semana seguinte, só lido.
create table if not exists mental.mentalcoins_hall_of_fame (
    id uuid primary key default gen_random_uuid(),
    cycle_start date not null,
    cycle_end date not null,
    category text not null, -- xp_daily | steps_week | steps_day
    rank integer, -- 1/2/3 para xp_daily; null para steps_week/steps_day (vencedor único)
    reference_date date, -- dia específico dentro do ciclo (xp_daily/steps_day); null para steps_week
    user_id uuid not null references auth.users(id) on delete cascade,
    nickname text not null,
    amount integer not null, -- MentalCoins concedidos nesta entrada
    metric_value integer not null, -- XP do dia ou passos, conforme category
    created_at timestamptz not null default now()
);

create index if not exists idx_mentalcoins_hof_cycle on mental.mentalcoins_hall_of_fame (cycle_start, cycle_end);

-- Controle de idempotência da apuração semanal (MENTALCOINS_V1.md §6) —
-- evita creditar duas vezes o mesmo ciclo se o job rodar mais de uma vez
-- (reinício do processo, redeploy no meio do horário agendado, etc.).
create table if not exists mental.mentalcoins_processed_cycles (
    cycle_start date primary key,
    cycle_end date not null,
    processed_at timestamptz not null default now()
);

-- Catálogo de itens cosméticos resgatáveis só com MentalCoins (nunca com
-- dinheiro real, MENTALCOINS_V1.md §4). Preços iniciais ilustrativos,
-- calibrar depois do lançamento (§7).
create table if not exists mental.mentalcoins_items (
    id text primary key,
    name text not null,
    description text not null,
    cost integer not null,
    item_type text not null, -- avatar_frame | avatar
    display_order integer not null default 0
);

create table if not exists mental.mentalcoins_redemptions (
    user_id uuid not null references auth.users(id) on delete cascade,
    item_id text not null references mental.mentalcoins_items (id),
    redeemed_at timestamptz not null default now(),
    primary key (user_id, item_id)
);

insert into mental.mentalcoins_items (id, name, description, cost, item_type, display_order) values
    ('moldura_dourada', 'Moldura Dourada', 'Moldura de destaque para sua foto de perfil.', 80, 'avatar_frame', 1),
    ('moldura_roxa', 'Moldura Roxa', 'Moldura de prestígio para sua foto de perfil.', 150, 'avatar_frame', 2)
on conflict (id) do nothing;
