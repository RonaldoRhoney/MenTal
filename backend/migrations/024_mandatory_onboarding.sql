-- MENTAL — Cadastro mínimo obrigatório antes de jogar (26/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 023_movement_snapshots.sql.
--
-- Decisão de Rhoney: nome, país, cidade, gênero e faixa etária passam a
-- ser obrigatórios antes de liberar o jogo. USER_PROFILE.md §1/§3
-- bloqueava "cidade exata" por risco de localizar um menor — restrição
-- motivada pelo público misto de antes da DIR-001 (MENTAL agora é
-- exclusivo pra maiores de 18 anos, sem child_safe_mode). Colunas
-- antigas (location_state, location_country, real_name) continuam
-- existindo e sendo usadas; city/gender/age_range/onboarding_completed_at
-- são novas.

alter table mental.profiles
    add column if not exists city text,
    add column if not exists gender text,
    add column if not exists age_range text,
    add column if not exists onboarding_completed_at timestamptz;
