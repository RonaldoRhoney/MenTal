-- MENTAL — corrige a MESMA classe de bug já eliminada pelas migrations
-- 048/071 (LGPD): mental.notifications (criada pela migration 075,
-- 14/09/2026) foi escrita sem NENHUMA foreign key pra auth.users. Sem
-- FK, DELETE /profile (services.delete_account -> delete_auth_user)
-- não falha, mas deixa notificações com dado pessoal de TERCEIROS
-- (nome real de quem desafiou/torceu/pediu amizade, dentro de `title`/
-- `body`) órfãs permanentemente no banco após a exclusão da conta.
--
-- Achado da auditoria de segurança pré-lançamento mundial (17/09/2026).
-- Mesmo raciocínio de CASCADE puro já usado em feed_events/follows/
-- movement_invites (071): notifications não guarda texto de valor
-- duradouro fora do contexto da própria notificação, então não há
-- motivo pra SET NULL (diferente de app_feedback/level_feedback/
-- content_suggestions).
--
-- Checagem a fazer ANTES de rodar em produção (mesmo cuidado da 048/071):
--   select count(*) from mental.notifications n
--     where not exists (select 1 from auth.users u where u.id = n.user_id);
-- Se vier > 0, apagar as linhas órfãs antes (a própria alter table já
-- falha com FK violation, servindo de trava de segurança adicional).

alter table mental.notifications
    add constraint notifications_user_id_fkey
    foreign key (user_id) references auth.users(id) on delete cascade;
