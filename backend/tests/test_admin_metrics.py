"""
U.I/ADMIN_PAINEL_IN_APP_V1.md — painel administrativo leve, dentro do
app. Somente leitura, restrito a role=admin.
"""

import uuid

from app import models
from app.db import SessionLocal
from app.seed import CHALLENGES

from .conftest import auth_header


def _promote_to_admin(user: str) -> None:
    with SessionLocal() as db:
        profile = db.get(models.Profile, user.replace("-", ""))
        profile.role = "admin"
        db.commit()


def test_non_admin_is_rejected(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/admin/metrics/summary", headers=headers)
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "ADMIN_ONLY"


def test_invalid_period_rejected(client):
    admin = str(uuid.uuid4())
    headers = auth_header(admin)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _promote_to_admin(admin)

    resp = client.get("/admin/metrics/summary", params={"period": "1y"}, headers=headers)
    assert resp.status_code == 422


def test_admin_gets_summary_with_expected_shape(client):
    admin = str(uuid.uuid4())
    headers = auth_header(admin)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    _promote_to_admin(admin)

    resp = client.get("/admin/metrics/summary", params={"period": "30d"}, headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    for key in (
        "active_users_today",
        "active_users_week",
        "new_signups_in_period",
        "engaged_users_in_period",
        "average_streak_active_users",
        "top_progressors",
        "accuracy_by_territory",
        "feedback_distribution",
        "demographics",
        "movement",
    ):
        assert key in body
    for key in ("gender", "age_range", "state", "city"):
        assert key in body["demographics"]
    for key in (
        "enabled_users",
        "active_users_in_period",
        "total_steps_in_period",
        "total_xp_in_period",
        "average_steps_per_active_user",
        "goal_distribution",
    ):
        assert key in body["movement"]


def test_top_progressors_and_accuracy_reflect_real_attempts(client):
    admin = str(uuid.uuid4())
    player = str(uuid.uuid4())
    admin_headers = auth_header(admin)
    player_headers = auth_header(player)
    client.post("/age-gate", json={"age_confirmed": True}, headers=admin_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=player_headers)
    _promote_to_admin(admin)

    challenge = client.get("/challenges/next", params={"territory_id": "esportes"}, headers=player_headers).json()
    correct_answer = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"])
    answer_resp = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": challenge["attempt_id"], "submitted_answer": correct_answer},
        headers=player_headers,
    )
    assert answer_resp.status_code == 200

    body = client.get("/admin/metrics/summary", params={"period": "today"}, headers=admin_headers).json()

    progressors = {p["user_id"]: p for p in body["top_progressors"]}
    assert player in progressors
    assert progressors[player]["xp_gained"] > 0

    accuracy = {a["territory_id"]: a for a in body["accuracy_by_territory"]}
    assert "esportes" in accuracy
    assert accuracy["esportes"]["total_attempts"] >= 1

    # engaged_users_in_period conta ação real (Attempt), não só ter
    # aberto o app — o player respondeu, então precisa entrar na contagem.
    assert body["engaged_users_in_period"] >= 1


def test_demographics_reflect_profile_fields(client):
    admin = str(uuid.uuid4())
    player = str(uuid.uuid4())
    admin_headers = auth_header(admin)
    player_headers = auth_header(player)
    client.post("/age-gate", json={"age_confirmed": True}, headers=admin_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=player_headers)
    _promote_to_admin(admin)

    client.put(
        "/profile",
        json={"gender": "feminino", "age_range": "26-35", "location_state": "SP", "city": "São Paulo"},
        headers=player_headers,
    )

    body = client.get("/admin/metrics/summary", params={"period": "30d"}, headers=admin_headers).json()
    demographics = body["demographics"]

    assert any(b["label"] == "feminino" and b["count"] >= 1 for b in demographics["gender"])
    assert any(b["label"] == "26-35" and b["count"] >= 1 for b in demographics["age_range"])
    assert any(b["label"] == "SP" and b["count"] >= 1 for b in demographics["state"])
    assert any(b["label"] == "São Paulo" and b["count"] >= 1 for b in demographics["city"])


def test_movement_metrics_reflect_real_collected_steps(client):
    admin = str(uuid.uuid4())
    player = str(uuid.uuid4())
    admin_headers = auth_header(admin)
    player_headers = auth_header(player)
    client.post("/age-gate", json={"age_confirmed": True}, headers=admin_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=player_headers)
    _promote_to_admin(admin)

    client.post("/movement/enable", headers=player_headers)
    client.put("/movement/goal", json={"daily_goal_steps": 10000}, headers=player_headers)
    collect_resp = client.post("/movement/collect", json={"steps": 3000}, headers=player_headers)
    assert collect_resp.status_code == 200

    body = client.get("/admin/metrics/summary", params={"period": "today"}, headers=admin_headers).json()
    movement = body["movement"]

    assert movement["enabled_users"] >= 1
    assert movement["active_users_in_period"] >= 1
    assert movement["total_steps_in_period"] >= 3000
    assert movement["average_steps_per_active_user"] >= 1
    assert any(b["label"] == "10.000 (padrão)" and b["count"] >= 1 for b in movement["goal_distribution"])
