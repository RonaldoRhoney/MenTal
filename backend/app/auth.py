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
"""

import uuid

import jwt
from fastapi import Header, HTTPException

from . import config

_jwks_client: jwt.PyJWKClient | None = None


def _get_jwks_client() -> jwt.PyJWKClient:
    global _jwks_client
    if _jwks_client is None:
        jwks_url = f"{config.SUPABASE_URL}/auth/v1/.well-known/jwks.json"
        _jwks_client = jwt.PyJWKClient(jwks_url, cache_keys=True)
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
