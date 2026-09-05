-- Pedido de Rhoney (05/09/2026): convite pontual pra ligar o Movimento,
-- na mesma área do Perfil Público onde já existe Torcida — botão "GO"
-- em quem convida, notificação push com deep link pra tela de
-- Movimento em quem recebe. Mesmo padrão de torcida_reactions (uma
-- linha por envio, limite diário calculado por COUNT em tempo real).

create table if not exists mental.movement_invites (
    id uuid primary key default gen_random_uuid(),
    from_user_id uuid not null,
    to_user_id uuid not null,
    created_at timestamptz not null default now()
);

create index if not exists idx_movement_invites_to_user_created_at
    on mental.movement_invites (to_user_id, from_user_id, created_at);
