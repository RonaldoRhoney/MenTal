-- Mundo_da_Tecnologia/Internet/README.md — ARQUITETURA_SUBMUNDOS_V1.md
-- (13/09/2026, aprovado por Rhoney): "Internet" entra como SubMundo do
-- "Mundo da Tecnologia", não como Mundo próprio de primeiro nível —
-- Internet é taxonomicamente um subconjunto de Tecnologia. Implementado
-- reaproveitando o mecanismo de Bloco já existente (BLOCOS_MENUS.md,
-- migrations/020_blocks.sql): os 4 territórios "clássicos" de
-- Tecnologia já usam block_id='tecnologia'; um Bloco 'internet' novo
-- cria o subcabeçalho separado na tela do Mundo Tecnologia, sem
-- precisar de nenhuma entidade "SubMundo" nova nem mudança de schema
-- além da linha em mental.blocks (tabela já existe desde 020).
--
-- Diferente dos últimos Mundos (Oceanos, Espaço, Gastronomia —
-- "cápsula de texto + perguntas", difficulty_level sempre 1), este
-- volta ao padrão de trilha por dificuldade (1/2/3/4 — 1º conteúdo
-- curado a usar o 4º nível; content_validation.py atualizado na mesma
-- leva pra aceitar até 4, já que config.XP_BASE_BY_DIFFICULTY e
-- ADAPTIVE_DIFFICULTY_MAX_LEVEL já suportavam até 5). Cada bloco
-- curado (Mundo_da_Tecnologia/Internet/mundo_internet_bloco*_desafio*_
-- <nivel>.json) é 1 território inteiro — os desafios dentro do bloco
-- não viram territórios separados, só agrupam perguntas por
-- dificuldade.

insert into mental.blocks (id, name, display_order) values
    ('internet', 'Internet', 15)
on conflict (id) do nothing;

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order, world_id, block_id) values
    ('internet_origens', 'internet', true, 2, 73, 'tecnologia', 'internet'),
    ('internet_sistemas_operacionais', 'internet', true, 2, 74, 'tecnologia', 'internet')
on conflict (id) do nothing;

-- Conteúdo em si é carregado DEPOIS desta migração, via
-- scripts/append_production_content.py (mesmo padrão de todos os
-- Mundos anteriores), a partir de backend/content/internet_*.json
-- (gerados por scripts/convert_internet_content.py). Novos territórios
-- (novos blocos curados: hoje só origens/sistemas_operacionais estão
-- prontos — Os Gigantes da Internet, Cultura de Internet e Passado/
-- Presente/Futuro ainda têm desafios incompletos, ver
-- scripts/convert_internet_content.py BLOCO_TO_TERRITORY) entram em
-- migrações/rodadas incrementais futuras, conforme a curadoria avançar
-- e Rhoney confirmar cada bloco pronto.
