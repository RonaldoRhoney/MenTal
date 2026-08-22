"""
V2 item 10 — Mundos completos (V2_KICKOFF.md §2/§6A). "Mundo completo"
nunca é armazenado — é sempre derivado de UserTerritoryProgress.
conquered_at (mesmo raciocínio já usado em badges/_all_territories_
conquered). Estes testes provam o agrupamento correto e a transição
exata do sinal world_just_completed (dispara uma vez, nunca de novo).
"""

import uuid

from .conftest import auth_header


def _answer_correctly(client, headers, territory_id):
    from app.seed import CHALLENGES

    challenge = client.get("/challenges/next", params={"territory_id": territory_id}, headers=headers).json()
    correct = next(
        c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"] and c["options"] == challenge["options"]
    )
    attempt_id = str(uuid.uuid4())
    return client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": attempt_id, "submitted_answer": correct},
        headers=headers,
    ).json()


def _conquer_territory(client, headers, territory_id, max_iterations=30):
    for _ in range(max_iterations):
        progress = client.get("/progress", headers=headers).json()
        territory = next(t for t in progress["territories"] if t["territory_id"] == territory_id)
        if territory["conquered"]:
            return
        _answer_correctly(client, headers, territory_id)
    raise AssertionError(f"{territory_id} não conquistado em {max_iterations} tentativas")


def test_progress_groups_territories_into_the_two_approved_worlds(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    progress = client.get("/progress", headers=headers).json()
    worlds = {w["world_id"]: w for w in progress["worlds"]}

    assert set(worlds.keys()) == {"linguagem", "mente_logica"}
    assert set(worlds["linguagem"]["territory_ids"]) == {"palavras", "textos", "enigmas"}
    assert set(worlds["mente_logica"]["territory_ids"]) == {"numeros", "logica", "visual", "conhecimento"}
    assert worlds["linguagem"]["completed"] is False
    assert worlds["mente_logica"]["completed"] is False


def test_world_just_completed_fires_once_at_the_exact_last_territory(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)
    # Conquistar 3 territórios facilmente ultrapassa o limite diário
    # gratuito (24/dia) — assinatura ativa contorna o limite, mesmo
    # padrão de test_active_subscription_bypasses_daily_limit. Não é o
    # que este teste verifica; é só infraestrutura pra ter respostas
    # suficientes.
    client.post("/subscription/parental-gate", headers=headers)
    client.post("/subscription/validate-receipt", json={"purchase_token": "TEST_TOKEN_VALID"}, headers=headers)

    # Mundo da Linguagem tem só 3 territórios (palavras/textos/enigmas) —
    # o menor dos dois, mais rápido de fechar num teste.
    _conquer_territory(client, headers, "palavras")
    progress = client.get("/progress", headers=headers).json()
    assert next(w for w in progress["worlds"] if w["world_id"] == "linguagem")["completed"] is False

    _conquer_territory(client, headers, "textos")
    progress = client.get("/progress", headers=headers).json()
    assert next(w for w in progress["worlds"] if w["world_id"] == "linguagem")["completed"] is False

    # Última resposta correta em "enigmas" fecha os 3 territórios do
    # Mundo da Linguagem — world_just_completed deve disparar EXATAMENTE
    # nessa resposta, nunca antes.
    world_completed_events = []
    for _ in range(30):
        progress = client.get("/progress", headers=headers).json()
        enigmas = next(t for t in progress["territories"] if t["territory_id"] == "enigmas")
        if enigmas["conquered"]:
            break
        result = _answer_correctly(client, headers, "enigmas")
        world_completed_events.append(result["world_just_completed"])
        if result["world_just_completed"]:
            assert result["completed_world_name"] == "Mundo da Linguagem"

    assert world_completed_events.count(True) == 1

    progress = client.get("/progress", headers=headers).json()
    assert next(w for w in progress["worlds"] if w["world_id"] == "linguagem")["completed"] is True
    # O outro mundo não foi tocado — continua incompleto, sem interferência.
    assert next(w for w in progress["worlds"] if w["world_id"] == "mente_logica")["completed"] is False

    # Continuar respondendo em "enigmas" (já conquistado) nunca dispara o
    # sinal de novo — mundo já fechado, não é evento novo.
    result = _answer_correctly(client, headers, "enigmas")
    assert result["world_just_completed"] is False
