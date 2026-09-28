-- Corrige a arquitetura de blocos do Mundo dos Idiomas (pedido de Rhoney,
-- 27/09/2026): "Phrasal Verbs não é um idioma novo, é conteúdo do Inglês.
-- Os idiomas são: Inglês, Espanhol e Francês. Dentro do Mundo dos Idiomas
-- crie Submundos e em cada submundo um idioma, e dentro de cada idioma os
-- seus respectivos conteúdos."
--
-- A migration 107 criou um bloco "phrasal_verbs" separado (decisão
-- revisada no mesmo dia). Esta migration desfaz isso: move os 6
-- territórios de Phrasal Verbs pro bloco "ingles" (mesmo SubMundo do
-- vocabulário de Inglês) e remove o bloco "phrasal_verbs", que não deve
-- mais existir.

update mental.territories
   set block_id = 'ingles'
 where id in (
    'ingles_phrasal_basico',
    'ingles_phrasal_intermediario',
    'ingles_phrasal_avancado',
    'ingles_phrasal_relampago_basico',
    'ingles_phrasal_relampago_intermediario',
    'ingles_phrasal_relampago_avancado'
 );

delete from mental.blocks where id = 'phrasal_verbs';
