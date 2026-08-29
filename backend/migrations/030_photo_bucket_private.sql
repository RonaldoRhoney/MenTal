-- MENTAL — Bucket de fotos privado + URL assinada (auditoria de segurança, 28/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 029_friend_request_consent.sql.
--
-- Achado: o bucket profile-photos era público (leitura sem autenticação
-- nenhuma), contrariando DIR-001 §3.2/§3.3 e POL-002/POL-003, que exigem
-- "bucket privado, acesso via URL assinada". Consequência prática: com o
-- user_id de qualquer um (exposto em FriendOut), dava pra montar a URL
-- e ler fotos 'pending'/'rejected' — justamente as que a moderação
-- decidiu NÃO mostrar.
--
-- Fix: bucket vira privado; a única forma de ler uma foto agora é uma
-- URL assinada de curta duração, gerada pelo BACKEND com a credencial
-- de admin (SUPABASE_SERVICE_ROLE_KEY, app/supabase_admin.py) — que já
-- aplica a checagem de moderação (services.public_photo_url) antes de
-- gerar a URL. Não sobra mais nenhum caminho de leitura direta sem
-- passar por essa checagem.
update storage.buckets set public = false where id = 'profile-photos';

drop policy if exists "Public read profile photos" on storage.objects;
-- Sem policy de SELECT nenhuma: o client nunca lê o bucket diretamente
-- (upload continua liberado pro dono via as policies de INSERT/UPDATE/
-- DELETE já existentes, inalteradas) — toda leitura passa pelo backend
-- com service_role, que ignora RLS por definição.
