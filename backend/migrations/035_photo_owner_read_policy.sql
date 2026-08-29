-- MENTAL — Corrige upload de foto quebrado (bug real, 29/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 034_app_feedback_reactions.sql.
--
-- Causa raiz confirmada: a migration 030_photo_bucket_private.sql
-- removeu TODA política de SELECT em storage.objects pro bucket
-- profile-photos (correto pra impedir leitura pública/de terceiros —
-- LGPD/DIR-001), mas sem perceber que o próprio Supabase Storage
-- precisa verificar se um arquivo já existe (SELECT) antes de decidir
-- entre INSERT/UPDATE num upload com upsert:true. Sem NENHUMA policy de
-- SELECT, essa checagem interna falhava com "new row violates row-level
-- security policy" — bloqueando o upload de qualquer foto nova, mesmo
-- do próprio dono.
--
-- Fix: dono pode ler os PRÓPRIOS objetos (necessário pro upsert
-- funcionar). Não reabre leitura pública nem de terceiros — isso
-- continua impossível sem a service_role key do backend, mantendo o
-- fail-closed de moderação intacto (USER_PROFILE.md §3.1).
drop policy if exists "Users can read own profile photo" on storage.objects;
create policy "Users can read own profile photo"
on storage.objects for select
using (bucket_id = 'profile-photos' and auth.uid()::text = (storage.foldername(name))[1]);
