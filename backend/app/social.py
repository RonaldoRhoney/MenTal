"""
Achado de auditoria de qualidade B4 (05/09/2026): extraído de
services.py (1548 linhas, muitas responsabilidades) — mesmo espírito
já usado pra movement.py/mentalcoins.py. Cobre amizade e bloqueio entre
usuários: pedido/aceite/recusa de amizade, busca por nome, e bloqueio
(que precisa valer pra amizade, perfil público, Torcida e convite de
Movimento — ver services.is_blocked_either_way, ainda re-exportado de
lá pra services.py, que é quem o resto do backend importa).

Nenhuma função aqui depende de outra função de services.py — só de
`models` e SQLAlchemy — extração sem risco de import circular.
"""

from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from . import models


def _canonical_pair(user_id_1: str, user_id_2: str) -> tuple[str, str]:
    return (user_id_1, user_id_2) if user_id_1 < user_id_2 else (user_id_2, user_id_1)


def is_blocked_either_way(db: Session, user_a: str, user_b: str) -> bool:
    """
    Achado de auditoria de conformidade Google Play (29/08/2026, item
    6): qualquer bloqueio em qualquer direção impede novo contato — não
    importa se foi A que bloqueou B ou o contrário, nenhum dos dois
    lados deve conseguir iniciar/reativar um pedido de amizade.
    """
    return (
        db.execute(
            select(models.UserBlock).where(
                or_(
                    and_(models.UserBlock.blocker_user_id == user_a, models.UserBlock.blocked_user_id == user_b),
                    and_(models.UserBlock.blocker_user_id == user_b, models.UserBlock.blocked_user_id == user_a),
                )
            )
        ).scalar_one_or_none()
        is not None
    )


def block_user(db: Session, blocker_user_id: str, blocked_user_id: str) -> models.UserBlock:
    """
    Idempotente (retorna o bloqueio já existente em vez de duplicar).
    Também encerra qualquer amizade/pedido pendente já existente entre
    os dois — bloquear alguém não deveria deixar uma amizade "zumbi".
    """
    existing = db.execute(
        select(models.UserBlock).where(
            models.UserBlock.blocker_user_id == blocker_user_id,
            models.UserBlock.blocked_user_id == blocked_user_id,
        )
    ).scalar_one_or_none()
    if existing is not None:
        return existing

    block = models.UserBlock(blocker_user_id=blocker_user_id, blocked_user_id=blocked_user_id)
    db.add(block)

    a, b = _canonical_pair(blocker_user_id, blocked_user_id)
    friendship = db.execute(
        select(models.Friendship).where(models.Friendship.user_id_a == a, models.Friendship.user_id_b == b)
    ).scalar_one_or_none()
    if friendship is not None:
        db.delete(friendship)

    db.commit()
    db.refresh(block)
    return block


def unblock_user(db: Session, blocker_user_id: str, blocked_user_id: str) -> bool:
    existing = db.execute(
        select(models.UserBlock).where(
            models.UserBlock.blocker_user_id == blocker_user_id,
            models.UserBlock.blocked_user_id == blocked_user_id,
        )
    ).scalar_one_or_none()
    if existing is None:
        return False
    db.delete(existing)
    db.commit()
    return True


def list_blocked_user_ids(db: Session, blocker_user_id: str) -> list[str]:
    return list(
        db.execute(
            select(models.UserBlock.blocked_user_id).where(models.UserBlock.blocker_user_id == blocker_user_id)
        ).scalars().all()
    )


def request_friendship(db: Session, requester_id: str, other_user_id: str) -> models.Friendship | None:
    """
    Achado de auditoria de segurança (28/08/2026): resgatar um
    invite_code criava a amizade direto, sem o dono do código nunca ser
    consultado. Agora só cria um PEDIDO ('pending') — vira amizade de
    verdade só quando o outro lado aceita explicitamente
    (accept_friend_request). Idempotente: retorna None se já existe
    qualquer linha entre os dois (pending ou accepted), sem duplicar.

    Também retorna None se qualquer um dos dois bloqueou o outro
    (achado de auditoria de conformidade Google Play, 29/08/2026, item
    6) — mesmo retorno de "já existe"/self-friend, o router decide a
    mensagem certa a partir do contexto.
    """
    if is_blocked_either_way(db, requester_id, other_user_id):
        return None
    a, b = _canonical_pair(requester_id, other_user_id)
    existing = db.execute(
        select(models.Friendship).where(models.Friendship.user_id_a == a, models.Friendship.user_id_b == b)
    ).scalar_one_or_none()
    if existing is not None:
        return None
    friendship = models.Friendship(user_id_a=a, user_id_b=b, status="pending", requested_by=requester_id)
    db.add(friendship)
    db.commit()
    db.refresh(friendship)
    return friendship


def list_pending_friend_requests(db: Session, user_id: str) -> list[tuple[models.Friendship, str]]:
    """Pedidos pendentes onde `user_id` é quem PODE aceitar (nunca quem pediu)."""
    rows = db.execute(
        select(models.Friendship).where(
            models.Friendship.status == "pending",
            models.Friendship.requested_by != user_id,
            (models.Friendship.user_id_a == user_id) | (models.Friendship.user_id_b == user_id),
        )
    ).scalars().all()
    return [(f, f.user_id_b if f.user_id_a == user_id else f.user_id_a) for f in rows]


def accept_friend_request(db: Session, friendship_id: str, user_id: str) -> models.Friendship | None:
    """
    None se o pedido não existir, já não for mais 'pending', ou se
    `user_id` for quem pediu (só o OUTRO lado pode aceitar o próprio
    pedido — nunca o remetente).
    """
    friendship = db.get(models.Friendship, friendship_id)
    if friendship is None or friendship.status != "pending" or friendship.requested_by == user_id:
        return None
    if user_id not in (friendship.user_id_a, friendship.user_id_b):
        return None
    # Defesa em profundidade (29/08/2026, item 6 da auditoria): o pedido
    # pode ter sido feito ANTES de um bloqueio acontecer — nunca aceitar
    # um pedido de quem está bloqueado nesse meio-tempo.
    if is_blocked_either_way(db, friendship.user_id_a, friendship.user_id_b):
        return None
    friendship.status = "accepted"
    db.commit()
    db.refresh(friendship)
    return friendship


def decline_friend_request(db: Session, friendship_id: str, user_id: str) -> bool:
    friendship = db.get(models.Friendship, friendship_id)
    if friendship is None or friendship.status != "pending" or friendship.requested_by == user_id:
        return False
    if user_id not in (friendship.user_id_a, friendship.user_id_b):
        return False
    db.delete(friendship)
    db.commit()
    return True


def friendship_status_between(db: Session, user_a: str, user_b: str) -> str | None:
    """None|"pending"|"accepted" — usado pra UI decidir se ainda mostra o
    botão de convite ou já reflete o estado atual (AMIGOS_CONVITE_POR_NOME.md
    §5, resultado de busca deve dar o mesmo contexto que a lista de
    amigos já dá)."""
    a, b = _canonical_pair(user_a, user_b)
    friendship = db.execute(
        select(models.Friendship).where(models.Friendship.user_id_a == a, models.Friendship.user_id_b == b)
    ).scalar_one_or_none()
    return friendship.status if friendship is not None else None


def search_users_by_name(db: Session, query: str, requester_id: str, limit: int = 10) -> list[models.Profile]:
    """
    Busca por PREFIXO (AMIGOS_CONVITE_POR_NOME.md §5 — "comparação de
    prefixo simples, não full-text search pesado") em nickname OU
    real_name. Nunca retorna o próprio requester, nem ninguém bloqueado
    em qualquer direção (mesma regra de request_friendship) — busca por
    nome não deveria contornar um bloqueio já feito.
    """
    escaped = query.replace("\\", "\\\\").replace("%", r"\%").replace("_", r"\_")
    pattern = f"{escaped}%"
    blocked_ids = set(
        db.execute(
            select(models.UserBlock.blocked_user_id).where(models.UserBlock.blocker_user_id == requester_id)
        )
        .scalars()
        .all()
    ) | set(
        db.execute(
            select(models.UserBlock.blocker_user_id).where(models.UserBlock.blocked_user_id == requester_id)
        )
        .scalars()
        .all()
    )
    candidates = (
        db.execute(
            select(models.Profile)
            .where(
                or_(
                    models.Profile.nickname.ilike(pattern, escape="\\"),
                    models.Profile.real_name.ilike(pattern, escape="\\"),
                ),
                models.Profile.user_id != requester_id,
            )
            .order_by(models.Profile.nickname)
            .limit(limit + len(blocked_ids))
        )
        .scalars()
        .all()
    )
    return [p for p in candidates if p.user_id not in blocked_ids][:limit]


def get_friend_user_ids(db: Session, user_id: str) -> list[str]:
    rows = db.execute(
        select(models.Friendship).where(
            models.Friendship.status == "accepted",
            (models.Friendship.user_id_a == user_id) | (models.Friendship.user_id_b == user_id),
        )
    ).scalars().all()
    return [f.user_id_b if f.user_id_a == user_id else f.user_id_a for f in rows]
