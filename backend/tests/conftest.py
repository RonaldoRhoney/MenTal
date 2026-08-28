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

from app.main import app  # noqa: E402


@pytest.fixture(scope="session")
def client():
    return TestClient(app)


def auth_header(user_id: str) -> dict:
    return {"Authorization": f"Bearer {user_id}"}
