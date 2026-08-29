-- MENTAL — Canal de denúncia (auditoria de segurança, 28/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 030_photo_bucket_private.sql.
--
-- Achado: não existia nenhuma forma de um usuário reportar a foto/nome
-- de outro — a única moderação era reativa (admin olhando a fila de
-- pendentes). DIR-001 §4 e POL-003 §2.4 exigem um canal de denúncia
-- pra conteúdo já aprovado que se revele impróprio depois.
create table if not exists mental.reports (
    id uuid primary key default gen_random_uuid(),
    reporter_user_id uuid not null references auth.users(id) on delete cascade,
    reported_user_id uuid not null references auth.users(id) on delete cascade,
    reason text not null,
    resolved boolean not null default false,
    created_at timestamptz not null default now()
);

create index if not exists idx_reports_resolved on mental.reports (resolved);
