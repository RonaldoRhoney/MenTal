-- MENTAL — corrige a cascata de exclusão de conta (LGPD, achado de
-- auditoria de segurança 01/09/2026). services.delete_account() delega
-- a exclusão real ao Supabase Auth (delete_auth_user) assumindo que
-- TODAS as tabelas mental.* cascateiam a partir de auth.users — na
-- prática:
--
--   1) mental.movement_cycles.user_id, mental.friendships.user_id_a/b
--      e mental.movement_snapshots.cycle_id referenciam a tabela errada
--      pra cascata completa (mental.profiles / mental.movement_cycles)
--      com NO ACTION em vez de CASCADE — apagar auth.users cascateia
--      até mental.profiles e ESTOURA ali, porque essas 3 ainda
--      referenciam o profile que está sendo apagado. Qualquer conta que
--      já tenha ativado Movimento ou tenha um amigo não consegue se
--      excluir (DELETE /profile responde 502).
--   2) mental.battles, mental.challenge_batch_progress e
--      mental.word_puzzle_results não têm FK nenhuma pra auth.users —
--      settadas com CASCADE aqui (0 linhas órfãs confirmadas antes
--      desta migration; nenhuma tem texto livre nem valor analítico que
--      justifique preservar o vínculo).
--   3) mental.app_feedback e mental.level_feedback também não têm FK
--      nenhuma — mas guardam texto livre com valor duradouro (mural
--      público com resposta do admin; insumo de calibração de
--      dificuldade de conteúdo) — decisão de produto (Rhoney,
--      01/09/2026): ANONIMIZAR (user_id -> NULL) em vez de apagar,
--      preservando comment/admin_reply/difficulty_rating. Exige tornar
--      user_id nullable antes de criar a FK com ON DELETE SET NULL.
--      schemas.py (PublicAppFeedbackItem/AdminLevelFeedbackItem) e os
--      routers correspondentes já foram ajustados pra tolerar
--      user_id=None nessas duas tabelas.
--
-- Checagem feita ANTES de escrever esta migration: 0 linhas órfãs em
-- todas as 5 tabelas do item 2/3 (nenhum user_id sem auth.users
-- correspondente) — as novas constraints podem ser criadas direto.
-- Rodar no SQL Editor do projeto Supabase.

-- 1) NO ACTION -> CASCADE (causa raiz do travamento hoje).
alter table mental.movement_cycles drop constraint movement_cycles_user_id_fkey;
alter table mental.movement_cycles add constraint movement_cycles_user_id_fkey
    foreign key (user_id) references mental.profiles(user_id) on delete cascade;

alter table mental.friendships drop constraint friendships_user_id_a_fkey;
alter table mental.friendships add constraint friendships_user_id_a_fkey
    foreign key (user_id_a) references mental.profiles(user_id) on delete cascade;

alter table mental.friendships drop constraint friendships_user_id_b_fkey;
alter table mental.friendships add constraint friendships_user_id_b_fkey
    foreign key (user_id_b) references mental.profiles(user_id) on delete cascade;

alter table mental.movement_snapshots drop constraint movement_snapshots_cycle_id_fkey;
alter table mental.movement_snapshots add constraint movement_snapshots_cycle_id_fkey
    foreign key (cycle_id) references mental.movement_cycles(id) on delete cascade;

-- 2) FK nova com CASCADE — metadado técnico/gameplay sem texto livre.
alter table mental.battles
    add constraint battles_challenger_user_id_fkey foreign key (challenger_user_id) references auth.users(id) on delete cascade,
    add constraint battles_opponent_user_id_fkey foreign key (opponent_user_id) references auth.users(id) on delete cascade,
    add constraint battles_winner_user_id_fkey foreign key (winner_user_id) references auth.users(id) on delete cascade;

alter table mental.challenge_batch_progress
    add constraint challenge_batch_progress_user_id_fkey foreign key (user_id) references auth.users(id) on delete cascade;

alter table mental.word_puzzle_results
    add constraint word_puzzle_results_user_id_fkey foreign key (user_id) references auth.users(id) on delete cascade;

-- 3) FK nova com SET NULL — anonimiza em vez de apagar (texto livre com
--    valor duradouro).
alter table mental.app_feedback alter column user_id drop not null;
alter table mental.app_feedback
    add constraint app_feedback_user_id_fkey foreign key (user_id) references auth.users(id) on delete set null;

alter table mental.level_feedback alter column user_id drop not null;
alter table mental.level_feedback
    add constraint level_feedback_user_id_fkey foreign key (user_id) references auth.users(id) on delete set null;
