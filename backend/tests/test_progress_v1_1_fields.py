"""
V1.1: /progress precisa expor conquest_threshold e xp_per_level — o client
(TerritoryProgress, ProgressScreen) usa esses valores pra desenhar a
barra de progresso por território sem duplicar o número mágico (mesmo
raciocínio já aplicado a DAILY_FREE_CHALLENGE_LIMIT e outras constantes
centralizadas em config.py).
"""

import uuid

from app.config import CONQUEST_XP_THRESHOLD, XP_PER_LEVEL

from .conftest import auth_header


def test_progress_exposes_conquest_threshold_and_xp_per_level(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_mode": "adult"}, headers=headers)

    progress = client.get("/progress", headers=headers).json()

    assert progress["xp_per_level"] == XP_PER_LEVEL
    for territory in progress["territories"]:
        assert territory["conquest_threshold"] == CONQUEST_XP_THRESHOLD
