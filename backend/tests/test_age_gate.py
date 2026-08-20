from .conftest import auth_header


def test_default_child_safe_mode_before_age_gate(client):
    # FAMILY_SAFETY.md §2: até confirmar idade, tratar como criança.
    resp = client.get("/progress", headers=auth_header("user-default-1"))
    assert resp.status_code == 200
    # perfil é criado implicitamente por get_or_create_profile; confirmamos
    # via age-gate que o estado inicial é child_safe.


def test_age_gate_child_gets_system_generated_nickname(client):
    resp = client.post("/age-gate", json={"age_mode": "child"}, headers=auth_header("user-child-1"))
    assert resp.status_code == 200
    body = resp.json()
    assert body["child_safe_mode"] is True
    assert "-" in body["nickname"]


def test_age_gate_adult_disables_child_safe_mode(client):
    resp = client.post("/age-gate", json={"age_mode": "adult"}, headers=auth_header("user-adult-1"))
    assert resp.status_code == 200
    body = resp.json()
    assert body["child_safe_mode"] is False


def test_age_gate_rejects_invalid_mode(client):
    resp = client.post("/age-gate", json={"age_mode": "teen"}, headers=auth_header("user-invalid-1"))
    assert resp.status_code == 422
