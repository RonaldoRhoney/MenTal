-- MENTAL — Timing server-side pra bônus de velocidade (auditoria de segurança, 28/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 026_profile_photo.sql.
--
-- Achado: response_time_ms em POST /challenges/{id}/answer vinha 100% do
-- client — mandar 0 dobrava o bônus de velocidade (até +100% de XP) em
-- qualquer território cronometrado (Palavras Relâmpago, Conhecimento).
-- served_at passa a ser gravado pelo backend no momento em que o desafio
-- é de fato entregue (GET /challenges/next), e o tempo de resposta passa
-- a ser calculado como (agora - served_at) no servidor.
alter table mental.attempts
    add column if not exists served_at timestamptz not null default now();
