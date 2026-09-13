-- Visibilidade de foto de perfil passa a ser escolha do PRÓPRIO usuário
-- (decisão de Rhoney, 13/09/2026), não mais um portão de aprovação do
-- admin: a fila de moderação (/admin/profile-photos) tinha um backlog
-- de 13+ usuários reais esperando revisão manual, deixando a foto de
-- todo mundo invisível no Ranking/Amigos/Batalhas por semanas — não é
-- assim que o produto deve funcionar.
--
-- photo_is_public é o novo controle: o usuário liga/desliga a qualquer
-- momento na tela de Perfil, sem depender de ninguém. Default TRUE:
-- foto de perfil já é obrigatória pra liberar o jogo (routers/profile.py
-- mandatory_fields), então quem já enviou uma claramente pretendia usá-la.
--
-- photo_moderation_status é MANTIDA (não removida) — deixa de ser o
-- portão de entrada, mas continua servindo de override administrativo:
-- um admin pode marcar 'rejected' numa foto reportada (ver
-- services/routers social.py — fluxo de denúncia já existente) pra
-- forçar ela invisível mesmo que o dono marque como pública de novo.
-- 'pending' deixa de ser usado por uploads novos (ver routers/
-- profile.py) — o backfill abaixo aprova tudo que já estava na fila,
-- fechando o backlog de uma vez.

alter table mental.profiles add column if not exists photo_is_public boolean not null default true;

update mental.profiles set photo_moderation_status = 'approved' where photo_moderation_status = 'pending';
