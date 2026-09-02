import uuid
from datetime import timedelta
from app.timeutil import utcnow

from app.config import DAILY_FREE_CHALLENGE_LIMIT

from .conftest import auth_header


def test_daily_free_limit_blocks_after_limit(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    for i in range(DAILY_FREE_CHALLENGE_LIMIT):
        resp = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
        assert resp.status_code == 200, f"deveria permitir a tentativa {i + 1}/{DAILY_FREE_CHALLENGE_LIMIT}"
        challenge = resp.json()
        client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": challenge["attempt_id"], "submitted_answer": "qualquer"},
            headers=headers,
        )

    over_limit = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
    assert over_limit.status_code == 429
    assert over_limit.json()["error"]["code"] == "DAILY_LIMIT_REACHED"


def test_answer_endpoint_rejects_invented_attempt_id_for_already_served_challenge(client):
    """
    Achado de auditoria de segurança CRÍTICO (01/09/2026): antes, POST
    /answer aceitava QUALQUER attempt_id novo (inventado pelo client) e
    criava uma tentativa nova pra ele — dava pra ignorar /next
    completamente e mandar POST /answer em loop, com um attempt_id novo
    a cada vez, pro MESMO challenge_id, gerando XP sem limite algum
    (nem o limite diário barrava, já que cada chamada é uma "tentativa
    nova"). Agora um attempt_id só é válido se tiver sido de fato
    servido pelo servidor (GET /challenges/next ou fluxo de Batalha) —
    qualquer id inventado pra um challenge_id já servido é 404, mesmo
    dentro do limite diário.
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()

    # A primeira resposta, com o attempt_id REAL servido, funciona.
    first = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": challenge["attempt_id"], "submitted_answer": "qualquer"},
        headers=headers,
    )
    assert first.status_code == 200

    # Qualquer tentativa de "responder de novo" o MESMO desafio com um
    # attempt_id inventado (nunca servido pelo servidor) é rejeitada —
    # o farm de XP não pode mais nascer de dentro de /answer sozinho.
    farm_attempt = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": str(uuid.uuid4()), "submitted_answer": "qualquer"},
        headers=headers,
    )
    assert farm_attempt.status_code == 404
    assert farm_attempt.json()["error"]["code"] == "ATTEMPT_NOT_FOUND"


def test_attempt_id_from_another_user_is_rejected(client):
    """
    Achado de auditoria de segurança (28/08/2026): um attempt_id de OUTRO
    usuário era aceito sem checagem de dono — devolvia correct_answer/
    explanation de uma tentativa alheia. Agora responde 404 em vez de
    vazar o resultado do desafio de outra pessoa.
    """
    victim = str(uuid.uuid4())
    attacker = str(uuid.uuid4())
    victim_headers = auth_header(victim)
    attacker_headers = auth_header(attacker)
    client.post("/age-gate", json={"age_confirmed": True}, headers=victim_headers)
    client.post("/age-gate", json={"age_confirmed": True}, headers=attacker_headers)

    victim_challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=victim_headers).json()
    victim_attempt_id = victim_challenge["attempt_id"]

    resp = client.post(
        f"/challenges/{victim_challenge['challenge_id']}/answer",
        json={"attempt_id": victim_attempt_id, "submitted_answer": "qualquer"},
        headers=attacker_headers,
    )
    assert resp.status_code == 404

    hint_resp = client.post(
        f"/challenges/{victim_challenge['challenge_id']}/hint",
        json={"attempt_id": victim_attempt_id},
        headers=attacker_headers,
    )
    assert hint_resp.status_code == 404


def test_endpoints_require_age_confirmation_server_side(client):
    """
    Achado de auditoria de segurança (28/08/2026): a confirmação de
    maioridade era um gate 100% de client — nenhum endpoint do backend
    conferia age_confirmed_at. Um token válido que nunca chamou
    POST /age-gate conseguia jogar, ver ranking, adicionar amigos e
    editar perfil normalmente. Prova que agora isso é recusado no
    servidor (GET /profile continua liberado de propósito — é a própria
    chamada que o client usa pra decidir se mostra a tela de
    confirmação).
    """
    user = str(uuid.uuid4())
    headers = auth_header(user)
    # Nenhum POST /age-gate aqui de propósito.

    profile_resp = client.get("/profile", headers=headers)
    assert profile_resp.status_code == 200
    assert profile_resp.json()["age_confirmed_at"] is None

    next_resp = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
    assert next_resp.status_code == 403
    assert next_resp.json()["error"]["code"] == "AGE_NOT_CONFIRMED"

    ranking_resp = client.get("/ranking", headers=headers)
    assert ranking_resp.status_code == 403

    friends_resp = client.get("/social/friends", headers=headers)
    assert friends_resp.status_code == 403

    put_profile_resp = client.put("/profile", json={"real_name": "Teste", "location_public": False}, headers=headers)
    assert put_profile_resp.status_code == 403

    # Depois de confirmar, os mesmos endpoints voltam a funcionar normalmente.
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    assert client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).status_code == 200


def test_active_subscription_bypasses_daily_limit(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/subscription/parental-gate", headers=headers)
    client.post("/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers)

    for _ in range(DAILY_FREE_CHALLENGE_LIMIT + 1):
        resp = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers)
        assert resp.status_code == 200
        challenge = resp.json()
        client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": challenge["attempt_id"], "submitted_answer": "qualquer"},
            headers=headers,
        )


def test_validate_receipt_requires_parental_gate(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post("/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers)
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "PARENTAL_GATE_REQUIRED"


def test_parental_gate_expires_and_requires_revalidation_per_purchase_attempt(client):
    # Cenário de risco identificado na revisão de Rhoney: adulto passa o
    # gate uma vez; meses depois, uma criança usa o celular já logado e
    # tenta comprar. O gate antigo NÃO pode autorizar essa nova tentativa.
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/subscription/parental-gate", headers=headers)

    from app.config import PARENTAL_GATE_VALIDITY_MINUTES
    from app.db import SessionLocal
    from app import models

    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        profile.parental_gate_passed_at = utcnow() - timedelta(
            minutes=PARENTAL_GATE_VALIDITY_MINUTES + 1
        )
        db.commit()

    resp = client.post(
        "/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers
    )
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "PARENTAL_GATE_EXPIRED"

    # Revalidando o gate agora (nova tentativa de compra), a compra passa.
    client.post("/subscription/parental-gate", headers=headers)
    resp2 = client.post(
        "/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers
    )
    assert resp2.status_code == 200
    assert resp2.json()["status"] == "active"


def test_ranking_never_exposes_email_or_extra_fields(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    from app.seed import CHALLENGES

    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"])
    client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": challenge["attempt_id"], "submitted_answer": correct},
        headers=headers,
    )

    ranking = client.get("/ranking", params={"scope": "global", "window": "weekly"}, headers=headers).json()
    for entry in ranking["entries"]:
        # avatar_id/real_name/photo_url: USER_PROFILE.md, aprovado — nunca
        # expõe e-mail. real_name e photo_url (revisão 26/08/2026) são o
        # mesmo tipo de dado público que nickname já expunha; photo_url
        # ainda passa pelo filtro fail-closed de moderação (services.
        # public_photo_url), nunca o dado bruto. user_id (achado de
        # auditoria/V4 item 1, 02/09/2026): antes NUNCA exposto aqui —
        # passa a ser exposto de propósito porque PERFIL_PUBLICO_E_
        # TORCIDA_V1.md §3 autoriza explicitamente o Ranking como ponto
        # de entrada pro perfil público de outro usuário, que precisa
        # do id pra existir. Ainda assim, nada além desses 7 campos.
        assert set(entry.keys()) == {"rank", "user_id", "nickname", "avatar_id", "real_name", "photo_url", "xp"}
        assert user not in entry["nickname"]  # nickname nunca contém o user_id bruto
