"""
V2 item 4 — Desafios visuais (V2_KICKOFF.md §6A). Nenhuma imagem real —
as opções são ícones vetoriais do Flutter codificados como string no
campo "options" já existente (decisão de armazenamento confirmada com
Rhoney antes de implementar, régua Free-First: custo zero com certeza
absoluta, sem Supabase Storage). Estes testes provam que o território
está de fato integrado e que as opções seguem o formato esperado pelo
client (client/lib/visual_options.dart).
"""

import uuid

import app.services as services_module

from .conftest import auth_header


def test_visual_territory_appears_in_progress(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    progress = client.get("/progress", headers=headers).json()
    territory_ids = {t["territory_id"] for t in progress["territories"]}
    assert "visual" in territory_ids


def test_visual_free_sample_then_lock(client, monkeypatch):
    monkeypatch.setattr(services_module.config, "MONETIZATION_ENABLED", True)
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    for _ in range(2):
        resp = client.get("/challenges/next", params={"territory_id": "visual"}, headers=headers)
        assert resp.status_code == 200
        challenge = resp.json()
        assert challenge["territory_id"] == "visual"
        client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": str(uuid.uuid4()), "submitted_answer": "qualquer coisa"},
            headers=headers,
        )

    locked_resp = client.get("/challenges/next", params={"territory_id": "visual"}, headers=headers)
    assert locked_resp.status_code == 403
    assert locked_resp.json()["error"]["code"] == "TERRITORY_LOCKED"


def test_visual_options_follow_expected_format(client):
    # Cada opção precisa seguir "forma_preenchimento_cor_índice" (4
    # segmentos) — é o contrato com client/lib/visual_options.dart
    # (parseVisualOption). Nenhuma opção pode ser texto livre aqui.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "visual"}, headers=headers).json()
    options = challenge["options"]
    assert options is not None and len(options) == 4
    for option in options:
        parts = option.split("_")
        assert len(parts) == 4, f"opção fora do formato esperado: {option}"
        shape, fill, color, _index = parts
        assert shape in {"circle", "square", "star", "heart"}
        assert fill in {"filled", "outline"}
        assert color in {"gold", "teal", "error", "bone"}


def test_visual_full_answer_and_hint_flow(client):
    from app.seed import CHALLENGES

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "visual"}, headers=headers).json()
    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"] and sorted(c["options"]) == sorted(challenge["options"]))
    attempt_id = str(uuid.uuid4())

    hint_resp = client.post(
        f"/challenges/{challenge['challenge_id']}/hint",
        json={"attempt_id": attempt_id},
        headers=headers,
    )
    assert hint_resp.status_code == 200

    answer_resp = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": attempt_id, "submitted_answer": correct},
        headers=headers,
    )
    result = answer_resp.json()
    assert result["is_correct"] is True
    assert result["hints_used"] == 1
    assert result["xp_awarded"] == round(result["xp_base"] * 0.75)
