"""
FEED_SOCIAL_V1.md — Feed de conquistas (piloto) + Seguir/Fã. Eventos
100% gerados pelo sistema (§1) nos MESMOS pontos que já detectam essas
condições hoje (§7) — estes testes cobrem: (a) seguir/deixar de seguir
+ contagem de fãs, (b) bloqueio desfazendo/impedindo "seguir", (c)
escopo de visibilidade do feed (amigos + seguidos, nunca bloqueado), e
(d) cada tipo de evento automático sendo de fato registrado no momento
certo (e só nesse momento — nunca repetido/prematuro).
"""

import uuid
from datetime import date, timedelta

from sqlalchemy import select

from app import config, models
from app.db import SessionLocal
from app.seed import CHALLENGES

from .conftest import auth_header
from .test_battles import _answer as _battle_answer
from .test_battles import _make_friends
from .test_worlds import _answer_correctly, _conquer_territory


def _feed_events_for(user_id: str, event_type: str | None = None) -> list[models.FeedEvent]:
    with SessionLocal() as db:
        rows = db.query(models.FeedEvent).filter(models.FeedEvent.user_id == user_id).all()
        if event_type is not None:
            rows = [r for r in rows if r.event_type == event_type]
        return rows


# ---------------------------------------------------------------------------
# Seguir / Fã (§4)
# ---------------------------------------------------------------------------


def test_follow_creates_relationship_updates_fan_count_and_is_following(client):
    a, b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = auth_header(a), auth_header(b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)

    before = client.get(f"/profile/{b}/public", headers=headers_a).json()
    assert before["is_following_by_me"] is False
    assert before["fan_count"] == 0

    resp = client.post(f"/profile/{b}/follow", headers=headers_a)
    assert resp.status_code == 200
    assert resp.json() == {"ok": True, "following": True, "fan_count": 1}

    after = client.get(f"/profile/{b}/public", headers=headers_a).json()
    assert after["is_following_by_me"] is True
    assert after["fan_count"] == 1


def test_cannot_follow_self(client):
    a = str(uuid.uuid4())
    headers_a = auth_header(a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)

    client.post(f"/profile/{a}/follow", headers=headers_a)
    profile = client.get(f"/profile/{a}/public", headers=headers_a).json()
    assert profile["is_following_by_me"] is False
    assert profile["fan_count"] == 0


def test_unfollow_is_free_and_does_not_notify(client):
    a, b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = auth_header(a), auth_header(b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)

    client.post(f"/profile/{b}/follow", headers=headers_a)
    resp = client.delete(f"/profile/{b}/follow", headers=headers_a)
    assert resp.status_code == 200
    assert resp.json() == {"ok": True, "following": False, "fan_count": 0}

    profile = client.get(f"/profile/{b}/public", headers=headers_a).json()
    assert profile["is_following_by_me"] is False


def test_follow_nonexistent_user_does_not_create_a_row(client):
    """Achado de auditoria de segurança 2.2 (11/09/2026): sem essa
    checagem, POST /profile/{id}/follow inseria uma linha em
    mental.follows pra qualquer uuid, mesmo sem Profile correspondente —
    vetor barato de poluição da tabela."""
    from app import models
    from app.db import SessionLocal

    a = str(uuid.uuid4())
    nonexistent = str(uuid.uuid4())
    headers_a = auth_header(a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)

    resp = client.post(f"/profile/{nonexistent}/follow", headers=headers_a)
    assert resp.status_code == 200
    assert resp.json()["following"] is False

    with SessionLocal() as db:
        row = db.execute(
            select(models.Follow).where(
                models.Follow.follower_user_id == a,
                models.Follow.followed_user_id == nonexistent,
            )
        ).scalar_one_or_none()
        assert row is None


def test_block_prevents_new_follow_and_removes_existing_follow_both_ways(client):
    a, b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = auth_header(a), auth_header(b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)

    # a segue b, e b segue a, ANTES do bloqueio.
    client.post(f"/profile/{b}/follow", headers=headers_a)
    client.post(f"/profile/{a}/follow", headers=headers_b)
    assert client.get(f"/profile/{b}/public", headers=headers_a).json()["fan_count"] == 1
    assert client.get(f"/profile/{a}/public", headers=headers_b).json()["fan_count"] == 1

    client.post("/social/block", json={"blocked_user_id": b}, headers=headers_a)

    # FEED_SOCIAL_V1.md §6: bloqueio desfaz a relação existente nos dois
    # sentidos — nenhum dos dois continua "fã" do outro.
    with SessionLocal() as db:
        remaining = db.query(models.Follow).filter(
            (models.Follow.follower_user_id.in_([a, b])) | (models.Follow.followed_user_id.in_([a, b]))
        ).all()
        assert remaining == []

    # E impede nova relação enquanto o bloqueio existir.
    follow_resp = client.post(f"/profile/{b}/follow", headers=headers_a)
    assert follow_resp.json()["following"] is False


# ---------------------------------------------------------------------------
# Visibilidade do Feed (§5/§6)
# ---------------------------------------------------------------------------


def test_feed_lists_events_from_friends_and_followed_only(client):
    viewer = str(uuid.uuid4())
    friend, followed, stranger = str(uuid.uuid4()), str(uuid.uuid4()), str(uuid.uuid4())
    headers_viewer = auth_header(viewer)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_viewer)
    for uid in (friend, followed, stranger):
        client.post("/age-gate", json={"age_confirmed": True}, headers=auth_header(uid))

    _make_friends(client, viewer, friend)
    client.post(f"/profile/{followed}/follow", headers=headers_viewer)

    with SessionLocal() as db:
        db.add(models.FeedEvent(user_id=friend, event_type="level_up_milestone", payload={"level": 10}))
        db.add(models.FeedEvent(user_id=followed, event_type="level_up_milestone", payload={"level": 20}))
        db.add(models.FeedEvent(user_id=stranger, event_type="level_up_milestone", payload={"level": 30}))
        db.commit()

    body = client.get("/feed", headers=headers_viewer).json()
    event_user_ids = {e["user_id"] for e in body["events"]}
    assert event_user_ids == {friend, followed}
    assert stranger not in event_user_ids


def test_feed_excludes_events_from_blocked_user_even_if_friend_or_followed(client):
    viewer = str(uuid.uuid4())
    friend = str(uuid.uuid4())
    headers_viewer = auth_header(viewer)
    headers_friend = auth_header(friend)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_viewer)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_friend)

    _make_friends(client, viewer, friend)
    with SessionLocal() as db:
        db.add(models.FeedEvent(user_id=friend, event_type="level_up_milestone", payload={"level": 10}))
        db.commit()

    assert friend in {e["user_id"] for e in client.get("/feed", headers=headers_viewer).json()["events"]}

    client.post("/social/block", json={"blocked_user_id": friend}, headers=headers_viewer)
    body = client.get("/feed", headers=headers_viewer).json()
    assert friend not in {e["user_id"] for e in body["events"]}


def test_feed_event_text_is_built_server_side_from_template(client):
    viewer, friend = str(uuid.uuid4()), str(uuid.uuid4())
    headers_viewer = auth_header(viewer)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_viewer)
    client.post("/age-gate", json={"age_confirmed": True}, headers=auth_header(friend))
    _make_friends(client, viewer, friend)

    with SessionLocal() as db:
        db.add(models.FeedEvent(user_id=friend, event_type="level_up_milestone", payload={"level": 20}))
        db.commit()
        nickname = db.get(models.Profile, friend).nickname

    body = client.get("/feed", headers=headers_viewer).json()
    event = next(e for e in body["events"] if e["user_id"] == friend)
    assert event["text"] == f"{nickname} chegou ao Nível 20! ⭐"


def test_feed_event_uses_real_name_instead_of_nickname_when_set(client):
    """Pedido de Rhoney (07/09/2026): "em todas as telas... o nome do
    usuário deve aparecer e não o código" — real_name tem prioridade
    sobre o apelido gerado, mesmo padrão já usado em Ranking/Amigos."""
    viewer, friend = str(uuid.uuid4()), str(uuid.uuid4())
    headers_viewer = auth_header(viewer)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_viewer)
    client.post("/age-gate", json={"age_confirmed": True}, headers=auth_header(friend))
    _make_friends(client, viewer, friend)

    with SessionLocal() as db:
        profile = db.get(models.Profile, friend)
        profile.real_name = "Fulano de Tal"
        db.add(models.FeedEvent(user_id=friend, event_type="level_up_milestone", payload={"level": 20}))
        db.commit()

    body = client.get("/feed", headers=headers_viewer).json()
    event = next(e for e in body["events"] if e["user_id"] == friend)
    assert event["nickname"] == "Fulano de Tal"
    assert event["text"] == "Fulano de Tal chegou ao Nível 20! ⭐"


# ---------------------------------------------------------------------------
# Cada tipo de evento automático (§2) — registrado no momento certo
# ---------------------------------------------------------------------------


def test_world_completed_creates_a_feed_event(client, monkeypatch):
    # Conquistar 4 territórios facilmente ultrapassa o limite diário
    # gratuito (24/dia) e o teto de abuso de resposta (RATE_LIMIT_
    # ANSWER_SUBMIT) — mesma infraestrutura de teste já usada em
    # test_worlds.py::test_world_just_completed_fires_once_at_the_exact_last_territory.
    monkeypatch.setattr(config, "RATE_LIMIT_ANSWER_SUBMIT", (10_000, 60.0))

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers)

    assert _feed_events_for(user, "world_completed") == []
    for territory_id in ("palavras", "textos", "enigmas", "redacao"):
        _conquer_territory(client, headers, territory_id)

    events = _feed_events_for(user, "world_completed")
    assert len(events) == 1
    assert events[0].payload["world_name"] == "Mundo da Linguagem"


def test_streak_milestone_creates_feed_event_only_at_the_exact_milestone_day(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _answer_correctly(client, headers, "palavras")  # cria o Streak

    with SessionLocal() as db:
        streak = db.get(models.Streak, user)
        streak.current_streak = 29
        streak.last_played_date = date.today() - timedelta(days=1)
        db.commit()

    _answer_correctly(client, headers, "palavras")  # streak vira 30 — marco
    assert len(_feed_events_for(user, "streak_milestone")) == 1
    assert _feed_events_for(user, "streak_milestone")[0].payload["days"] == 30

    with SessionLocal() as db:
        streak = db.get(models.Streak, user)
        streak.last_played_date = date.today() - timedelta(days=1)
        db.commit()

    _answer_correctly(client, headers, "palavras")  # streak vira 31 — não é marco
    assert len(_feed_events_for(user, "streak_milestone")) == 1  # continua só o de 30


def test_level_up_milestone_creates_feed_event_only_crossing_a_multiple_of_ten(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        profile.xp_total = 899  # nível 9 (1 + 899 // 100)
        profile.level = 9
        db.commit()

    _answer_correctly(client, headers, "palavras")  # xp cruza 900 — nível 10
    events = _feed_events_for(user, "level_up_milestone")
    assert len(events) == 1
    assert events[0].payload["level"] == 10


def test_level_up_that_does_not_cross_a_multiple_of_ten_creates_no_event(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        profile.xp_total = 199  # nível 2 (1 + 199 // 100)
        profile.level = 2
        db.commit()

    _answer_correctly(client, headers, "palavras")  # xp cruza 200 — nível 3, não é marco de 10
    assert _feed_events_for(user, "level_up_milestone") == []


def test_battle_won_creates_feed_event_for_winner_only(client):
    winner, loser = str(uuid.uuid4()), str(uuid.uuid4())
    headers_winner, headers_loser = _make_friends(client, winner, loser)

    created = client.post(
        "/battles",
        json={"opponent_user_id": loser, "territory_id": "palavras", "difficulty_level": 1},
        headers=headers_winner,
    ).json()
    battle_id = created["battle_id"]
    opponent_challenge = client.get(f"/battles/{battle_id}/my-challenge", headers=headers_loser).json()

    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == created["challenge"]["prompt"])
    _battle_answer(client, headers_winner, created["challenge"], correct)
    _battle_answer(client, headers_loser, opponent_challenge, "resposta errada de propósito")

    winner_events = _feed_events_for(winner, "battle_won")
    assert len(winner_events) == 1
    assert winner_events[0].payload["opponent_nickname"]
    assert _feed_events_for(loser, "battle_won") == []


def test_battle_tie_creates_no_feed_event(client):
    a, b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, headers_b = _make_friends(client, a, b)

    created = client.post(
        "/battles",
        json={"opponent_user_id": b, "territory_id": "palavras", "difficulty_level": 1},
        headers=headers_a,
    ).json()
    battle_id = created["battle_id"]
    opponent_challenge = client.get(f"/battles/{battle_id}/my-challenge", headers=headers_b).json()

    _battle_answer(client, headers_a, created["challenge"], "resposta errada de propósito")
    _battle_answer(client, headers_b, opponent_challenge, "resposta errada de propósito")

    assert _feed_events_for(a, "battle_won") == []
    assert _feed_events_for(b, "battle_won") == []


def test_movement_personal_record_creates_feed_event_only_when_crossing_previous_best(client):
    from app import movement, services

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    with SessionLocal() as db:
        services.get_or_create_profile(db, user)
        profile = db.get(models.Profile, user)
        profile.movement_enabled = True
        from app.timeutil import utcnow
        profile.movement_cycle_anchor_at = utcnow()
        db.commit()

        # Ciclo antigo já fechado, com um recorde conhecido.
        old_cycle = models.MovementCycle(
            user_id=user,
            cycle_start_at=utcnow() - timedelta(days=2),
            cycle_end_at=utcnow() - timedelta(days=1),
            steps_collected=5000,
        )
        db.add(old_cycle)
        db.commit()

        cycle, *_ = movement.collect_steps(db, user, 3000)  # abaixo do recorde — sem evento
        assert _feed_events_for(user, "movement_record") == []

        movement.collect_steps(db, user, 4000, cycle_id=cycle.id)  # total 7000, cruza os 5000 — evento
        events = _feed_events_for(user, "movement_record")
        assert len(events) == 1
        assert events[0].payload["steps"] == 7000

        movement.collect_steps(db, user, 500, cycle_id=cycle.id)  # já acima do recorde — sem novo evento
        assert len(_feed_events_for(user, "movement_record")) == 1
