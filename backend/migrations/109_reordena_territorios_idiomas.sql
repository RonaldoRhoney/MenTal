-- Corrige a ordem de exibição do Mundo dos Idiomas (achado de Rhoney, 28/09/2026:
-- "conteúdo do Mundo dos Idiomas confuso, quero que apareçam em sequência como se
-- estivessem dentro de pastas"). Causa raiz: o agrupamento visual por Bloco
-- (client._territoryGroups) junta territórios CONSECUTIVOS do mesmo block_id num
-- único cartão de seção; os territórios de Phrasal Verbs tinham display_order
-- 119-124, bem longe de Inglês (40-42), então mesmo estando no mesmo bloco
-- "ingles" (migration 108), apareciam numa seção separada, com Espanhol e
-- Francês intercalados no meio. Esta migration move Phrasal Verbs pra logo
-- depois do vocabulário de Inglês (43-48) e empurra Espanhol/Francês pra
-- 49-54, sem conflito com nenhum outro território do Mundo dos Idiomas.
-- (A correção da consulta que faltava ORDER BY display_order é só no código
-- do backend — services.get_worlds_progress/get_blocks — não precisa de SQL.)

update mental.territories set display_order = 43 where id = 'ingles_phrasal_basico';
update mental.territories set display_order = 44 where id = 'ingles_phrasal_intermediario';
update mental.territories set display_order = 45 where id = 'ingles_phrasal_avancado';
update mental.territories set display_order = 46 where id = 'ingles_phrasal_relampago_basico';
update mental.territories set display_order = 47 where id = 'ingles_phrasal_relampago_intermediario';
update mental.territories set display_order = 48 where id = 'ingles_phrasal_relampago_avancado';
update mental.territories set display_order = 49 where id = 'espanhol_basico';
update mental.territories set display_order = 50 where id = 'espanhol_intermediario';
update mental.territories set display_order = 51 where id = 'espanhol_avancado';
update mental.territories set display_order = 52 where id = 'frances_basico';
update mental.territories set display_order = 53 where id = 'frances_intermediario';
update mental.territories set display_order = 54 where id = 'frances_avancado';
