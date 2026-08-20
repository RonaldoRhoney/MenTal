"""
Resolução de user_id a partir do token de autenticação.

Decisão registrada no Vertical Slice 01 (não estava no API_CONTRACT.md):
não existe ainda projeto Supabase real configurado para o MENTAL, então a
validação de token real (Supabase JWT, HS256 com SUPABASE_JWT_SECRET) só
roda quando a variável de ambiente SUPABASE_JWT_SECRET está definida.

Sem essa variável (ambiente de desenvolvimento local e testes automatizados
deste Vertical Slice), o token é tratado como o próprio user_id em texto
puro — modo DEV_INSECURE, nunca deve rodar assim em produção. Isso é um gap
de infraestrutura (falta de projeto Supabase provisionado), não uma
decisão de arquitetura: ARCHITECTURE.md já definiu Supabase Auth como
fonte de identidade; este stub só existe para o Vertical Slice 01 poder
ser demonstrado e testado sem depender de um projeto Supabase já criado.
"""

import jwt
from fastapi import Header, HTTPException

from . import config


def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail={"error": {"code": "UNAUTHENTICATED", "message": "Missing bearer token"}})

    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        raise HTTPException(status_code=401, detail={"error": {"code": "UNAUTHENTICATED", "message": "Empty token"}})

    if config.SUPABASE_JWT_SECRET:
        try:
            payload = jwt.decode(token, config.SUPABASE_JWT_SECRET, algorithms=["HS256"], audience="authenticated")
        except jwt.PyJWTError as exc:
            raise HTTPException(status_code=401, detail={"error": {"code": "INVALID_TOKEN", "message": str(exc)}}) from exc
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail={"error": {"code": "INVALID_TOKEN", "message": "Token missing sub"}})
        return user_id

    # DEV_INSECURE: token é o próprio user_id.
    return token
