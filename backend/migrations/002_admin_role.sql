-- MENTAL — role de admin + auto-promoção de rhoneyinc@gmail.com
-- Padrão RhoneyInc (skill admin-padrao): rhoneyinc@gmail.com é sempre
-- admin, promovido automaticamente — nunca por passo manual.
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 001_initial_schema.sql.

alter table mental.profiles
    add column if not exists role text not null default 'user'
    check (role in ('user', 'admin'));

-- Trigger em auth.users: toda vez que uma conta nova é criada no Supabase
-- Auth, cria (ou atualiza) a linha correspondente em mental.profiles,
-- promovendo automaticamente a rhoneyinc@gmail.com a admin. O nickname
-- aqui é só um placeholder — o fluxo real de onboarding (POST /age-gate)
-- sobrescreve com o nickname definitivo (gerado ou escolhido pelo
-- usuário), sem conflito, porque só atualiza a linha já existente.
create or replace function mental.handle_new_mental_user()
returns trigger
language plpgsql
security definer
set search_path = mental, public
as $$
begin
    insert into mental.profiles (user_id, nickname, nickname_is_system_generated, role)
    values (
        new.id,
        'Jogador-' || substr(new.id::text, 1, 8),
        true,
        case when new.email = 'rhoneyinc@gmail.com' then 'admin' else 'user' end
    )
    on conflict (user_id) do nothing;
    return new;
end;
$$;

drop trigger if exists on_auth_user_created_mental on auth.users;

create trigger on_auth_user_created_mental
    after insert on auth.users
    for each row execute function mental.handle_new_mental_user();

-- Fallback retroativo (padrão da skill admin-padrao): se
-- rhoneyinc@gmail.com já tiver se cadastrado ANTES desta migration rodar,
-- promove manualmente aqui. Idempotente — não faz nada se a conta ainda
-- não existir ou já estiver correta.
update mental.profiles
set role = 'admin'
where user_id in (select id from auth.users where email = 'rhoneyinc@gmail.com')
  and role <> 'admin';
