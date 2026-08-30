from fastapi import FastAPI, Request
from fastapi.exceptions import HTTPException
from fastapi.responses import JSONResponse

from . import config, models
from .db import Base, engine, SessionLocal
from .scheduler import start_scheduler
from .seed import seed_if_empty
from .routers import admin_metrics, age_gate, app_feedback, badges, battles, challenges, learning_pauses, level_feedback, mentalcoins, movement, notifications, profile, progress, stats, subscription, ranking, social

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
app.include_router(stats.router, tags=["stats"])
app.include_router(notifications.router, tags=["notifications"])
app.include_router(movement.router, tags=["movement"])
app.include_router(battles.router, tags=["battles"])
app.include_router(profile.router, tags=["profile"])
app.include_router(level_feedback.router, tags=["level-feedback"])
app.include_router(app_feedback.router, tags=["app-feedback"])
app.include_router(mentalcoins.router, tags=["mentalcoins"])
app.include_router(learning_pauses.router, tags=["learning-pauses"])
app.include_router(admin_metrics.router, tags=["admin-metrics"])

# V2 item 8 — só liga de verdade com NOTIFICATION_SCHEDULER_ENABLED=true
# (default false, nunca roda em teste/dev casual — ver app/scheduler.py).
start_scheduler()


@app.get("/health")
def health():
    return {"status": "ok"}
