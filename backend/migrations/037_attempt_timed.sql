-- MENTAL — Corrige bônus de velocidade fora de escopo no Relâmpago generalizado (29/08/2026)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 036_v3_cultura_geral.sql.
--
-- Achado: com o Relâmpago generalizado pra todos os territórios (pedido
-- de Rhoney: "em todos os módulos tem que haver um relâmpago"), o bônus
-- de velocidade em POST /answer continuava decidido por uma allowlist
-- fixa de territórios (só "palavras" e "conhecimento") — um desafio
-- servido em modo relâmpago em qualquer outro território mostrava o
-- cronômetro no cliente mas nunca pagava bônus por responder rápido.
-- "timed" passa a ser gravado pelo backend no momento em que o desafio
-- é entregue (GET /challenges/next, mesma origem de served_at) e
-- consultado em POST /answer — nunca um flag vindo do client, que
-- poderia ser forjado pra sempre reivindicar o bônus.
alter table mental.attempts
    add column if not exists timed boolean not null default false;
