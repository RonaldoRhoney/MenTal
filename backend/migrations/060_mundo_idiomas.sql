-- MENTAL — Mundo dos Idiomas (V5/README.md, V5/mundo_dos_idiomas_*.json).
-- Cria o Mundo novo, os 9 territórios (inglês/espanhol/francês x
-- básico/intermediário/avançado) e a coluna accepted_answers em
-- mental.challenges (desafio de tradução em texto livre tem mais de
-- uma resposta correta possível — ex.: "The house is big" e "The
-- house is big.").
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 059_review_errors_round.sql.
-- Conteúdo em si (os 540 challenges) é carregado DEPOIS desta
-- migração, via scripts/append_production_content.py (ver V5/README.md).

alter table mental.challenges add column if not exists accepted_answers jsonb;

insert into mental.worlds (id, name, display_order) values
    ('idiomas', 'Mundo dos Idiomas', 5)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id) values
    ('ingles_basico', 'idiomas', true, 3, 40, 'idiomas'),
    ('ingles_intermediario', 'idiomas', true, 3, 41, 'idiomas'),
    ('ingles_avancado', 'idiomas', true, 3, 42, 'idiomas'),
    ('espanhol_basico', 'idiomas', true, 3, 43, 'idiomas'),
    ('espanhol_intermediario', 'idiomas', true, 3, 44, 'idiomas'),
    ('espanhol_avancado', 'idiomas', true, 3, 45, 'idiomas'),
    ('frances_basico', 'idiomas', true, 3, 46, 'idiomas'),
    ('frances_intermediario', 'idiomas', true, 3, 47, 'idiomas'),
    ('frances_avancado', 'idiomas', true, 3, 48, 'idiomas')
on conflict (id) do nothing;
