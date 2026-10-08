import uuid

from .conftest import auth_header


def test_guest_worlds_lists_first_territory_of_each_world(client):
    resp = client.get("/guest/worlds")
    assert resp.status_code == 200
    body = resp.json()
    assert body, "esperado pelo menos 1 mundo"
    world_ids = {w["world_id"] for w in body}
    assert "idiomas" in world_ids
    idiomas_entry = next(w for w in body if w["world_id"] == "idiomas")
    assert idiomas_entry["territory_id"] == "libras"


def test_guest_next_challenge_works_without_auth(client):
    resp = client.get("/guest/challenges/next", params={"territory_id": "libras"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["attempt_id"] is None
    assert body["territory_id"] == "libras"
    assert body["prompt"]
    assert body["options"]
    assert "correct_answer" not in body


def test_guest_next_challenge_rejects_non_entry_territory(client):
    resp = client.get("/guest/challenges/next", params={"territory_id": "ingles_intermediario"})
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "TERRITORY_NOT_ALLOWED_FOR_GUEST"


def test_guest_submit_answer_grades_without_persisting(client):
    next_resp = client.get("/guest/challenges/next", params={"territory_id": "libras"})
    challenge_id = next_resp.json()["challenge_id"]

    wrong_resp = client.post(f"/guest/challenges/{challenge_id}/answer", json={"submitted_answer": "resposta errada qualquer"})
    assert wrong_resp.status_code == 200
    wrong_body = wrong_resp.json()
    assert wrong_body["is_correct"] is False
    assert wrong_body["xp_preview"] == 0
    assert wrong_body["correct_answer"]

    right_resp = client.post(f"/guest/challenges/{challenge_id}/answer", json={"submitted_answer": wrong_body["correct_answer"]})
    assert right_resp.status_code == 200
    right_body = right_resp.json()
    assert right_body["is_correct"] is True
    assert right_body["xp_preview"] > 0


def test_migrate_progress_awards_real_xp_through_normal_pipeline(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    answered = []
    for _ in range(3):
        next_resp = client.get("/guest/challenges/next", params={"territory_id": "libras"})
        challenge_id = next_resp.json()["challenge_id"]
        guess_resp = client.post(f"/guest/challenges/{challenge_id}/answer", json={"submitted_answer": "x"})
        correct_answer = guess_resp.json()["correct_answer"]
        answered.append({"challenge_id": challenge_id, "submitted_answer": correct_answer})

    # GET /progress já concede XP de login diário (rewards.daily_login)
    # fora deste fluxo — por isso comparamos o DELTA, não um baseline 0.
    xp_before = client.get("/progress", headers=headers).json()["xp_total"]

    migrate_resp = client.post("/guest/migrate-progress", json={"answers": answered}, headers=headers)
    assert migrate_resp.status_code == 200
    assert migrate_resp.json()["xp_awarded_total"] > 0

    xp_after = client.get("/progress", headers=headers).json()["xp_total"]
    assert xp_after - xp_before == migrate_resp.json()["xp_awarded_total"]


def test_migrate_progress_is_idempotent(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    next_resp = client.get("/guest/challenges/next", params={"territory_id": "libras"})
    challenge_id = next_resp.json()["challenge_id"]
    guess_resp = client.post(f"/guest/challenges/{challenge_id}/answer", json={"submitted_answer": "x"})
    correct_answer = guess_resp.json()["correct_answer"]
    answers = [{"challenge_id": challenge_id, "submitted_answer": correct_answer}]

    xp_before = client.get("/progress", headers=headers).json()["xp_total"]

    first = client.post("/guest/migrate-progress", json={"answers": answers}, headers=headers)
    second = client.post("/guest/migrate-progress", json={"answers": answers}, headers=headers)
    assert first.json()["xp_awarded_total"] > 0
    assert second.json()["xp_awarded_total"] == 0

    xp_after = client.get("/progress", headers=headers).json()["xp_total"]
    assert xp_after - xp_before == first.json()["xp_awarded_total"]


def test_guest_endpoints_are_rate_limited(client):
    for _ in range(25):
        resp = client.get("/guest/worlds")
    assert resp.status_code in (200, 429)
    if resp.status_code == 429:
        assert resp.json()["error"]["code"] == "RATE_LIMIT_EXCEEDED"
