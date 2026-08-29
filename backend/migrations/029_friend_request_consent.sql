-- MENTAL — Consentimento de amizade (auditoria de segurança, 28/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 028_photo_reset_moderation_on_overwrite.sql.
--
-- Achado: resgatar um invite_code criava a amizade IMEDIATAMENTE, sem
-- nunca perguntar ao dono do código — qualquer estranho com o código
-- (compartilhado publicamente) passava a ver user_id, nome real, foto
-- de perfil e XP do dono automaticamente, e podia desafiá-lo pra
-- batalhas. Agora o resgate cria um PEDIDO pendente; a amizade só conta
-- (aparece em /social/friends, ranking de amigos, batalhas) depois que
-- o dono aceita explicitamente.
alter table mental.friendships
    add column if not exists status text not null default 'accepted',
    add column if not exists requested_by uuid;

-- Linhas já existentes (criadas antes desta migration) continuam
-- 'accepted' pelo default acima — não retroage consentimento em
-- amizades já estabelecidas, só passa a exigir a partir de agora.
