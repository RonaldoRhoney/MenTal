-- ORGANIZACAO_VISUAL_POR_SECAO_TODOS_MUNDOS_V1.md (19/09/2026, aprovado
-- por Rhoney): levantamento confirmou que o Mundo dos Idiomas é o único
-- Mundo com territórios sem block_id misturados numa mesma grade —
-- Libras, Internet (em Tecnologia) e Futebol/Copa do Mundo (em
-- Esportes) já usam o mecanismo de Bloco (BLOCOS_MENUS.md,
-- migrations/020_blocks.sql), Inglês/Espanhol/Francês nunca tinham
-- ganhado o próprio block_id. Mesmo padrão já usado em
-- migrations/072/074/076 (SubMundo = Bloco, sem entidade nova).
-- Puramente organizacional/visual — não altera progresso, XP nem
-- navegação, só agrupamento de exibição.

insert into mental.blocks (id, name, display_order) values
    ('ingles', 'Inglês', 18),
    ('espanhol', 'Espanhol', 19),
    ('frances', 'Francês', 20)
on conflict (id) do nothing;

update mental.territories set block_id = 'ingles' where id in ('ingles_basico', 'ingles_intermediario', 'ingles_avancado');
update mental.territories set block_id = 'espanhol' where id in ('espanhol_basico', 'espanhol_intermediario', 'espanhol_avancado');
update mental.territories set block_id = 'frances' where id in ('frances_basico', 'frances_intermediario', 'frances_avancado');
