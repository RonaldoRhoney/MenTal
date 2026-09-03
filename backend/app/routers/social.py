import secrets

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import mentalcoins, models, schemas, services
from ..auth import get_current_user_id, require_age_confirmed_user_id
from ..db import get_db

router = APIRouter()


@router.get("/social/invite-code")
def get_invite_code(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    invite = db.execute(select(models.Invite).where(models.Invite.inviter_user_id == user_id)).scalars().first()
    if invite is None:
        invite = models.Invite(inviter_user_id=user_id, invite_code=secrets.token_urlsafe(6))
        db.add(invite)
        db.commit()
        db.refresh(invite)
    return {"invite_code": invite.invite_code}


@router.post("/social/invite-conversions")
def register_conversion(invite_code: str, user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    invite = db.execute(select(models.Invite).where(models.Invite.invite_code == invite_code)).scalars().first()
    if invite is None:
        return {"registered": False}

    existing = db.execute(select(models.InviteConversion).where(models.InviteConversion.invited_user_id == user_id)).scalars().first()
    if existing is not None:
        return {"registered": True, "already_registered": True}

    conversion = models.InviteConversion(invite_id=invite.id, invited_user_id=user_id)
    db.add(conversion)
    db.commit()
    return {"registered": True}


@router.post("/social/achievement-card")
def generate_achievement_card(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    """
    STUB no Vertical Slice 01 — geração real de imagem (server-side vs.
    client-side) é decisão de implementação pendente (MENTAL_KICKOFF.md
    §6: "Claude Code deve propor a abordagem mais simples e de menor custo
    de manutenção antes de implementar"), fora do escopo travado para este
    slice (só os 4 tipos de desafio + loop completo). Endpoint existe para
    não quebrar o contrato, retorna os dados que alimentariam o card.
    """
    profile = db.get(models.Profile, user_id)
    return {
        "nickname": profile.nickname if profile else None,
        "xp_total": profile.xp_total if profile else 0,
        "level": profile.level if profile else 1,
        "image_url": None,
        "note": "geração de imagem não implementada no Vertical Slice 01",
    }


# V2 item 12 — Amigos (V2_KICKOFF.md §6A, aprovado 2026-08-22). Usa o
# MESMO invite_code de /social/invite-code como ponto de entrada —
# nenhuma tela nova de convite. Deliberadamente NÃO reaproveita
# InviteConversion (1 atribuição por usuário, pensado pra métrica de
# crescimento) — grava em mental.friendships, N:N de verdade.
#
# Achado de auditoria de segurança (28/08/2026): resgatar o código
# criava a amizade DIRETO — o dono do invite_code nunca era consultado,
# e um estranho com o código (compartilhado publicamente, por exemplo)
# passava a ver o user_id/nome real/foto/XP do dono automaticamente.
# Agora isso só cria um PEDIDO pendente (services.request_friendship);
# vira amizade de verdade só quando o dono aceita explicitamente via
# POST /social/friend-requests/{id}/accept.
@router.post("/social/friends")
def add_friend(
    body: schemas.AddFriendRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    invite = db.execute(select(models.Invite).where(models.Invite.invite_code == body.invite_code)).scalars().first()
    if invite is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "INVITE_NOT_FOUND", "message": "Código de convite não encontrado."}})
    if invite.inviter_user_id == user_id:
        raise HTTPException(status_code=400, detail={"error": {"code": "CANNOT_FRIEND_SELF", "message": "Não é possível adicionar a si mesmo como amigo."}})

    services.request_friendship(db, user_id, invite.inviter_user_id)
    return {"status": "pending"}


# AMIGOS_CONVITE_POR_NOME.md §1/§3 — envia convite direto a partir de um
# resultado de busca por nome (o convite por código continua sendo o
# caminho pra quem ainda nem tem o app). Idempotente/sem vazamento: se
# já existe pedido, já são amigos, ou um bloqueou o outro,
# request_friendship retorna None silenciosamente e a resposta é a
# mesma — o requisitante nunca descobre por essa via se foi bloqueado.
@router.post("/social/friend-requests")
def send_friend_request(
    body: schemas.SendFriendRequestRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    if body.to_user_id == user_id:
        raise HTTPException(status_code=400, detail={"error": {"code": "CANNOT_FRIEND_SELF", "message": "Não é possível adicionar a si mesmo como amigo."}})
    target = db.get(models.Profile, body.to_user_id)
    if target is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "USER_NOT_FOUND", "message": "Usuário não encontrado."}})
    services.request_friendship(db, user_id, body.to_user_id)
    return {"status": "pending"}


@router.get("/social/friend-requests", response_model=schemas.FriendRequestsResponse)
def list_friend_requests(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    pending = services.list_pending_friend_requests(db, user_id)
    requests = []
    for friendship, from_user_id in pending:
        from_profile = db.get(models.Profile, from_user_id)
        requests.append(
            schemas.FriendRequestOut(
                friendship_id=friendship.id,
                from_user_id=from_user_id,
                from_nickname=from_profile.nickname if from_profile else "???",
            )
        )
    return schemas.FriendRequestsResponse(requests=requests)


@router.post("/social/friend-requests/{friendship_id}/accept")
def accept_friend_request(
    friendship_id: str,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    friendship = services.accept_friend_request(db, friendship_id, user_id)
    if friendship is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "FRIEND_REQUEST_NOT_FOUND", "message": friendship_id}})
    return {"status": "accepted"}


@router.post("/social/friend-requests/{friendship_id}/decline")
def decline_friend_request(
    friendship_id: str,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    ok = services.decline_friend_request(db, friendship_id, user_id)
    if not ok:
        raise HTTPException(status_code=404, detail={"error": {"code": "FRIEND_REQUEST_NOT_FOUND", "message": friendship_id}})
    return {"status": "declined"}


@router.get("/social/friends", response_model=schemas.FriendsResponse)
def list_friends(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    friend_ids = services.get_friend_user_ids(db, user_id)
    friends = []
    for friend_id in friend_ids:
        profile = db.get(models.Profile, friend_id)
        if profile is None:
            continue
        friends.append(
            schemas.FriendOut(
                user_id=friend_id,
                nickname=profile.nickname,
                avatar_id=profile.avatar_id,
                real_name=profile.real_name,
                photo_url=services.public_photo_url(profile),
                xp_total=profile.xp_total,
                level=profile.level,
            )
        )
    return schemas.FriendsResponse(friends=friends)


# AMIGOS_CONVITE_POR_NOME.md — busca de amigos por nome, complementando
# o convite por código já existente (não o substitui — código funciona
# fora do app, nome só ajuda quem já está nele). Escopada estritamente
# ao fluxo de convite (§2 do doc): devolve só nome+foto+nível, nunca
# abre o perfil público completo a partir daqui.
@router.get("/social/users/search", response_model=schemas.UserSearchResponse)
def search_users(
    q: str,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    query = q.strip()
    if len(query) < 3:
        return schemas.UserSearchResponse(results=[])
    profiles = services.search_users_by_name(db, query, user_id)
    results = [
        schemas.UserSearchResultOut(
            user_id=profile.user_id,
            nickname=profile.nickname,
            real_name=profile.real_name,
            photo_url=services.public_photo_url(profile),
            level=profile.level,
            friendship_status=services.friendship_status_between(db, user_id, profile.user_id),
        )
        for profile in profiles
    ]
    return schemas.UserSearchResponse(results=results)


# Pedido de Rhoney (2026-08-22): compartilhar uma conquista (nível,
# território, mundo, badge, meta de passos) rende XP. Backend é a única
# autoridade — client nunca calcula nem decide o valor, só avisa "um
# compartilhamento aconteceu". Teto de 1 recompensa/dia (services.
# award_share_reward) é a defesa contra farm, já que o app não confirma
# conclusão real do compartilhamento no SO.
@router.post("/social/share-reward", response_model=schemas.ShareRewardResponse)
def reward_share(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    profile = db.get(models.Profile, user_id)
    if profile is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "PROFILE_NOT_FOUND", "message": "Perfil não encontrado."}})

    xp_awarded, already_rewarded_today = services.award_share_reward(db, profile)
    return schemas.ShareRewardResponse(
        xp_awarded=xp_awarded,
        already_rewarded_today=already_rewarded_today,
        xp_total=profile.xp_total,
        level=profile.level,
    )


# Pedido de Rhoney: o botão de convidar amigos (ao lado do wordmark
# MENTAL) rende XP + MentalCoins — recompensa e teto diário PRÓPRIOS,
# distintos de /social/share-reward acima (compartilhar conquista).
@router.post("/social/share-app-reward", response_model=schemas.AppInviteShareRewardResponse)
def reward_app_invite_share(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    profile = db.get(models.Profile, user_id)
    if profile is None:
        raise HTTPException(status_code=404, detail={"error": {"code": "PROFILE_NOT_FOUND", "message": "Perfil não encontrado."}})

    xp_before = profile.xp_total
    coins_before = mentalcoins.get_or_create_balance(db, user_id).balance
    xp_awarded, mentalcoins_awarded, already_rewarded_today = services.award_app_invite_reward(db, profile)
    balance = mentalcoins.get_or_create_balance(db, user_id)
    coin_milestone_reached = services.crossed_coin_milestone(xp_before, profile.xp_total, coins_before, balance.balance)
    return schemas.AppInviteShareRewardResponse(
        xp_awarded=xp_awarded,
        mentalcoins_awarded=mentalcoins_awarded,
        already_rewarded_today=already_rewarded_today,
        xp_total=profile.xp_total,
        level=profile.level,
        mentalcoins_balance=balance.balance,
        coin_milestone_reached=coin_milestone_reached,
    )


# Achado de auditoria de segurança (28/08/2026) — DIR-001 §4/POL-003
# §2.4 exigem um canal de denúncia pra conteúdo já aprovado (foto/nome)
# que se revele impróprio depois. Puramente reativo: só registra, não
# esconde nada sozinho — um admin decide via GET /admin/reports +
# POST /admin/profile-photos/{id}/moderate (endpoint já existente).
@router.post("/social/report")
def report_user(
    body: schemas.ReportUserRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    if body.reported_user_id == user_id:
        raise HTTPException(status_code=400, detail={"error": {"code": "CANNOT_REPORT_SELF", "message": "Não é possível se autodenunciar."}})
    services.create_report(db, reporter_user_id=user_id, reported_user_id=body.reported_user_id, reason=body.reason)
    return {"status": "reported"}


# Achado de auditoria de conformidade Google Play (29/08/2026, item 6):
# a denúncia já existia, mas não havia como impedir que a mesma pessoa
# continuasse mandando pedido de amizade depois de denunciada/recusada.
# Bloquear é a ação complementar — services.is_blocked_either_way passa
# a ser checado em qualquer novo pedido de amizade.
@router.post("/social/block")
def block_user(
    body: schemas.BlockUserRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    if body.blocked_user_id == user_id:
        raise HTTPException(status_code=400, detail={"error": {"code": "CANNOT_BLOCK_SELF", "message": "Não é possível bloquear a si mesmo."}})
    services.block_user(db, user_id, body.blocked_user_id)
    return {"status": "blocked"}


@router.post("/social/unblock")
def unblock_user(
    body: schemas.BlockUserRequest,
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    services.unblock_user(db, user_id, body.blocked_user_id)
    return {"status": "unblocked"}


@router.get("/social/blocked", response_model=schemas.BlockedUsersResponse)
def list_blocked_users(user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    blocked = []
    for blocked_user_id in services.list_blocked_user_ids(db, user_id):
        profile = db.get(models.Profile, blocked_user_id)
        if profile is None:
            continue
        blocked.append(
            schemas.BlockedUserOut(
                user_id=blocked_user_id,
                nickname=profile.nickname,
                real_name=profile.real_name,
                photo_url=services.public_photo_url(profile),
            )
        )
    return schemas.BlockedUsersResponse(blocked=blocked)


@router.get("/admin/reports", response_model=list[schemas.AdminReportItem])
def list_reports(user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    admin_profile = db.get(models.Profile, user_id)
    if admin_profile is None or admin_profile.role != "admin":
        raise HTTPException(status_code=403, detail={"error": {"code": "ADMIN_ONLY", "message": "Restricted to admin accounts"}})

    reports = services.list_unresolved_reports(db)
    out = []
    for report in reports:
        reported_profile = db.get(models.Profile, report.reported_user_id)
        out.append(
            schemas.AdminReportItem(
                id=report.id,
                reporter_user_id=report.reporter_user_id,
                reported_user_id=report.reported_user_id,
                reported_nickname=reported_profile.nickname if reported_profile else "???",
                reported_photo_url=services.own_photo_url(reported_profile) if reported_profile else None,
                reason=report.reason,
                created_at=report.created_at,
            )
        )
    return out
