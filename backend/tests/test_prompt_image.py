"""
CONHECIMENTO_CONTEUDO_GERAL_E_IMAGEM.md §3 (aprovado): enriquecimento
visual opcional (emoji) por desafio. prompt_image é sempre opcional —
None na grande maioria dos desafios, sem quebrar nada.
"""

import uuid

from app.db import SessionLocal
from app import models

from .conftest import auth_header


def _insert_challenge_with_image(prompt_image: str | None) -> str:
    with SessionLocal() as db:
        challenge = models.Challenge(
            territory_id="conhecimento",
            difficulty_level=1,
            prompt=f"Pergunta de teste com imagem {uuid.uuid4()}",
            options=["A", "B", "C", "D"],
            correct_answer="A",
            explanation="x",
            age_reviewed=True,
            prompt_image=prompt_image,
        )
        db.add(challenge)
        db.commit()
        db.refresh(challenge)
        return challenge.id


def test_prompt_image_travels_through_next_challenge(client):
    challenge_id = _insert_challenge_with_image("🏛️")
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    # Força repetidamente até o sorteio pegar exatamente esse desafio
    # (território tem outros também) — nunca deve falhar em algumas
    # tentativas dado tamanho pequeno do pool de teste.
    for _ in range(50):
        body = client.get("/challenges/next", params={"territory_id": "conhecimento"}, headers=headers).json()
        if body["challenge_id"] == challenge_id:
            assert body["prompt_image"] == "🏛️"
            return
    raise AssertionError("nunca sorteou o desafio com imagem em 50 tentativas")


def test_prompt_image_is_none_by_default(client):
    challenge_id = _insert_challenge_with_image(None)
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    for _ in range(50):
        body = client.get("/challenges/next", params={"territory_id": "conhecimento"}, headers=headers).json()
        if body["challenge_id"] == challenge_id:
            assert body["prompt_image"] is None
            return
    raise AssertionError("nunca sorteou o desafio sem imagem em 50 tentativas")
