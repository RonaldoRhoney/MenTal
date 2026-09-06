"""
FEED_SOCIAL_V1.md — Feed de conquistas (piloto) + Seguir/Fã. Eventos
100% gerados pelo sistema no momento em que a condição é detectada
(§1: nunca texto livre do usuário) — reduz ao mínimo o risco de
moderação. "Seguir" é uma relação unilateral (§4), distinta de
Friendship (mútua).

Mesmo espírito de extração já usado em movement.py/mentalcoins.py/
social.py: nenhuma função aqui depende de services.py, só de
models/config/notification_copy e de social.py (pra bloqueio) —
reduz o tamanho de services.py em vez de crescer ainda mais nele
(achado de auditoria de qualidade B4, 05/09/2026).
"""

from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from . import config, models, notification_copy
from .social import get_blocked_user_ids_either_way, get_friend_user_ids, is_blocked_either_way


def create_feed_event(db: Session, user_id: str, event_type: str, payload: dict) -> models.FeedEvent:
    """
    Chamado pelos MESMOS pontos do backend que já detectam essas
    condições hoje (submit_answer, resolução de batalha, coleta de
    Movimento) — nunca uma lógica de detecção nova (FEED_SOCIAL_V1.md
    §7: "não é necessário criar nova lógica de detecção, apenas
    registrar o evento já detectado também como uma entrada de feed").
    """
    if event_type not in config.FEED_EVENT_TYPES:
        raise ValueError(f"event_type desconhecido: {event_type!r}")
    event = models.FeedEvent(user_id=user_id, event_type=event_type, payload=payload)
    db.add(event)
    db.commit()
    db.refresh(event)
    return event


def build_feed_event_text(event: models.FeedEvent, nickname: str) -> str:
    template = notification_copy.FEED_EVENT_TEMPLATES[event.event_type]
    return template.format(nickname=nickname, **event.payload)


def follow_user(db: Session, follower_id: str, followed_id: str) -> models.Follow | None:
    """
    None se: tentativa de seguir a si mesmo, bloqueio em qualquer
    direção (§6), ou relação já existente (idempotente, nunca duplica).
    """
    if follower_id == followed_id:
        return None
    if is_blocked_either_way(db, follower_id, followed_id):
        return None
    existing = db.execute(
        select(models.Follow).where(
            models.Follow.follower_user_id == follower_id,
            models.Follow.followed_user_id == followed_id,
        )
    ).scalar_one_or_none()
    if existing is not None:
        return None
    follow = models.Follow(follower_user_id=follower_id, followed_user_id=followed_id)
    db.add(follow)
    db.commit()
    db.refresh(follow)
    return follow


def unfollow_user(db: Session, follower_id: str, followed_id: str) -> bool:
    """§4: deixar de seguir é livre e não notifica a outra parte."""
    existing = db.execute(
        select(models.Follow).where(
            models.Follow.follower_user_id == follower_id,
            models.Follow.followed_user_id == followed_id,
        )
    ).scalar_one_or_none()
    if existing is None:
        return False
    db.delete(existing)
    db.commit()
    return True


def is_following(db: Session, follower_id: str, followed_id: str) -> bool:
    return (
        db.execute(
            select(models.Follow).where(
                models.Follow.follower_user_id == follower_id,
                models.Follow.followed_user_id == followed_id,
            )
        ).scalar_one_or_none()
        is not None
    )


def get_fan_count(db: Session, user_id: str) -> int:
    """§4: "um jogador pode ver, de forma simples, sua contagem de
    fãs... dado público, no mesmo espírito de nível e XP"."""
    return db.execute(
        select(func.count()).select_from(models.Follow).where(models.Follow.followed_user_id == user_id)
    ).scalar_one()


def get_following_user_ids(db: Session, user_id: str) -> list[str]:
    return list(
        db.execute(select(models.Follow.followed_user_id).where(models.Follow.follower_user_id == user_id))
        .scalars()
        .all()
    )


def list_feed(db: Session, user_id: str, limit: int, before: datetime | None = None) -> list[models.FeedEvent]:
    """
    FEED_SOCIAL_V1.md §5 — eventos de amigos (relação mútua) + seguidos
    (relação unilateral), nunca de quem bloqueou ou é bloqueado em
    qualquer direção (§6), aplicado ANTES de montar a query (nunca
    filtrado só no client). Paginado por cursor (`before` = created_at
    do último item da página anterior) — mais estável que offset numa
    tabela que só cresce.
    """
    source_user_ids = set(get_friend_user_ids(db, user_id)) | set(get_following_user_ids(db, user_id))
    if not source_user_ids:
        return []
    source_user_ids -= get_blocked_user_ids_either_way(db, user_id)
    if not source_user_ids:
        return []

    query = select(models.FeedEvent).where(models.FeedEvent.user_id.in_(source_user_ids))
    if before is not None:
        query = query.where(models.FeedEvent.created_at < before)
    query = query.order_by(models.FeedEvent.created_at.desc()).limit(limit)
    return list(db.execute(query).scalars().all())
