-- MENTAL — Recompensa do botão de convidar amigos (pedido de Rhoney):
-- 20 XP + 5 MentalCoins, teto de 1x/dia, separado do teto de
-- compartilhamento de conquista (Profile.last_share_reward_date) — são
-- botões e recompensas distintas, cada um com seu próprio teto diário.
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 056_mundo_descoberta.sql.

alter table mental.profiles add column if not exists last_app_invite_reward_date date;
