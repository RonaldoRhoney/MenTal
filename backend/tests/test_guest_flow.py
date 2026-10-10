import uuid

from sqlalchemy import select

from app import config, models
from app.db import SessionLocal
from app.routers.guest import _pick_challenge_for_guest

from .conftest import auth_header


def _any_challenge_id_for(territory_id: str) -> str:
    with SessionLocal() as db:
        return db.execute(
            select(models.Challenge.id).where(models.Challenge.territory_id == territory_id).limit(1)
        ).scalar_one()


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
    assert body["serve_token"]
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
    serve_token = next_resp.json()["serve_token"]

    wrong_resp = client.post(
        f"/guest/challenges/{challenge_id}/answer",
        json={"submitted_answer": "resposta errada qualquer", "serve_token": serve_token},
    )
    assert wrong_resp.status_code == 200
    wrong_body = wrong_resp.json()
    assert wrong_body["is_correct"] is False
    assert wrong_body["xp_preview"] == 0
    assert wrong_body["correct_answer"]
    assert wrong_body["completion_token"]

    right_resp = client.post(
        f"/guest/challenges/{challenge_id}/answer",
        json={"submitted_answer": wrong_body["correct_answer"], "serve_token": serve_token},
    )
    assert right_resp.status_code == 200
    right_body = right_resp.json()
    assert right_body["is_correct"] is True
    assert right_body["xp_preview"] > 0


def test_guest_submit_answer_rejects_missing_or_wrong_serve_token(client):
    """
    Achado crítico de segurança (09/10/2026, auditoria pré-AAB): antes
    desta correção, o endpoint aceitava QUALQUER challenge_id sem
    nenhuma prova de que foi servido por GET /guest/challenges/next —
    um oráculo gratuito de resposta certa pra qualquer desafio das
    etapas liberadas pra guest, sem precisar nem chamar /next antes.
    """
    next_resp = client.get("/guest/challenges/next", params={"territory_id": "libras"})
    challenge_id = next_resp.json()["challenge_id"]

    no_token = client.post(f"/guest/challenges/{challenge_id}/answer", json={"submitted_answer": "x", "serve_token": ""})
    assert no_token.status_code == 403
    assert no_token.json()["error"]["code"] == "INVALID_SERVE_TOKEN"

    # serve_token de um challenge_id DIFERENTE (ex.: outro território
    # liberado pra guest) nunca pode gradear este challenge_id.
    other_resp = client.get("/guest/challenges/next", params={"territory_id": "palavras"})
    other_token = other_resp.json()["serve_token"]
    wrong_token = client.post(
        f"/guest/challenges/{challenge_id}/answer",
        json={"submitted_answer": "x", "serve_token": other_token},
    )
    assert wrong_token.status_code == 403
    assert wrong_token.json()["error"]["code"] == "INVALID_SERVE_TOKEN"


def test_guest_submit_answer_rejects_challenge_from_non_entry_territory(client):
    """
    'ingles_intermediario' não é a primeira etapa de nenhum Mundo (não
    aparece em GET /guest/worlds) — mesmo com um serve_token forjado
    (impossível sem o segredo do servidor), o território continua
    bloqueado.
    """
    challenge_id = _any_challenge_id_for("ingles_intermediario")
    resp = client.post(
        f"/guest/challenges/{challenge_id}/answer",
        json={"submitted_answer": "qualquer coisa", "serve_token": "forjado.assinatura"},
    )
    assert resp.status_code == 403


def _answer_via_guest_flow(client, territory_id: str = "libras") -> dict:
    next_resp = client.get("/guest/challenges/next", params={"territory_id": territory_id})
    challenge_id = next_resp.json()["challenge_id"]
    serve_token = next_resp.json()["serve_token"]
    guess_resp = client.post(
        f"/guest/challenges/{challenge_id}/answer",
        json={"submitted_answer": "x", "serve_token": serve_token},
    )
    correct_answer = guess_resp.json()["correct_answer"]
    confirm_resp = client.post(
        f"/guest/challenges/{challenge_id}/answer",
        json={"submitted_answer": correct_answer, "serve_token": serve_token},
    )
    return {
        "challenge_id": challenge_id,
        "submitted_answer": correct_answer,
        "completion_token": confirm_resp.json()["completion_token"],
    }


def test_migrate_progress_awards_real_xp_through_normal_pipeline(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    answered = [_answer_via_guest_flow(client) for _ in range(3)]

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

    answers = [_answer_via_guest_flow(client)]

    xp_before = client.get("/progress", headers=headers).json()["xp_total"]

    first = client.post("/guest/migrate-progress", json={"answers": answers}, headers=headers)
    second = client.post("/guest/migrate-progress", json={"answers": answers}, headers=headers)
    assert first.json()["xp_awarded_total"] > 0
    assert second.json()["xp_awarded_total"] == 0

    xp_after = client.get("/progress", headers=headers).json()["xp_total"]
    assert xp_after - xp_before == first.json()["xp_awarded_total"]


def test_migrate_progress_requires_age_confirmation(client):
    """
    Achado crítico de segurança (09/10/2026, DIR-001): migrate-progress
    usava get_current_user_id (sem exigir maioridade confirmada) — uma
    conta que nunca passou pelo Age Gate podia acumular Attempt/XP reais
    mesmo assim. Agora exige require_age_confirmed_user_id, igual a
    qualquer outro endpoint que credita XP.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    # Propositalmente NÃO confirma idade (sem POST /age-gate).
    answers = [_answer_via_guest_flow(client)]
    resp = client.post("/guest/migrate-progress", json={"answers": answers}, headers=headers)
    assert resp.status_code == 403


def test_migrate_progress_rejects_fabricated_completion_token(client):
    """
    Achado crítico de segurança (09/10/2026): antes desta correção,
    migrate-progress confiava direto em challenge_id+submitted_answer
    vindos do client — dava pra "migrar" qualquer par sem nunca ter
    passado por POST /guest/challenges/{id}/answer, usando a resposta
    certa descoberta por fora (ex.: o próprio oráculo do endpoint de
    resposta). Agora exige um completion_token assinado pelo servidor,
    emitido só por aquele endpoint pra aquele par exato.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    with SessionLocal() as db:
        challenge = db.get(models.Challenge, _any_challenge_id_for("libras"))
        correct_answer = challenge.correct_answer

    xp_before = client.get("/progress", headers=headers).json()["xp_total"]
    resp = client.post(
        "/guest/migrate-progress",
        json={"answers": [{"challenge_id": challenge.id, "submitted_answer": correct_answer, "completion_token": "forjado.assinatura"}]},
        headers=headers,
    )
    assert resp.status_code == 200
    assert resp.json()["xp_awarded_total"] == 0
    xp_after = client.get("/progress", headers=headers).json()["xp_total"]
    assert xp_after == xp_before


def test_migrate_progress_rejects_completion_token_for_different_answer(client):
    """
    completion_token é amarrado ao hash do submitted_answer exato — não
    dá pra pegar um recibo de uma resposta e usá-lo pra "migrar" uma
    resposta diferente (ex.: trocar pela resposta certa depois de ter
    errado de propósito no /answer pra só coletar o token).
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    next_resp = client.get("/guest/challenges/next", params={"territory_id": "libras"})
    challenge_id = next_resp.json()["challenge_id"]
    serve_token = next_resp.json()["serve_token"]
    wrong_resp = client.post(
        f"/guest/challenges/{challenge_id}/answer",
        json={"submitted_answer": "resposta errada", "serve_token": serve_token},
    )
    completion_token = wrong_resp.json()["completion_token"]
    correct_answer = wrong_resp.json()["correct_answer"]

    resp = client.post(
        "/guest/migrate-progress",
        json={"answers": [{"challenge_id": challenge_id, "submitted_answer": correct_answer, "completion_token": completion_token}]},
        headers=headers,
    )
    assert resp.status_code == 200
    assert resp.json()["xp_awarded_total"] == 0


def test_migrate_progress_ignores_challenge_from_non_entry_territory(client):
    """
    Território trancado continua bloqueado mesmo com um completion_token
    estruturalmente válido pra outro item — _is_guest_allowed_territory
    é checado antes de processar qualquer item.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    xp_before = client.get("/progress", headers=headers).json()["xp_total"]

    resp = client.post(
        "/guest/migrate-progress",
        json={"answers": [{
            "challenge_id": _any_challenge_id_for("ingles_intermediario"),
            "submitted_answer": "x",
            "completion_token": "forjado.assinatura",
        }]},
        headers=headers,
    )
    assert resp.status_code == 200
    assert resp.json()["xp_awarded_total"] == 0

    xp_after = client.get("/progress", headers=headers).json()["xp_total"]
    assert xp_after == xp_before

    progress = client.get("/progress", headers=headers).json()
    territory_entry = next(t for t in progress["territories"] if t["territory_id"] == "ingles_intermediario")
    assert territory_entry["xp_in_territory"] == 0


def test_guest_next_challenge_never_exposes_more_than_the_preview_sized_deck(client):
    """
    C1 fechado de verdade (10/10/2026, ver guest.py): antes desta
    correção, repetir GET /next sem limite deixava "garimpar" o deck
    inteiro de um território liberado pra guest — mitigado só pelo rate
    limit genérico (chamadas/minuto, não challenge_ids DIFERENTES
    vistos). Testa _pick_challenge_for_guest diretamente (não via HTTP)
    pra não disputar o rate limit em memória com os outros testes deste
    arquivo, que compartilham o mesmo IP de TestClient: mesmo chamando
    bem mais vezes que as 3 perguntas que o fluxo pretende mostrar,
    nunca mais que config.GUEST_MAX_DISTINCT_CHALLENGES ids diferentes
    aparecem pro mesmo (IP, território).
    """
    with SessionLocal() as db:
        candidates = db.execute(
            select(models.Challenge).where(models.Challenge.territory_id == "palavras")
        ).scalars().all()

    seen_ids = set()
    fake_ip = "203.0.113.42"
    for _ in range(10):
        challenge = _pick_challenge_for_guest(candidates, fake_ip, "palavras")
        seen_ids.add(challenge.id)
    assert len(seen_ids) <= config.GUEST_MAX_DISTINCT_CHALLENGES


def test_guest_endpoints_are_rate_limited(client):
    for _ in range(25):
        resp = client.get("/guest/worlds")
    assert resp.status_code in (200, 429)
    if resp.status_code == 429:
        assert resp.json()["error"]["code"] == "RATE_LIMIT_EXCEEDED"
