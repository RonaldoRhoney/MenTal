-- Pedido de Rhoney (10/10/2026), reunindo 3 achados da auditoria de
-- segurança/consistência de conteúdo pré-AAB (09/10/2026):
--
-- 1) Conteúdo morto (achado 3.1 de mental-content-consistency): os 45
--    Desafios do formato antigo "Complete a frase" em
--    ingles_parperfeito_{basico,intermediario,avancado} ficaram órfãos
--    desde que esses territory_ids passaram a rotear SEMPRE pra
--    ParPerfeitoScreen (formato "Pares de cards", tabela própria
--    par_perfeito_items — nunca mais Challenge). Remove só o que nunca
--    foi respondido por nenhum testador real; o que já tem Attempt
--    fica (histórico real nunca é apagado por limpeza de conteúdo).
--
-- 2) A2 (CRÍTICO, auditoria de segurança): par_perfeito_matches não
--    tinha UNIQUE (user_id, item_id) — nada no banco impedia duas
--    linhas pro mesmo par, só a checagem em Python antes do insert
--    (corrida possível). Tabela par_perfeito_rounds é nova (ver
--    app/models.py ParPerfeitoRound) — registra a rodada no servidor
--    pra POST /complete-round só aceitar item_ids de uma rodada real
--    (fecha o harvesting de ids via várias chamadas de GET /round).
--
-- 3) A3 (ALTO, LGPD — 4ª recorrência do mesmo padrão, já visto em
--    048/071/077/082/085): par_perfeito_matches.user_id sem FK pra
--    auth.users — excluir a conta deixava o histórico órfão pra
--    sempre. Mesmo padrão: remove órfãos primeiro (contas já
--    excluídas — exatamente o que a LGPD manda apagar), depois FK com
--    ON DELETE CASCADE.

-- --- 1) conteúdo morto ------------------------------------------------

delete from mental.challenge_hints
where challenge_id in (
    select id from mental.challenges
    where territory_id in ('ingles_parperfeito_basico', 'ingles_parperfeito_intermediario', 'ingles_parperfeito_avancado')
      and id not in (select distinct challenge_id from mental.attempts)
);

delete from mental.challenges
where territory_id in ('ingles_parperfeito_basico', 'ingles_parperfeito_intermediario', 'ingles_parperfeito_avancado')
  and id not in (select distinct challenge_id from mental.attempts);

-- --- 2) A2: registro de rodada + unicidade real no banco --------------

create table if not exists mental.par_perfeito_rounds (
    id uuid primary key,
    user_id uuid not null,
    territory_id varchar not null references mental.territories(id),
    item_ids jsonb not null,
    issued_at timestamp not null default now()
);

create index if not exists ix_par_perfeito_rounds_user_territory
    on mental.par_perfeito_rounds (user_id, territory_id, issued_at desc);

delete from mental.par_perfeito_matches a
where a.id not in (
    select min(b.id) from mental.par_perfeito_matches b
    group by b.user_id, b.item_id
);

alter table mental.par_perfeito_matches
    add constraint par_perfeito_matches_user_item_unique
    unique (user_id, item_id);

-- --- 3) A3: FK com cascade pra auth.users ------------------------------

delete from mental.par_perfeito_matches
where user_id not in (select id from auth.users);

alter table mental.par_perfeito_matches
    add constraint par_perfeito_matches_user_id_fkey
    foreign key (user_id) references auth.users(id) on delete cascade;
