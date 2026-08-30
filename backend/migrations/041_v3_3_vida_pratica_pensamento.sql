-- MENTAL — V3.3: Vida Prática e Pensamento (V3/V3.3_VIDA_PRATICA_PENSAMENTO.md)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de
-- 040_v3_2_tecnologia_pausa_aprender.sql.
--
-- 4 dos 5 blocos do doc — Finanças Pessoais, Filosofia, Artes, Saúde e
-- Bem-estar — cada um com 1 território homônimo (mesmo padrão de
-- "regioes"). "Jogos de Palavras" (Caça-palavras/Cruzadas, §6 do doc)
-- fica de fora: não reaproveita o mecanismo Relâmpago, exige
-- arquitetura de jogo própria (grade), desenhada numa etapa separada.
-- Conteúdo é curadoria manual via backend/content/*.json — nunca
-- inserido aqui.

insert into mental.blocks (id, name, display_order) values
    ('financas_pessoais', 'Finanças Pessoais', 8),
    ('filosofia', 'Filosofia', 9),
    ('artes', 'Artes', 10),
    ('saude_bemestar', 'Saúde e Bem-estar', 11)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('financas_pessoais', 'financas_pessoais', true, 2, 26, 'cultura_geral', 'financas_pessoais'),
    ('filosofia', 'filosofia', true, 2, 27, 'cultura_geral', 'filosofia'),
    ('artes', 'artes', true, 2, 28, 'cultura_geral', 'artes'),
    ('saude_bemestar', 'saude_bemestar', true, 2, 29, 'cultura_geral', 'saude_bemestar')
on conflict (id) do nothing;
