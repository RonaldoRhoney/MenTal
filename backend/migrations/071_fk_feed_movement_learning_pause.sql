-- MENTAL — corrige a MESMA classe de bug que a migration 048 já
-- corrigiu (LGPD, achado 4.1 da AUDITORIA_COMPLETA_PRE_PRODUCAO_V1.md,
-- 11/09/2026): 4 tabelas criadas DEPOIS da 048 (Feed/Seguir de 06/09,
-- convite de Movimento de 05/09, piso de Pausa de Aprendizagem de
-- 05/09) foram escritas sem NENHUMA foreign key pra auth.users. Sem
-- FK, DELETE /profile (services.delete_account -> delete_auth_user)
-- não falha, mas deixa essas 4 tabelas com dado pessoal órfão
-- permanentemente no banco após a exclusão de conta — exatamente o
-- que a 048 já havia eliminado nas outras 5 tabelas antigas.
--
-- Nenhuma das 6 colunas abaixo guarda texto livre com valor duradouro
-- (diferente de app_feedback/level_feedback/content_suggestions, que
-- continuam SET NULL) — todas se qualificam para CASCADE puro.
--
-- Checagem a fazer ANTES de rodar esta migration em produção (mesmo
-- cuidado da 048): confirmar 0 linhas órfãs nas 4 tabelas.
--   select count(*) from mental.learning_pause_serves lps
--     where not exists (select 1 from auth.users u where u.id = lps.user_id);
--   select count(*) from mental.movement_invites mi
--     where not exists (select 1 from auth.users u where u.id = mi.from_user_id)
--        or not exists (select 1 from auth.users u where u.id = mi.to_user_id);
--   select count(*) from mental.feed_events fe
--     where not exists (select 1 from auth.users u where u.id = fe.user_id);
--   select count(*) from mental.follows f
--     where not exists (select 1 from auth.users u where u.id = f.follower_user_id)
--        or not exists (select 1 from auth.users u where u.id = f.followed_user_id);
-- Se algum COUNT vier > 0, apagar as linhas órfãs antes de criar a FK
-- (a própria alter table falha com FK violation, então serve de trava
-- de segurança adicional).

alter table mental.learning_pause_serves
    add constraint learning_pause_serves_user_id_fkey
    foreign key (user_id) references auth.users(id) on delete cascade;

alter table mental.movement_invites
    add constraint movement_invites_from_user_id_fkey foreign key (from_user_id) references auth.users(id) on delete cascade,
    add constraint movement_invites_to_user_id_fkey foreign key (to_user_id) references auth.users(id) on delete cascade;

alter table mental.feed_events
    add constraint feed_events_user_id_fkey
    foreign key (user_id) references auth.users(id) on delete cascade;

alter table mental.follows
    add constraint follows_follower_user_id_fkey foreign key (follower_user_id) references auth.users(id) on delete cascade,
    add constraint follows_followed_user_id_fkey foreign key (followed_user_id) references auth.users(id) on delete cascade;
