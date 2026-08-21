-- MENTAL — V2 item 8: Notificações (NOTIFICATIONS.md)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 007_visual_territory.sql.
--
-- Preferência por categoria vive no backend (não só localmente no
-- aparelho, ao contrário do toggle de som/MICROINTERACTIONS.md) — quem
-- decide SE notifica é o job agendado no backend, que precisa conhecer a
-- preferência. push_token fica nulo até o client registrar um token de
-- verdade (obtido do Firebase Cloud Messaging, ver ARCHITECTURE deste
-- item — nenhum dado é enviado a um provedor externo antes disso).

alter table mental.profiles
    add column if not exists push_token text,
    add column if not exists notif_reengagement_enabled boolean not null default true,
    add column if not exists notif_social_enabled boolean not null default true,
    add column if not exists last_seen_at timestamptz,
    add column if not exists last_reengagement_notified_window text,
    add column if not exists last_known_weekly_rank integer;
