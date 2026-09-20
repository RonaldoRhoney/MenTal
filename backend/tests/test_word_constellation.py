"""
MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md (19/09/2026) — etapa
complementar automática ao final de todo Desafio do Mundo dos Idiomas,
gerada a partir do próprio conteúdo do Desafio (correct_answer com
espaço vira reconstrução por peças; sem espaço vira reconhecimento de
significado). XP só na primeira conclusão CORRETA por (usuário,
desafio) — nunca atalho fácil repetindo.
"""

import uuid

from app import config, models
from app.db import SessionLocal

from .conftest import auth_header


def _seed_idiomas_challenge(prompt: str, correct_answer: str, territory_id: str = "ingles_basico") -> str:
    with SessionLocal() as db:
        challenge = models.Challenge(
            territory_id=territory_id,
            difficulty_level=1,
            prompt=prompt,
            options=[correct_answer, "x", "y", "z"],
            correct_answer=correct_answer,
            explanation="x",
            age_reviewed=True,
        )
        db.add(challenge)
        db.commit()
        db.refresh(challenge)
        return challenge.id


def _seed_siblings(territory_id: str = "ingles_basico") -> None:
    # Distratores — outras palavras/frases do mesmo território.
    _seed_idiomas_challenge("Como se escreve 'gato' em inglês?", "Cat", territory_id)
    _seed_idiomas_challenge("Como se escreve 'cachorro' em inglês?", "Dog", territory_id)
    _seed_idiomas_challenge("Como se escreve 'pássaro' em inglês?", "Bird", territory_id)
    _seed_idiomas_challenge("Como se escreve 'peixe' em inglês?", "Fish", territory_id)
    _seed_idiomas_challenge("Traduza para o inglês: 'O gato é pequeno.'", "The cat is small", territory_id)


def test_word_constellation_pieces_for_multi_word_correct_answer(client):
    _seed_siblings()
    challenge_id = _seed_idiomas_challenge("Traduza para o inglês: 'A casa é grande.'", "The house is big")
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get(f"/challenges/{challenge_id}/word-constellation", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["kind"] == "pieces"
    assert body["options"] is None
    assert set(body["tiles"]) >= {"The", "house", "is", "big"}
    # Peças embaralhadas com distratores — mais peças do que as 4 corretas.
    assert len(body["tiles"]) > 4


def test_word_constellation_meaning_for_single_word_correct_answer(client):
    _seed_siblings()
    challenge_id = _seed_idiomas_challenge("Como se escreve 'casa' em inglês?", "House")
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get(f"/challenges/{challenge_id}/word-constellation", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["kind"] == "meaning"
    assert body["tiles"] is None
    # Áudio nas opções (20/09/2026): enunciado em português, opções são
    # palavras do idioma estudado (a correta + de outros Desafios).
    assert body["prompt_text"] == "casa"
    assert "House" in body["options"]
    assert len(body["options"]) == 4
    assert len(set(o.lower() for o in body["options"])) == 4  # sem repetidas


def test_word_constellation_meaning_extracts_word_with_parenthetical_clarifier(client):
    """Achado real em produção (19/09/2026): ~55 prompts reais de
    Idiomas têm um esclarecimento entre a palavra e "em <idioma>"
    (ex.: "'preciso' (necessidade) em inglês?"), quebrando a suposição
    original de "100% dos prompts seguem 2 templates fixos". Antes desta
    correção, esses Desafios travavam a Constelação de Palavras com
    MEANING_NOT_EXTRACTABLE — nunca devem quebrar a extração."""
    _seed_siblings()
    challenge_id = _seed_idiomas_challenge("Como se escreve 'preciso' (necessidade) em inglês?", "Need")
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get(f"/challenges/{challenge_id}/word-constellation", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["kind"] == "meaning"
    assert body["prompt_text"] == "preciso"
    assert "Need" in body["options"]


def test_word_constellation_complete_correct_awards_xp_only_once(client):
    _seed_siblings()
    challenge_id = _seed_idiomas_challenge("Como se escreve 'casa' em inglês?", "House")
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp1 = client.post(
        f"/challenges/{challenge_id}/word-constellation/complete",
        json={"submitted_meaning": "House"},
        headers=headers,
    )
    assert resp1.status_code == 200
    body1 = resp1.json()
    assert body1["correct"] is True
    assert body1["xp_awarded"] == config.WORD_CONSTELLATION_XP_REWARD

    # Repetir a mesma rodada de novo — continua "correct", mas sem XP de novo.
    resp2 = client.post(
        f"/challenges/{challenge_id}/word-constellation/complete",
        json={"submitted_meaning": "House"},
        headers=headers,
    )
    assert resp2.status_code == 200
    body2 = resp2.json()
    assert body2["correct"] is True
    assert body2["xp_awarded"] == 0


def test_word_constellation_complete_wrong_answer_never_awards_xp(client):
    _seed_siblings()
    challenge_id = _seed_idiomas_challenge("Como se escreve 'casa' em inglês?", "House")
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.post(
        f"/challenges/{challenge_id}/word-constellation/complete",
        json={"submitted_meaning": "Cat"},
        headers=headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["correct"] is False
    assert body["xp_awarded"] == 0


def test_word_constellation_pieces_complete_validates_word_order(client):
    _seed_siblings()
    challenge_id = _seed_idiomas_challenge("Traduza para o inglês: 'A casa é grande.'", "The house is big")
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    wrong_order = client.post(
        f"/challenges/{challenge_id}/word-constellation/complete",
        json={"submitted_order": ["big", "house", "The", "is"]},
        headers=headers,
    )
    assert wrong_order.json()["correct"] is False

    right_order = client.post(
        f"/challenges/{challenge_id}/word-constellation/complete",
        json={"submitted_order": ["The", "house", "is", "big"]},
        headers=headers,
    )
    assert right_order.json()["correct"] is True
    assert right_order.json()["xp_awarded"] == config.WORD_CONSTELLATION_XP_REWARD


def test_word_constellation_404_outside_idiomas_territory(client):
    with SessionLocal() as db:
        challenge = models.Challenge(
            territory_id="numeros",
            difficulty_level=1,
            prompt="Quanto é 2+2?",
            options=["3", "4", "5", "6"],
            correct_answer="4",
            explanation="x",
            age_reviewed=True,
        )
        db.add(challenge)
        db.commit()
        db.refresh(challenge)
        challenge_id = challenge.id

    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get(f"/challenges/{challenge_id}/word-constellation", headers=headers)
    assert resp.status_code == 404


def test_word_constellation_round_exposes_image_and_credit(client):
    # Ilustração de vocabulário (Canva/Twemoji) só aparece com o crédito
    # da licença junto — o cliente mostra como legenda (CC-BY exige).
    _seed_siblings()
    challenge_id = _seed_idiomas_challenge("Como se escreve 'maçã' em inglês?", "Apple")
    with SessionLocal() as db:
        challenge = db.get(models.Challenge, challenge_id)
        challenge.vocab_media_url = "https://example.supabase.co/storage/v1/object/public/vocab-media/x.webp"
        challenge.vocab_media_type = "image"
        challenge.vocab_media_source_name = "Twemoji (jdecked) — CC-BY 4.0"
        challenge.vocab_media_source_url = "https://github.com/jdecked/twemoji"
        db.commit()
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get(f"/challenges/{challenge_id}/word-constellation", headers=headers).json()
    assert body["vocab_media_url"].endswith("x.webp")
    assert body["vocab_media_source_name"] == "Twemoji (jdecked) — CC-BY 4.0"


def test_word_constellation_meaning_options_never_include_synonyms(client):
    # Sinônimo (mesmo significado em português) como distrator tornaria a
    # rodada injusta — duas respostas certas. Ele nunca entra nas opções.
    _seed_siblings()
    _seed_idiomas_challenge("Como se escreve 'rápido' em inglês?", "Quick")
    challenge_id = _seed_idiomas_challenge("Como se escreve 'rápido' em inglês?", "Fast")
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    for _ in range(8):  # distratores são sorteados
        body = client.get(f"/challenges/{challenge_id}/word-constellation", headers=headers).json()
        assert "Quick" not in body["options"]
        assert "Fast" in body["options"]
