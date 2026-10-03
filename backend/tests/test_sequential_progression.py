"""
MUNDO_IDIOMAS_PROGRESSAO_POR_FASE_V1.md — desbloqueio sequencial por
família de território (Básico → Intermediário → Avançado), detectado só
pelo padrão de nomenclatura do territory_id (nunca world_id/block_id
hardcoded). Hoje só o Mundo dos Idiomas tem essa estrutura, mas o
mecanismo em si não é restrito a ele.

Família usada nos testes: ingles_phrasal_{basico,intermediario,avancado}
+ variantes _relampago_.
"""

import uuid

from sqlalchemy import select

from app import models
from app.db import SessionLocal
from app.timeutil import utcnow

from .conftest import auth_header


def _conquer_territory(user_id: str, territory_id: str) -> None:
    """Marca o território como conquistado direto no banco — mais simples
    e mais rápido que simular XP suficiente via respostas reais, já que o
    foco destes testes é o gate de sequência, não o cálculo de conquista
    em si (coberto em outro lugar)."""
    with SessionLocal() as db:
        progress = db.get(models.UserTerritoryProgress, (user_id, territory_id))
        if progress is None:
            progress = models.UserTerritoryProgress(user_id=user_id, territory_id=territory_id)
            db.add(progress)
        progress.conquered_at = utcnow()
        db.commit()


def test_progress_shows_basico_but_hides_intermediario_and_avancado_before_conquest(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    progress = client.get("/progress", headers=headers).json()
    by_id = {t["territory_id"]: t for t in progress["territories"]}

    assert by_id["ingles_phrasal_basico"]["visible"] is True
    assert by_id["ingles_phrasal_relampago_basico"]["visible"] is True
    assert by_id["ingles_phrasal_intermediario"]["visible"] is False
    assert by_id["ingles_phrasal_relampago_intermediario"]["visible"] is False
    assert by_id["ingles_phrasal_avancado"]["visible"] is False


def test_conquering_basico_reveals_intermediario_but_not_avancado(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    user_db_id = user.replace("-", "")

    _conquer_territory(user_db_id, "ingles_phrasal_basico")

    progress = client.get("/progress", headers=headers).json()
    by_id = {t["territory_id"]: t for t in progress["territories"]}

    assert by_id["ingles_phrasal_intermediario"]["visible"] is True
    assert by_id["ingles_phrasal_relampago_intermediario"]["visible"] is True
    assert by_id["ingles_phrasal_avancado"]["visible"] is False
    assert by_id["ingles_phrasal_relampago_avancado"]["visible"] is False


def test_conquering_relampago_basico_alone_does_not_reveal_intermediario(client):
    """Relâmpago desbloqueia JUNTO com o normal do mesmo nível, mas quem
    abre o próximo nível é sempre o território NORMAL conquistado —
    conquistar só o Relâmpago do nível atual não basta."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    user_db_id = user.replace("-", "")

    _conquer_territory(user_db_id, "ingles_phrasal_relampago_basico")

    progress = client.get("/progress", headers=headers).json()
    by_id = {t["territory_id"]: t for t in progress["territories"]}

    assert by_id["ingles_phrasal_intermediario"]["visible"] is False


def test_conquering_all_three_levels_reveals_everything_in_the_family(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    user_db_id = user.replace("-", "")

    _conquer_territory(user_db_id, "ingles_phrasal_basico")
    _conquer_territory(user_db_id, "ingles_phrasal_intermediario")

    progress = client.get("/progress", headers=headers).json()
    by_id = {t["territory_id"]: t for t in progress["territories"]}

    assert by_id["ingles_phrasal_avancado"]["visible"] is True
    assert by_id["ingles_phrasal_relampago_avancado"]["visible"] is True


def test_different_families_are_independent(client):
    """Conquistar Phrasal Verbs Básico não libera Expressões Idiomáticas
    Intermediário — famílias diferentes, sem trava cruzada."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    user_db_id = user.replace("-", "")

    _conquer_territory(user_db_id, "ingles_phrasal_basico")

    progress = client.get("/progress", headers=headers).json()
    by_id = {t["territory_id"]: t for t in progress["territories"]}

    assert by_id["ingles_expressoes_intermediario"]["visible"] is False


def test_territory_without_level_suffix_is_always_visible(client):
    """Território de Mundo sem família sequencial (ex.: 'numeros') nunca
    é afetado pelo gate — continua sempre visible=True."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    progress = client.get("/progress", headers=headers).json()
    by_id = {t["territory_id"]: t for t in progress["territories"]}

    assert by_id["numeros"]["visible"] is True


def test_grandfather_clause_existing_attempt_keeps_territory_visible(client):
    """Usuário que já tinha respondido um nível avançado ANTES desta
    regra existir não perde acesso retroativamente — qualquer tentativa
    já registrada conta como "alcançado", mesmo sem conquistar o nível
    anterior. Simulado inserindo o Attempt direto no banco (o próprio
    endpoint de busca já respeita o gate novo — não dá mais pra criar
    uma tentativa "antiga" de verdade por ele depois que o gate existe,
    então isso representa fielmente um Attempt de antes da migração)."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    user_db_id = user.replace("-", "")

    progress = client.get("/progress", headers=headers).json()
    by_id = {t["territory_id"]: t for t in progress["territories"]}
    assert by_id["ingles_phrasal_intermediario"]["visible"] is False

    from app.seed import CHALLENGES

    sample = next(c for c in CHALLENGES if c["territory_id"] == "ingles_phrasal_intermediario")
    with SessionLocal() as db:
        challenge = db.execute(
            select(models.Challenge).where(models.Challenge.prompt == sample["prompt"])
        ).scalars().first()
        db.add(
            models.Attempt(
                attempt_id=str(uuid.uuid4()),
                user_id=user_db_id,
                challenge_id=challenge.id,
                submitted_answer="qualquer",
                is_correct=True,
                served_at=utcnow(),
            )
        )
        db.commit()

    progress = client.get("/progress", headers=headers).json()
    by_id = {t["territory_id"]: t for t in progress["territories"]}
    assert by_id["ingles_phrasal_intermediario"]["visible"] is True


def test_unlocked_also_reflects_the_sequence_gate_for_real_enforcement(client, monkeypatch):
    """`unlocked` é a autoridade de ACESSO de verdade (por isso também
    incorpora o gate de sequência — defesa em profundidade, não só uma
    dica visual) — `visible` é o flag separado que o client usa pra
    decidir se MOSTRA o card ou não. Os dois ficam False juntos aqui
    porque o acesso está genuinamente bloqueado; a diferença entre os
    dois fica clara no território bloqueado só por assinatura (esse
    continua visible=True, unlocked=False — ver test_monetization_flag.py
    e test_core_loop.py, não duplicado aqui)."""
    import app.services as services_module

    monkeypatch.setattr(services_module.config, "MONETIZATION_ENABLED", False)
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    progress = client.get("/progress", headers=headers).json()
    by_id = {t["territory_id"]: t for t in progress["territories"]}

    assert by_id["ingles_phrasal_intermediario"]["unlocked"] is False
    assert by_id["ingles_phrasal_intermediario"]["visible"] is False


def test_sequential_gate_blocks_real_access_even_with_monetization_off(client, monkeypatch):
    """Defesa em profundidade: o gate de sequência vale mesmo com
    MONETIZATION_ENABLED=false (lançamento gratuito atual) — é uma trava
    de ritmo pedagógico, não de assinatura, então não pode depender da
    flag de monetização pra funcionar de verdade."""
    import app.services as services_module

    monkeypatch.setattr(services_module.config, "MONETIZATION_ENABLED", False)
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    resp = client.get(
        "/challenges/next",
        params={"territory_id": "ingles_phrasal_intermediario"},
        headers=headers,
    )
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "TERRITORY_LOCKED"
