"""
MUNDO_IDIOMAS_REPETICAO_ESPACADA_V1.md — força de memória por
usuário+desafio, agnóstica a Mundo/território. Schedule fixo crescente
(Leitner-like): acerto sem dica avança repetitions e cresce o intervalo
([1, 3, 7, 14, 30, 60] dias); erro OU uso de dica reseta pra
repetitions=0 (intervalo volta a 1 dia).

GET /challenges/review/next serve o item vencido mais atrasado (mesma
autoridade de GET /challenges/next); GET /challenges/review/count só
conta, sem servir nada.
"""

import uuid
from datetime import timedelta

from app import config, models
from app.db import SessionLocal
from app.timeutil import utcnow

from .conftest import auth_header


def _answer(client, headers, challenge, submitted_answer):
    return client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": challenge["attempt_id"], "submitted_answer": submitted_answer},
        headers=headers,
    )


def _correct_answer_for(challenge):
    from app.seed import CHALLENGES

    return next(
        c["correct_answer"]
        for c in CHALLENGES
        if c["territory_id"] == challenge["territory_id"] and c["prompt"] == challenge["prompt"]
    )


def test_correct_answer_without_hint_creates_record_due_in_one_day(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    correct = _correct_answer_for(challenge)
    resp = _answer(client, headers, challenge, correct)
    assert resp.status_code == 200

    with SessionLocal() as db:
        item = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), challenge["challenge_id"]))
        assert item is not None
        assert item.repetitions == 1
        assert item.interval_days == 1
        assert item.territory_id == "numeros"
        assert item.next_due_at - item.last_reviewed_at == timedelta(days=1)


def test_wrong_answer_creates_record_with_zero_repetitions(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    _answer(client, headers, challenge, "__resposta_propositalmente_errada__")

    with SessionLocal() as db:
        item = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), challenge["challenge_id"]))
        assert item is not None
        assert item.repetitions == 0
        assert item.interval_days == 1


def test_hint_used_resets_repetitions_even_if_answer_is_correct(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    correct = _correct_answer_for(challenge)
    hint_resp = client.post(
        f"/challenges/{challenge['challenge_id']}/hint",
        json={"attempt_id": challenge["attempt_id"]},
        headers=headers,
    )
    assert hint_resp.status_code == 200
    _answer(client, headers, challenge, correct)

    with SessionLocal() as db:
        item = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), challenge["challenge_id"]))
        assert item is not None
        assert item.repetitions == 0
        assert item.interval_days == 1


def test_consecutive_correct_answers_grow_the_interval_along_the_schedule(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    correct = _correct_answer_for(challenge)
    _answer(client, headers, challenge, correct)

    # Simula o intervalo já ter passado (sem esperar dias de verdade) pra
    # poder revisar o mesmo item de novo via GET /challenges/review/next.
    for expected_interval in (3, 7, 14):
        with SessionLocal() as db:
            item = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), challenge["challenge_id"]))
            item.next_due_at = utcnow() - timedelta(minutes=1)
            db.commit()

        due = client.get("/challenges/review/next", headers=headers).json()
        assert due["has_due"] is True
        assert due["challenge"]["challenge_id"] == challenge["challenge_id"]
        _answer(client, headers, due["challenge"], correct)

        with SessionLocal() as db:
            item = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), challenge["challenge_id"]))
            assert item.interval_days == expected_interval


def test_review_next_has_due_false_when_nothing_is_due(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get("/challenges/review/next", headers=headers).json()
    assert resp == {"has_due": False, "challenge": None, "due_count": 0}


def test_review_next_serves_the_most_overdue_item(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    c1 = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    _answer(client, headers, c1, _correct_answer_for(c1))
    c2 = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    _answer(client, headers, c2, _correct_answer_for(c2))

    with SessionLocal() as db:
        item1 = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), c1["challenge_id"]))
        item1.next_due_at = utcnow() - timedelta(days=5)
        item2 = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), c2["challenge_id"]))
        item2.next_due_at = utcnow() - timedelta(days=1)
        db.commit()

    due = client.get("/challenges/review/next", headers=headers).json()
    assert due["has_due"] is True
    assert due["due_count"] == 2
    # item1 está vencido há mais tempo — serve primeiro.
    assert due["challenge"]["challenge_id"] == c1["challenge_id"]


def test_review_count_endpoint_matches_review_next_due_count(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    _answer(client, headers, challenge, _correct_answer_for(challenge))

    with SessionLocal() as db:
        item = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), challenge["challenge_id"]))
        item.next_due_at = utcnow() - timedelta(minutes=1)
        db.commit()

    count_resp = client.get("/challenges/review/count", headers=headers).json()
    assert count_resp == {"due_count": 1}


def test_answering_a_due_review_item_grants_normal_xp_not_zero(client):
    """Diferente do REGRA_REVISAO_ERROS_FIM_RODADA.md (is_review=True,
    XP zero) — revisão espaçada é um encontro novo, legítimo, em outro
    dia, e paga o XP normal da pergunta (a recompensa de SESSÃO de
    revisão, essa sim, fica pra quando a Regra Oficial de Gamificação
    for atualizada, doc §5)."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    _answer(client, headers, challenge, _correct_answer_for(challenge))

    with SessionLocal() as db:
        item = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), challenge["challenge_id"]))
        item.next_due_at = utcnow() - timedelta(minutes=1)
        db.commit()

    due = client.get("/challenges/review/next", headers=headers).json()
    resp = _answer(client, headers, due["challenge"], _correct_answer_for(challenge))
    result = resp.json()
    assert resp.status_code == 200
    assert result["is_correct"] is True
    assert result["xp_awarded"] > 0


def test_calling_review_next_repeatedly_without_answering_reuses_the_same_attempt_and_grants_no_extra_batch_bonus(client):
    """Achado CRÍTICO da auditoria de segurança (02/10/2026): sem a
    correção, cada chamada a GET /challenges/review/next criava um
    Attempt NOVO pro MESMO item vencido, e rewards.on_batch_completed
    pagava +3 XP de bônus de lote por attempt_id — farm de XP
    ilimitado chamando o endpoint em loop sem nunca responder nada."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    _answer(client, headers, challenge, _correct_answer_for(challenge))

    with SessionLocal() as db:
        item = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), challenge["challenge_id"]))
        item.next_due_at = utcnow() - timedelta(minutes=1)
        db.commit()
        xp_before = db.get(models.Profile, user.replace("-", "")).xp_total

    attempt_ids = set()
    for _ in range(5):
        due = client.get("/challenges/review/next", headers=headers).json()
        assert due["has_due"] is True
        assert due["challenge"]["challenge_id"] == challenge["challenge_id"]
        attempt_ids.add(due["challenge"]["attempt_id"])

    # As 5 chamadas, sem nenhuma resposta entre elas, devolvem o MESMO
    # attempt_id — nunca um novo Attempt por chamada.
    assert len(attempt_ids) == 1

    with SessionLocal() as db:
        xp_after = db.get(models.Profile, user.replace("-", "")).xp_total
        pending_count = (
            db.query(models.Attempt)
            .filter(
                models.Attempt.user_id == user.replace("-", ""),
                models.Attempt.challenge_id == challenge["challenge_id"],
                models.Attempt.is_spaced_review.is_(True),
            )
            .count()
        )
    # Nenhum XP pago só por SERVIR a revisão repetidamente (só responder
    # paga XP), e só existe UM Attempt de revisão pra este item na base.
    assert xp_after == xp_before
    assert pending_count == 1


def test_answering_a_spaced_review_item_grants_no_batch_completion_bonus(client):
    """Mesmo achado CRÍTICO — mesmo respondendo de verdade (não só
    servindo em loop), o bônus de lote (+3/+5 XP) não deve se aplicar a
    uma revisão de item único (não existe "lote" aqui, igual a busca)."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    correct = _correct_answer_for(challenge)
    _answer(client, headers, challenge, correct)

    with SessionLocal() as db:
        item = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), challenge["challenge_id"]))
        item.next_due_at = utcnow() - timedelta(minutes=1)
        db.commit()
        xp_before = db.get(models.Profile, user.replace("-", "")).xp_total

    due = client.get("/challenges/review/next", headers=headers).json()
    resp = _answer(client, headers, due["challenge"], correct)
    xp_awarded = resp.json()["xp_awarded"]

    with SessionLocal() as db:
        xp_after = db.get(models.Profile, user.replace("-", "")).xp_total
        batch_claim = (
            db.query(models.RewardClaim)
            .filter(models.RewardClaim.claim_key == f"batch:{due['challenge']['attempt_id']}")
            .first()
        )

    # Só o XP normal da pergunta (nenhum +3/+5 de bônus de lote somado),
    # e nenhum claim de bônus de lote foi registrado pra este attempt.
    assert xp_after == xp_before + xp_awarded
    assert batch_claim is None


def test_blocked_territory_item_is_skipped_but_never_deleted(client, monkeypatch):
    """Achados MÉDIO da auditoria de segurança (02/10/2026): item de
    território bloqueado (assinatura exigida, amostra grátis esgotada)
    não aparece em GET /challenges/review/next, mas continua existindo
    no banco — apagar destruiria de vez o histórico de quem renovar a
    assinatura depois."""
    import app.services as services_module

    monkeypatch.setattr(services_module.config, "MONETIZATION_ENABLED", True)

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    # 'logica' tem free_sample_count=2 no seed — as 2 respostas abaixo
    # consomem a amostra inteira, travando o território imediatamente.
    challenge = None
    for _ in range(2):
        challenge = client.get("/challenges/next", params={"territory_id": "logica"}, headers=headers).json()
        client.post(
            f"/challenges/{challenge['challenge_id']}/answer",
            json={"attempt_id": challenge["attempt_id"], "submitted_answer": "qualquer"},
            headers=headers,
        )

    with SessionLocal() as db:
        item = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), challenge["challenge_id"]))
        assert item is not None
        item.next_due_at = utcnow() - timedelta(minutes=1)
        db.commit()

    due = client.get("/challenges/review/next", headers=headers).json()
    assert due["has_due"] is False

    with SessionLocal() as db:
        item_after = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), challenge["challenge_id"]))
        assert item_after is not None, "o item não deveria ser apagado só por o território estar bloqueado"


def test_due_items_are_isolated_between_users(client):
    """Isolamento entre usuários — item vencido de A nunca aparece na
    fila nem na contagem de B."""
    user_a = str(uuid.uuid4())
    user_b = str(uuid.uuid4())
    headers_a = auth_header(user_a)
    headers_b = auth_header(user_b)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_a)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers_b)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers_a).json()
    _answer(client, headers_a, challenge, _correct_answer_for(challenge))

    with SessionLocal() as db:
        item = db.get(models.SpacedRepetitionItem, (user_a.replace("-", ""), challenge["challenge_id"]))
        item.next_due_at = utcnow() - timedelta(minutes=1)
        db.commit()

    due_for_b = client.get("/challenges/review/next", headers=headers_b).json()
    count_for_b = client.get("/challenges/review/count", headers=headers_b).json()
    assert due_for_b == {"has_due": False, "challenge": None, "due_count": 0}
    assert count_for_b == {"due_count": 0}

    due_for_a = client.get("/challenges/review/next", headers=headers_a).json()
    assert due_for_a["has_due"] is True


def test_review_next_respects_the_daily_limit(client, monkeypatch):
    monkeypatch.setattr(config, "DAILY_FREE_CHALLENGE_LIMIT", 1)
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    _answer(client, headers, challenge, _correct_answer_for(challenge))  # consome o único slot diário

    with SessionLocal() as db:
        item = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), challenge["challenge_id"]))
        item.next_due_at = utcnow() - timedelta(minutes=1)
        db.commit()

    resp = client.get("/challenges/review/next", headers=headers)
    assert resp.status_code == 429
    assert resp.json()["error"]["code"] == "DAILY_LIMIT_REACHED"


def test_end_of_round_reattempt_does_not_touch_the_spaced_repetition_schedule(client):
    """attempt.is_review=True (REGRA_REVISAO_ERROS_FIM_RODADA.md, reforço
    imediato dentro da mesma rodada) nunca passa pelo caminho que
    atualiza a força de memória — só attempts reais (is_review=False)
    alimentam o schedule de longo prazo."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge = client.get("/challenges/next", params={"territory_id": "numeros"}, headers=headers).json()
    correct = _correct_answer_for(challenge)
    _answer(client, headers, challenge, "__errado_de_proposito__")

    with SessionLocal() as db:
        item_after_wrong = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), challenge["challenge_id"]))
        reviewed_at_before = item_after_wrong.last_reviewed_at

    reattempted = client.get(f"/challenges/{challenge['challenge_id']}/reattempt", headers=headers).json()
    _answer(client, headers, reattempted, correct)

    with SessionLocal() as db:
        item_after_reattempt = db.get(models.SpacedRepetitionItem, (user.replace("-", ""), challenge["challenge_id"]))
        # Não mudou por causa do reattempt (nem repetitions, nem o
        # timestamp de última revisão) — a revisão imediata de fim de
        # rodada é um mecanismo totalmente separado deste.
        assert item_after_reattempt.repetitions == 0
        assert item_after_reattempt.last_reviewed_at == reviewed_at_before
