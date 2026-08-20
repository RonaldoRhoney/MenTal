-- MENTAL — i18n-ready: language_code em mental.challenges
-- ARCHITECTURE_UPDATE_I18N_READY.md — 100% dos registros continuam
-- pt-BR hoje; este campo só evita migração de schema dolorosa quando um
-- segundo idioma for adicionado no futuro (inserir novos registros com
-- language_code diferente, sem alteração estrutural).
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 002_admin_role.sql.

alter table mental.challenges
    add column if not exists language_code text not null default 'pt-BR';

create index if not exists idx_challenges_territory_language
    on mental.challenges (territory_id, language_code);
