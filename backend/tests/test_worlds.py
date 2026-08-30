"""
V2 item 10 — Mundos completos (V2_KICKOFF.md §2/§6A). "Mundo completo"
nunca é armazenado — é sempre derivado de UserTerritoryProgress.
conquered_at (mesmo raciocínio já usado em badges/_all_territories_
conquered). Estes testes provam o agrupamento correto e a transição
exata do sinal world_just_completed (dispara uma vez, nunca de novo).
"""

import uuid

from app import config

from .conftest import auth_header


def _answer_correctly(client, headers, territory_id):
    from app.seed import CHALLENGES

    challenge = client.get("/challenges/next", params={"territory_id": territory_id}, headers=headers).json()
    correct = next(
        c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"] and (challenge["options"] is None or sorted(c["options"] or []) == sorted(challenge["options"]))
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


def test_progress_groups_territories_into_the_approved_worlds(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    progress = client.get("/progress", headers=headers).json()
    worlds = {w["world_id"]: w for w in progress["worlds"]}

    # V3.0 (V3.0_ESPORTES_REGIOES_CULTURA_POP.md) acrescenta o Mundo da
    # Cultura Geral (esportes/regioes/cultura_pop) aos dois mundos
    # originais. V3.0.1 (cores) entra em Mente Lógica; V3.1 (mitologia/
    # enem/concursos) entra em Cultura Geral, junto dos demais
    # territórios de trivia.
    assert set(worlds.keys()) == {"linguagem", "mente_logica", "cultura_geral"}
    assert set(worlds["linguagem"]["territory_ids"]) == {"palavras", "textos", "enigmas"}
    assert set(worlds["mente_logica"]["territory_ids"]) == {"numeros", "logica", "visual", "conhecimento", "cores"}
    assert set(worlds["cultura_geral"]["territory_ids"]) == {
        "esportes", "regioes", "cultura_pop",
        "mitologia_grega", "mitologia_nordica", "mitologia_indigena",
        "enem_linguagens", "enem_humanas", "enem_natureza", "enem_matematica",
        "concursos_portugues", "concursos_raciocinio", "concursos_direito",
    }
    assert worlds["linguagem"]["completed"] is False
    assert worlds["mente_logica"]["completed"] is False
    assert worlds["cultura_geral"]["completed"] is False


def test_world_just_completed_fires_once_at_the_exact_last_territory(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
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

    xp_before_completion = client.get("/progress", headers=headers).json()["xp_total"]

    # Última resposta correta em "enigmas" fecha os 3 territórios do
    # Mundo da Linguagem — world_just_completed deve disparar EXATAMENTE
    # nessa resposta, nunca antes.
    world_completed_events = []
    completing_result = None
    for _ in range(30):
        progress = client.get("/progress", headers=headers).json()
        enigmas = next(t for t in progress["territories"] if t["territory_id"] == "enigmas")
        if enigmas["conquered"]:
            break
        result = _answer_correctly(client, headers, "enigmas")
        world_completed_events.append(result["world_just_completed"])
        if result["world_just_completed"]:
            assert result["completed_world_name"] == "Mundo da Linguagem"
            completing_result = result

    assert world_completed_events.count(True) == 1

    # V2 item 11 — bônus fixo de XP e badge de mundo, na MESMA resposta
    # que fecha o mundo (reaproveita o sistema de badges do item 1).
    assert completing_result["world_completion_bonus_xp"] == config.WORLD_COMPLETION_BONUS_XP
    xp_after_completion = client.get("/progress", headers=headers).json()["xp_total"]
    assert xp_after_completion - xp_before_completion >= config.WORLD_COMPLETION_BONUS_XP
    badge_codes_awarded = {b["code"] for b in completing_result["newly_awarded_badges"]}
    assert "world_master_linguagem" in badge_codes_awarded

    progress = client.get("/progress", headers=headers).json()
    assert next(w for w in progress["worlds"] if w["world_id"] == "linguagem")["completed"] is True
    # O outro mundo não foi tocado — continua incompleto, sem interferência.
    assert next(w for w in progress["worlds"] if w["world_id"] == "mente_logica")["completed"] is False

    # Continuar respondendo em "enigmas" (já conquistado) nunca dispara o
    # sinal de novo — mundo já fechado, não é evento novo.
    result = _answer_correctly(client, headers, "enigmas")
    assert result["world_just_completed"] is False
