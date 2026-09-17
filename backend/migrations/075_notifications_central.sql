-- CENTRAL_DE_NOTIFICACOES_HOME_V1.md (14/09/2026, aprovado por Rhoney:
-- "histórico persistente", não um atalho visual sem memória) —
-- histórico centralizado de notificações dentro do app, agregando as
-- origens já existentes (Batalha, Torcida, Movimento, Amizade, sistema),
-- complementar ao push (nunca substitui). Ver services.create_notification
-- e app/models.py::Notification pro raciocínio completo.

create table if not exists mental.notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null,
    type varchar not null,
    title varchar not null,
    body text not null,
    data jsonb,
    read_at timestamptz,
    created_at timestamptz not null default now()
);

create index if not exists ix_notifications_user_id on mental.notifications (user_id);
create index if not exists ix_notifications_created_at on mental.notifications (created_at);
-- Consulta mais comum (lista/contagem de não lidas de UM usuário,
-- recente primeiro) — índice composto cobre isso sem precisar dos dois
-- índices simples acima pra essa query específica, mas os simples ficam
-- (created_at sozinho é usado pela limpeza por retenção, ver §3 do doc).
create index if not exists ix_notifications_user_id_created_at on mental.notifications (user_id, created_at desc);
