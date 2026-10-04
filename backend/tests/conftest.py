import os
import tempfile

import pytest

_tmp_db = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
os.environ["MENTAL_DATABASE_URL"] = f"sqlite:///{_tmp_db.name}"
# Suite roda sem projeto Supabase real (SQLite local) — precisa habilitar
# DEV_INSECURE explicitamente desde a auditoria de 28/08/2026, que passou
# a exigir essa opt-in pra evitar fail-open silencioso em produção.
os.environ["MENTAL_ALLOW_DEV_INSECURE_AUTH"] = "true"

from fastapi.testclient import TestClient  # noqa: E402

from app import models  # noqa: E402
from app.db import SessionLocal  # noqa: E402
from app.main import app  # noqa: E402
from app.timeutil import utcnow  # noqa: E402


@pytest.fixture(scope="session")
def client():
    return TestClient(app)


def auth_header(user_id: str) -> dict:
    return {"Authorization": f"Bearer {user_id}"}


def conquer_territory(user_id: str, territory_id: str) -> None:
    """Marca o território como conquistado direto no banco — usado pelos
    testes de conteúdo que precisam driblar a trava de progressão
    sequencial (MENTAL_ESPECIFICACAO_FLUXO_PROGRESSAO_MAPA_RANKING_
    FEEDBACK_V1.1.md §4, generalizada pra todo Mundo em 04/10/2026) pra
    testar um território que não é mais o primeiro da sua sequência,
    sem precisar simular o fluxo de resposta completo do(s)
    território(s) anterior(es) — o foco desses testes é o conteúdo/
    mecânica do território em si, não o gate de sequência (coberto em
    test_sequential_progression.py)."""
    with SessionLocal() as db:
        progress = db.get(models.UserTerritoryProgress, (user_id, territory_id))
        if progress is None:
            progress = models.UserTerritoryProgress(user_id=user_id, territory_id=territory_id)
            db.add(progress)
        progress.conquered_at = utcnow()
        db.commit()
