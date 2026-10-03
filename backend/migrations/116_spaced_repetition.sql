-- Mundo dos Idiomas: Sistema de Repetição Espaçada
-- (MUNDO_IDIOMAS_REPETICAO_ESPACADA_V1.md, Prioridade 1 das lacunas do
-- Inglês, 29/09/2026). Agnóstico a Mundo/território desde o início
-- (doc §4) — a chave é challenge_id, nunca hardcoded pra Inglês/Idiomas;
-- territory_id é só desnormalizado pra filtrar/relatar sem join.
--
-- Algoritmo deliberadamente simplificado (Leitner-like, schedule fixo
-- crescente), não o SM-2 completo do Anki com fator de facilidade por
-- item — doc §4 pede pra avaliar a complexidade adequada ao estágio
-- atual do MENTAL; ver app/services.py::update_spaced_repetition.
--
-- Escopo desta entrega: backend completo (modelo + algoritmo + endpoint
-- de itens vencidos). Seção "Revisão" no client e a recompensa de
-- sessão de revisão (doc §5, exige formalização prévia da Regra Oficial
-- de Gamificação) ficam para depois.

create table if not exists mental.spaced_repetition_items (
    user_id uuid not null references auth.users(id) on delete cascade,
    challenge_id uuid not null references mental.challenges(id) on delete cascade,
    territory_id text not null references mental.territories(id),
    repetitions integer not null default 0,
    interval_days integer not null default 1,
    last_reviewed_at timestamp not null default now(),
    next_due_at timestamp not null default now(),
    created_at timestamp not null default now(),
    primary key (user_id, challenge_id)
);

-- Consulta principal (GET /challenges/review/next): itens vencidos de
-- UM usuário, ordenados pelo mais atrasado primeiro.
create index if not exists idx_spaced_repetition_due on mental.spaced_repetition_items (user_id, next_due_at);

-- Achado CRÍTICO da auditoria de segurança (02/10/2026): sem esta
-- marca, GET /challenges/review/next servia was_last_of_batch=True sem
-- distinção, e rewards.on_batch_completed paga o bônus de lote (+3 XP)
-- por attempt_id — cada chamada ao endpoint criava um Attempt novo pro
-- MESMO item vencido, virando farm de XP ilimitado. on_batch_completed
-- agora exclui attempts marcados assim do bônus, mesmo tratamento já
-- dado a is_search.
alter table mental.attempts add column if not exists is_spaced_review boolean not null default false;
