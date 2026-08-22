-- MENTAL — Perfil do usuário (USER_PROFILE.md, aprovado)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 017_battles.sql.

alter table mental.profiles
    add column if not exists avatar_id text,
    add column if not exists real_name text,
    add column if not exists location_state text,
    add column if not exists location_country text,
    add column if not exists location_public boolean not null default false;
