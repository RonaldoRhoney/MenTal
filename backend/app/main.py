from fastapi import FastAPI, Request
from fastapi.exceptions import HTTPException
from fastapi.responses import JSONResponse

from . import config, models
from .db import Base, engine, SessionLocal
from .seed import seed_if_empty
from .routers import age_gate, badges, challenges, progress, subscription, ranking, social

# create_all() e o seed de desenvolvimento só rodam contra o SQLite local.
# Correção feita testando contra o Postgres real do MENTAL (2026-08-19,
# ver docs/02_IMPLEMENTATION/SUPABASE_SETUP.md §4): contra um banco real, o
# schema é controlado pela migration versionada
# (backend/migrations/001_initial_schema.sql), nunca pelo create_all do
# SQLAlchemy — e o seed de desafios de exemplo nunca deve rodar em
# produção (RISKS_AND_OPEN_DECISIONS.md §2: conteúdo curado manualmente).
if config.DATABASE_URL.startswith("sqlite"):
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        seed_if_empty(db)

app = FastAPI(title="MENTAL API", version="0.1.0")


@app.exception_handler(HTTPException)
async def api_contract_error_handler(request: Request, exc: HTTPException):
    # API_CONTRACT.md §1: toda resposta de erro segue {"error": {"code":
    # ..., "message": ...}} — sem o envelope {"detail": ...} padrão do
    # FastAPI. Endpoints levantam HTTPException(detail={"error": {...}}).
    body = exc.detail if isinstance(exc.detail, dict) and "error" in exc.detail else {"error": {"code": "ERROR", "message": str(exc.detail)}}
    return JSONResponse(status_code=exc.status_code, content=body, headers=exc.headers)


app.include_router(age_gate.router, tags=["age-gate"])
app.include_router(challenges.router, tags=["challenges"])
app.include_router(progress.router, tags=["progress"])
app.include_router(subscription.router, tags=["subscription"])
app.include_router(ranking.router, tags=["ranking"])
app.include_router(social.router, tags=["social"])
app.include_router(badges.router, tags=["badges"])


@app.get("/health")
def health():
    return {"status": "ok"}
