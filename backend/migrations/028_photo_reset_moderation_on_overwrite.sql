-- MENTAL — Fecha o bypass de moderação de foto via reupload (auditoria de segurança, 28/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 027_attempt_served_at.sql.
--
-- Achado: a moderação de foto vive numa COLUNA do Postgres
-- (mental.profiles.photo_moderation_status), não no arquivo em si. O
-- path do objeto é fixo ({user_id}/photo.ext, upsert=true) e a policy de
-- Storage permite ao dono sobrescrever livremente o próprio arquivo.
-- Cenário de exploração: usuário sobe uma foto normal → aprovada pelo
-- admin → depois troca o CONTEÚDO do arquivo (via API do Storage
-- diretamente, fora do app) por algo impróprio, sem nunca passar de
-- novo por PUT /profile — a coluna continua 'approved' e a foto nova
-- aparece pra todo mundo sem moderação nenhuma.
--
-- Fix: trigger no próprio storage.objects — qualquer INSERT/UPDATE num
-- objeto do bucket profile-photos derruba o status pra 'pending' de
-- novo, não importa por qual caminho o arquivo mudou (app oficial ou
-- chamada direta à API do Storage). security definer porque o dono do
-- objeto (o usuário comum) não tem permissão de UPDATE em
-- mental.profiles de terceiros nem, aqui, nem precisa — é sempre a
-- PRÓPRIA linha dele sendo atualizada.
create or replace function mental.reset_photo_moderation_on_storage_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  owner_id uuid;
begin
  owner_id := (storage.foldername(new.name))[1]::uuid;
  update mental.profiles
     set photo_moderation_status = 'pending'
   where user_id = owner_id
     and photo_moderation_status = 'approved';
  return new;
end;
$$;

drop trigger if exists trg_reset_photo_moderation on storage.objects;
create trigger trg_reset_photo_moderation
after insert or update on storage.objects
for each row
when (new.bucket_id = 'profile-photos')
execute function mental.reset_photo_moderation_on_storage_change();
