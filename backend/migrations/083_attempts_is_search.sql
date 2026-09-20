-- Achado A2 da revisão de segurança da Fase 2 (20/09/2026): resultado de
-- busca (GET /challenges/search) serve com was_last_of_batch=True e
-- pagaria o bônus de lote (+3 XP) em toda pergunta avulsa. Marcador
-- gravado pelo servidor; o bônus de lote ignora estas tentativas.
alter table mental.attempts add column if not exists is_search boolean not null default false;
