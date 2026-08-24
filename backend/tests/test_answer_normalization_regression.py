"""
Regressão para BUGS_TEST_REPORT_01.md.

Bug 1 (causa raiz real: client Flutter, não backend — botão "Confirmar
resposta" não reavaliava após digitar por falta de setState no
TextField.onChanged, corrigido em challenge_screen.dart) é coberto aqui
indiretamente: estes testes provam que o BACKEND sempre reconhece a
resposta correta já na primeira tentativa, sem depender de dica alguma —
eliminando a hipótese (já descartada por leitura de código, aqui
confirmada por teste) de que o backend exigisse algum estado prévio.

Bug 2 (case-insensitive + espaços): já implementado
(`submitted_answer.strip().lower() == correct_answer.strip().lower()`
em routers/challenges.py) — travado aqui explicitamente nos 4 tipos de
desafio (Palavras, Números, Lógica, Conhecimento), não só no território
onde foi observado.
"""

import uuid

import pytest

from .conftest import auth_header

TERRITORIES = ["palavras", "numeros", "logica", "conhecimento"]


def _get_challenge_and_answer(client, headers, territory_id):
    from app.seed import CHALLENGES

    challenge = client.get("/challenges/next", params={"territory_id": territory_id}, headers=headers).json()
    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == challenge["prompt"])
    return challenge, correct


@pytest.mark.parametrize("territory_id", TERRITORIES)
def test_correct_answer_recognized_on_first_attempt_without_any_hint(client, territory_id):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge, correct = _get_challenge_and_answer(client, headers, territory_id)

    result = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": str(uuid.uuid4()), "submitted_answer": correct},
        headers=headers,
    ).json()

    assert result["is_correct"] is True, f"resposta correta não reconhecida na 1ª tentativa em {territory_id}"
    assert result["hints_used"] == 0
    assert result["xp_awarded"] > 0


@pytest.mark.parametrize("territory_id", TERRITORIES)
def test_answer_comparison_is_case_insensitive(client, territory_id):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge, correct = _get_challenge_and_answer(client, headers, territory_id)

    result = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": str(uuid.uuid4()), "submitted_answer": correct.lower()},
        headers=headers,
    ).json()
    assert result["is_correct"] is True, f"minúsculo não reconhecido em {territory_id}"

    challenge2, correct2 = _get_challenge_and_answer(client, headers, territory_id)
    result2 = client.post(
        f"/challenges/{challenge2['challenge_id']}/answer",
        json={"attempt_id": str(uuid.uuid4()), "submitted_answer": correct2.upper()},
        headers=headers,
    ).json()
    assert result2["is_correct"] is True, f"maiúsculo não reconhecido em {territory_id}"


@pytest.mark.parametrize("territory_id", TERRITORIES)
def test_answer_comparison_trims_whitespace(client, territory_id):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    challenge, correct = _get_challenge_and_answer(client, headers, territory_id)

    result = client.post(
        f"/challenges/{challenge['challenge_id']}/answer",
        json={"attempt_id": str(uuid.uuid4()), "submitted_answer": f"  {correct}  "},
        headers=headers,
    ).json()
    assert result["is_correct"] is True, f"espaço nas pontas não tolerado em {territory_id}"
