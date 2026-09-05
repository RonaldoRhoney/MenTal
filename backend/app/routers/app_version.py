"""
SCREENSHOTS_LOJA_E_AVISO_ATUALIZACAO_V1.md §2 (05/09/2026) — aviso
gentil de nova versão disponível. Endpoint público (sem autenticação):
a checagem de versão precisa funcionar mesmo antes do login, e não
carrega nenhum dado sensível — só dois números de versão que já são
públicos na ficha da Google Play.
"""

from fastapi import APIRouter

from .. import config, schemas

router = APIRouter()


@router.get("/app/version", response_model=schemas.AppVersionOut)
def get_app_version():
    return schemas.AppVersionOut(
        latest_version=config.APP_LATEST_VERSION,
        min_required_version=config.APP_MIN_REQUIRED_VERSION,
    )
