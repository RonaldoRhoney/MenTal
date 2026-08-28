"""
Resolução de user_id a partir do token de autenticação.

Três modos, em ordem de prioridade:

1. SUPABASE_URL configurado → valida o JWT via JWKS (chave pública do
   projeto, buscada em {SUPABASE_URL}/auth/v1/.well-known/jwks.json).
   Modo real, usado pelo projeto MENTAL (assinatura ES256/ECC P-256,
   confirmado no painel em 2026-08-19 — não é o modelo legado HS256).
2. SUPABASE_JWT_SECRET configurado (sem SUPABASE_URL) → valida via HS256
   com segredo compartilhado. Fallback só para projeto Supabase ainda no
   modelo legado de assinatura.
3. Nenhum dos dois → modo DEV_INSECURE: o token é tratado como o próprio
   user_id em texto puro. Nunca deve rodar assim em produção — existe só
   para desenvolvimento local/testes sem depender de um projeto Supabase.
   Achado de auditoria (28/08/2026): sem uma trava explícita, uma
   SUPABASE_URL/SUPABASE_JWT_SECRET ausente por engano em produção (env
   var apagada, typo, restore de config no Render) fazia o backend cair
   nesse modo 3 silenciosamente, aceitando qualquer UUID como identidade
   de qualquer usuário. Agora exige config.ALLOW_DEV_INSECURE_AUTH
   (env var MENTAL_ALLOW_DEV_INSECURE_AUTH=true) explicitamente setada —
   sem ela, get_current_user_id recusa a requisição com 500 em vez de
   aceitar silenciosamente (fail loud, nunca fail-open).
"""

import uuid

import jwt
from fastapi import Depends, Header, HTTPException
from sqlalchemy.orm import Session

from . import config, models
from .db import get_db

_jwks_client: jwt.PyJWKClient | None = None


def _get_jwks_client() -> jwt.PyJWKClient:
    global _jwks_client
    if _jwks_client is None:
        jwks_url = f"{config.SUPABASE_URL}/auth/v1/.well-known/jwks.json"
        # timeout explícito — Achado real (2026-08-22, teste informal): o
        # padrão da lib é 30s, e get_signing_key() tenta de novo (outro
        # fetch) se o kid não bater na primeira vez, dobrando o pior caso
        # pra ~60s numa falha de rede de saída do provedor. O endpoint em
        # si responde em <1s quando alcançável (testado direto), então
        # 8s já é folga generosa — trava a requisição bem menos tempo
        # numa falha real, sem risco de cortar uma resposta legítima.
        _jwks_client = jwt.PyJWKClient(jwks_url, cache_keys=True, timeout=8)
    return _jwks_client


def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail={"error": {"code": "UNAUTHENTICATED", "message": "Missing bearer token"}})

    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        raise HTTPException(status_code=401, detail={"error": {"code": "UNAUTHENTICATED", "message": "Empty token"}})

    if config.SUPABASE_URL:
        try:
            signing_key = _get_jwks_client().get_signing_key_from_jwt(token)
            payload = jwt.decode(token, signing_key.key, algorithms=["ES256"], audience="authenticated")
        except jwt.PyJWTError as exc:
            raise HTTPException(status_code=401, detail={"error": {"code": "INVALID_TOKEN", "message": str(exc)}}) from exc
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail={"error": {"code": "INVALID_TOKEN", "message": "Token missing sub"}})
        return user_id

    if config.SUPABASE_JWT_SECRET:
        try:
            payload = jwt.decode(token, config.SUPABASE_JWT_SECRET, algorithms=["HS256"], audience="authenticated")
        except jwt.PyJWTError as exc:
            raise HTTPException(status_code=401, detail={"error": {"code": "INVALID_TOKEN", "message": str(exc)}}) from exc
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail={"error": {"code": "INVALID_TOKEN", "message": "Token missing sub"}})
        return user_id

    if not config.ALLOW_DEV_INSECURE_AUTH:
        raise HTTPException(
            status_code=500,
            detail={
                "error": {
                    "code": "AUTH_MISCONFIGURED",
                    "message": "SUPABASE_URL/SUPABASE_JWT_SECRET ausentes e MENTAL_ALLOW_DEV_INSECURE_AUTH não setado — recusando autenticar em vez de aceitar qualquer token.",
                }
            },
        )

    # DEV_INSECURE: token é o próprio user_id. Precisa ser um UUID válido
    # — desde que user_id virou coluna Uuid real (models.py, corrigido
    # testando contra Postgres), um token não-UUID quebrava com 500 lá na
    # frente (no INSERT/refresh do SQLAlchemy) em vez de um 401 limpo.
    # Achado testando manualmente com um Bearer token de teste malformado
    # — o app real sempre manda um UUID de verdade (session_store.dart),
    # isso nunca acontece em uso normal, mas a API não devia responder
    # com stack trace pra token malformado de qualquer jeito.
    try:
        uuid.UUID(token)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail={"error": {"code": "INVALID_TOKEN", "message": "Token must be a valid UUID in DEV_INSECURE mode"}}) from exc
    return token


def require_age_confirmed_user_id(
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
) -> str:
    """
    Achado de auditoria de segurança (28/08/2026): a confirmação de
    maioridade (POL-002/POL-003, base legal do consentimento coletado no
    onboarding) era um gate 100% de client — nenhum endpoint do backend
    conferia age_confirmed_at. Um token válido que nunca chamou POST
    /age-gate conseguia jogar, ver ranking, adicionar amigos, editar
    perfil e subir foto normalmente. Usar esta dependência (em vez de
    get_current_user_id puro) em qualquer endpoint que não seja
    POST /age-gate ou GET /profile (que PRECISA continuar acessível
    antes da confirmação — é a própria chamada que o client usa pra
    decidir se mostra a tela de confirmação, main.dart::
    _checkProfileStatus).
    """
    profile = db.get(models.Profile, user_id)
    if profile is None or profile.age_confirmed_at is None:
        raise HTTPException(
            status_code=403,
            detail={"error": {"code": "AGE_NOT_CONFIRMED", "message": "Confirm age via POST /age-gate first"}},
        )
    return user_id
