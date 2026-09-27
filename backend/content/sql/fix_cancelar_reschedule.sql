-- Correção pontual: o Sentinela sinalizou "Como se escreve 'cancelar' em inglês?" (resposta
-- 'Cancel') porque a resposta está contida no próprio enunciado ('cancelar' contém 'cancel').
-- Troca por 'reagendar' -> 'Reschedule', mesmo tema (Clima e planos), sem colisão com o resto
-- do vocabulário. Idempotente por (territory_id, prompt) igual às demais cargas.
begin;
update mental.challenges
set prompt = $q$Como se escreve 'reagendar' em inglês?$q$,
    options = $q$["Reschedule", "Reeschedule", "Rescedule", "Reschedul"]$q$::jsonb,
    correct_answer = $q$Reschedule$q$,
    explanation = $q$'reagendar' se traduz como 'Reschedule' em inglês.$q$
where territory_id = 'ingles_intermediario'
  and prompt = $q$Como se escreve 'cancelar' em inglês?$q$;

update mental.challenge_hints h
set content = 'Começa com ''R''.'
from mental.challenges c
where h.challenge_id = c.id
  and c.territory_id = 'ingles_intermediario'
  and c.prompt = $q$Como se escreve 'reagendar' em inglês?$q$
  and h.hint_level = 2;
commit;
