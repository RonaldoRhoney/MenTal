"""
Mural de feedback aberto (decisão de Rhoney, 20/09/2026): TODOS comentam e
respondem, não só o admin. O que mais importa aqui: qualquer usuário
consegue responder, ninguém apaga a resposta dos outros (só o autor ou o
admin) e o mural aberto tem freio contra flood.
"""

import uuid

from app import config, models
from app.db import SessionLocal

from .conftest import auth_header


def _user(client) -> tuple[str, dict]:
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    return user, headers


def _feedback(client, headers, text="O app é ótimo") -> str:
    client.post("/feedback", json={"comment": text}, headers=headers)
    items = client.get("/feedback", headers=headers).json()["items"]
    return next(i["id"] for i in items if i["comment"] == text)


def _make_admin(user: str) -> None:
    with SessionLocal() as db:
        db.get(models.Profile, user).role = "admin"
        db.commit()


def test_qualquer_usuario_responde_e_todos_veem(client):
    _, author = _user(client)
    _, other = _user(client)
    _, third = _user(client)
    fid = _feedback(client, author, f"Sugestão {uuid.uuid4()}")

    resp = client.post(f"/feedback/{fid}/replies", json={"comment": "Concordo com você!"}, headers=other)
    assert resp.status_code == 200
    assert resp.json()["is_mine"] is True

    # o autor do comentário e um terceiro veem a resposta
    for viewer in (author, third):
        item = next(i for i in client.get("/feedback", headers=viewer).json()["items"] if i["id"] == fid)
        assert [r["comment"] for r in item["replies"]] == ["Concordo com você!"]
        assert item["replies"][0]["is_mine"] is False
    item = next(i for i in client.get("/feedback", headers=other).json()["items"] if i["id"] == fid)
    assert item["replies"][0]["is_mine"] is True


def test_resposta_em_comentario_inexistente_da_404(client):
    _, headers = _user(client)
    resp = client.post(f"/feedback/{uuid.uuid4()}/replies", json={"comment": "oi"}, headers=headers)
    assert resp.status_code == 404


def test_resposta_vazia_ou_gigante_e_rejeitada(client):
    _, headers = _user(client)
    fid = _feedback(client, headers, f"Comentário {uuid.uuid4()}")
    assert client.post(f"/feedback/{fid}/replies", json={"comment": "   "}, headers=headers).status_code == 422
    assert client.post(f"/feedback/{fid}/replies", json={"comment": "x" * 1001}, headers=headers).status_code == 422


def test_so_o_autor_ou_admin_apaga_a_resposta(client):
    _, author = _user(client)
    _, replier = _user(client)
    _, stranger = _user(client)
    admin_id, admin = _user(client)
    _make_admin(admin_id)
    fid = _feedback(client, author, f"Tema {uuid.uuid4()}")
    reply_id = client.post(f"/feedback/{fid}/replies", json={"comment": "resposta"}, headers=replier).json()["id"]

    # estranho e até o autor do COMENTÁRIO não apagam a resposta dos outros (404 não-revelador)
    assert client.delete(f"/feedback/replies/{reply_id}", headers=stranger).status_code == 404
    assert client.delete(f"/feedback/replies/{reply_id}", headers=author).status_code == 404
    assert client.delete(f"/feedback/replies/{reply_id}", headers=replier).status_code == 200

    reply_id2 = client.post(f"/feedback/{fid}/replies", json={"comment": "outra"}, headers=replier).json()["id"]
    assert client.delete(f"/feedback/replies/{reply_id2}", headers=admin).status_code == 200  # moderação
    item = next(i for i in client.get("/feedback", headers=author).json()["items"] if i["id"] == fid)
    assert item["replies"] == []


def test_resposta_de_usuario_nao_paga_xp(client):
    # Anti-farm: só o comentário novo (1x por semana) paga; responder nunca.
    _, headers = _user(client)
    _, other = _user(client)
    fid = _feedback(client, other, f"Assunto {uuid.uuid4()}")
    before = client.get("/progress", headers=headers).json()["xp_total"]
    for i in range(3):
        client.post(f"/feedback/{fid}/replies", json={"comment": f"resposta longa numero {i}"}, headers=headers)
    assert client.get("/progress", headers=headers).json()["xp_total"] == before


def test_mural_aberto_tem_freio_por_dia(client, monkeypatch):
    _, headers = _user(client)
    monkeypatch.setattr(config, "RATE_LIMIT_FEEDBACK_POST", (1000, 60.0))
    monkeypatch.setattr(config, "APP_FEEDBACK_DAILY_LIMIT", 3)
    fid = _feedback(client, headers, f"Base {uuid.uuid4()}")  # 1 do teto diário
    assert client.post(f"/feedback/{fid}/replies", json={"comment": "um"}, headers=headers).status_code == 200
    assert client.post(f"/feedback/{fid}/replies", json={"comment": "dois"}, headers=headers).status_code == 200
    blocked = client.post(f"/feedback/{fid}/replies", json={"comment": "tres"}, headers=headers)
    assert blocked.status_code == 429
    assert blocked.json()["error"]["code"] == "DAILY_FEEDBACK_LIMIT"
    # comentário novo também conta no mesmo teto
    assert client.post("/feedback", json={"comment": "novo comentário"}, headers=headers).status_code == 429


def test_rate_limit_por_minuto_no_comentario(client, monkeypatch):
    _, headers = _user(client)
    monkeypatch.setattr(config, "RATE_LIMIT_FEEDBACK_POST", (2, 60.0))
    monkeypatch.setattr(config, "APP_FEEDBACK_DAILY_LIMIT", 1000)
    codes = [client.post("/feedback", json={"comment": f"texto {i} {uuid.uuid4()}"}, headers=headers).status_code for i in range(4)]
    assert codes[:2] == [200, 200] and 429 in codes[2:]
