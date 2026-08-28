-- MENTAL — Upload de foto de perfil real (26/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 025_app_feedback.sql.
--
-- Decisão de Rhoney: substitui o sistema de avatares emoji pré-definidos
-- por upload de foto real, visível publicamente (Ranking/Amigos/
-- Batalhas) junto do nome real (também passa a ser público — reversão
-- explícita da regra anterior "nome real nunca exibido publicamente",
-- registrada agora em USER_PROFILE.md). photo_moderation_status começa
-- 'pending' a cada novo upload — USER_PROFILE.md §3.1 exige moderação
-- (fail-closed) antes de qualquer foto aparecer pra outros usuários;
-- hoje só a camada manual (admin/Rhoney, via /admin/profile-photos)
-- está implementada — as camadas automatizadas (Claude/Mentora_AI)
-- ficam para quando essa integração existir.
--
-- avatar_id NÃO é removido (coluna antiga, deprecated, sem leitura pelo
-- client a partir de agora) — mesmo padrão já usado em colunas
-- deprecated anteriores (age_mode/child_safe_mode).

alter table mental.profiles
    add column if not exists photo_url text,
    add column if not exists photo_moderation_status text not null default 'none';
    -- 'none' (nunca fez upload) | 'pending' | 'approved' | 'rejected'

-- Bucket de Storage para as fotos — público pra leitura (o usuário já
-- consente que a foto seja vista por outros ao fazer upload), mas só o
-- próprio dono pode escrever no seu próprio caminho
-- (profile-photos/{user_id}/...).
insert into storage.buckets (id, name, public)
values ('profile-photos', 'profile-photos', true)
on conflict (id) do nothing;

drop policy if exists "Public read profile photos" on storage.objects;
create policy "Public read profile photos"
on storage.objects for select
using (bucket_id = 'profile-photos');

drop policy if exists "Users can upload own profile photo" on storage.objects;
create policy "Users can upload own profile photo"
on storage.objects for insert
with check (bucket_id = 'profile-photos' and auth.uid()::text = (storage.foldername(name))[1]);

drop policy if exists "Users can update own profile photo" on storage.objects;
create policy "Users can update own profile photo"
on storage.objects for update
using (bucket_id = 'profile-photos' and auth.uid()::text = (storage.foldername(name))[1])
with check (bucket_id = 'profile-photos' and auth.uid()::text = (storage.foldername(name))[1]);

drop policy if exists "Users can delete own profile photo" on storage.objects;
create policy "Users can delete own profile photo"
on storage.objects for delete
using (bucket_id = 'profile-photos' and auth.uid()::text = (storage.foldername(name))[1]);
