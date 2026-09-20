-- Achado A1 da auditoria de 20/09/2026 (LGPD): word_constellation_completions
-- (079) guardava user_id sem FK — excluir a conta deixava o histórico órfão.
-- Mesmo padrão de 048/071/077/082: FK para auth.users com ON DELETE CASCADE.
-- Primeiro remove órfãos (contas já excluídas — é justamente o que a LGPD manda apagar).

delete from mental.word_constellation_completions
where user_id not in (select id from auth.users);

alter table mental.word_constellation_completions
    add constraint word_constellation_completions_user_id_fkey
    foreign key (user_id) references auth.users(id) on delete cascade;
