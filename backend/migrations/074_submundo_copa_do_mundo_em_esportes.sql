-- MUNDO_ESPORTES_ARQUITETURA_V1.md (14/09/2026, aprovado por Rhoney):
-- Mundo dos Esportes ganha 9 SubMundos, um por categoria esportiva —
-- mesmo mecanismo de Bloco já reaproveitado no SubMundo Internet de
-- Tecnologia (migrations/072). "Copa do Mundo" é o primeiro SubMundo
-- com curadoria completa; os demais 8 entram em migrations futuras
-- conforme Rhoney confirmar cada um pronto.
--
-- Diferente do SubMundo Internet (trilha por dificuldade 1-4), este
-- Mundo não tem níveis de dificuldade (doc §2): difficulty_level
-- sempre 1, mesmo padrão "flat" já usado em Oceanos/Espaço/Gastronomia.
-- Cada bloco curado (Mundo_dos_Esportes/Copa_do_Mundo/
-- mundo_esportes_copadomundo_bloco*_desafio*.json) é 1 território
-- inteiro — os 5 desafios dentro do bloco não viram territórios
-- separados, só agrupam as 25 perguntas na curadoria bruta.

insert into mental.blocks (id, name, display_order) values
    ('copa_do_mundo', 'Copa do Mundo', 16)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('copa_mundo_primeiras_copas', 'copa_do_mundo', true, 2, 78, 'esportes', 'copa_do_mundo'),
    ('copa_mundo_expansao', 'copa_do_mundo', true, 2, 79, 'esportes', 'copa_do_mundo'),
    ('copa_mundo_era_moderna', 'copa_do_mundo', true, 2, 80, 'esportes', 'copa_do_mundo'),
    ('copa_mundo_curiosidades', 'copa_do_mundo', true, 2, 81, 'esportes', 'copa_do_mundo')
on conflict (id) do nothing;

-- Conteúdo em si é carregado DEPOIS desta migração, via
-- scripts/append_production_content.py (mesmo padrão de todos os
-- Mundos anteriores), a partir de backend/content/copa_mundo_*.json
-- (gerados por scripts/convert_esportes_content.py). 100 desafios em 4
-- territórios, 0 excluídos — curadoria completa em 14/09/2026.
