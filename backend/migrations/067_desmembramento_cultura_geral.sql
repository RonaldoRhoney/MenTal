-- DESMEMBRAMENTO_CULTURA_GERAL_V1.md (07/09/2026, aprovado) — Mundo da
-- Cultura Geral desmembrado em Mundos temáticos dedicados. Pura
-- reorganização de agrupamento: nenhum desafio é alterado/removido,
-- nenhum XP/progresso é afetado ("mundo completo" é sempre derivado de
-- UserTerritoryProgress, nunca armazenado). Libras migra pra Mundo dos
-- Idiomas e Finanças Pessoais pra Mundo dos Valores — Mundos já
-- existentes que combinam melhor com eles.

insert into mental.worlds (id, name, display_order) values
    ('esportes', 'Mundo dos Esportes', 8),
    ('mitologia', 'Mundo da Mitologia', 9),
    ('enem', 'Mundo do ENEM', 10),
    ('concursos', 'Mundo dos Concursos', 11),
    ('tecnologia', 'Mundo da Tecnologia', 12),
    ('regioes_brasil', 'Mundo das Regiões do Brasil', 13)
on conflict (id) do nothing;

update mental.territories set world_id = 'esportes' where id = 'esportes';
update mental.territories set world_id = 'regioes_brasil' where id = 'regioes';
update mental.territories set world_id = 'mitologia' where id in ('mitologia_grega', 'mitologia_nordica', 'mitologia_indigena');
update mental.territories set world_id = 'enem' where id in ('enem_linguagens', 'enem_humanas', 'enem_natureza', 'enem_matematica');
update mental.territories set world_id = 'concursos' where id in ('concursos_portugues', 'concursos_raciocinio', 'concursos_direito');
update mental.territories set world_id = 'tecnologia' where id in ('tecnologia_fundamentos', 'tecnologia_programacao', 'tecnologia_seguranca', 'tecnologia_fronteira');
update mental.territories set world_id = 'idiomas' where id = 'libras';
update mental.territories set world_id = 'valores' where id = 'financas_pessoais';
