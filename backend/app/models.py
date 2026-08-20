import uuid
from datetime import datetime, date

from sqlalchemy import (
    String,
    Boolean,
    Integer,
    Text,
    JSON,
    DateTime,
    Date,
    ForeignKey,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


def new_uuid() -> str:
    return str(uuid.uuid4())


# Gap identificado testando contra o Postgres real do projeto MENTAL
# (2026-08-19, ver docs/02_IMPLEMENTATION/SUPABASE_SETUP.md §3): colunas
# de UUID declaradas como String genérico geram erro real no Postgres
# ("operator does not exist: uuid = character varying") porque a migration
# (backend/migrations/001_initial_schema.sql) usa o tipo uuid nativo.
# sqlalchemy.Uuid é agnóstico de banco — native uuid no Postgres,
# CHAR(32) no SQLite — e mantém o valor Python como str (as_uuid=False),
# sem exigir mudança em nenhum outro ponto do código que já trata esses
# campos como string.
UUIDType = Uuid(as_uuid=False)


class Profile(Base):
    __tablename__ = "profiles"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    nickname: Mapped[str] = mapped_column(String, nullable=False)
    nickname_is_system_generated: Mapped[bool] = mapped_column(Boolean, default=True)
    age_mode: Mapped[str] = mapped_column(String, default="unknown")  # unknown|child|adult
    # Padrão RhoneyInc (skill admin-padrao, aplicado 2026-08-20):
    # rhoneyinc@gmail.com é sempre admin, promovido automaticamente por
    # trigger no Postgres (migrations/002_admin_role.sql), não por passo
    # manual. Nenhum endpoint usa este campo ainda no V1 — não existe
    # painel admin no Vertical Slice 01 — mas a coluna/trigger nasce agora
    # para não virar retrabalho estrutural depois (mesmo raciocínio já
    # aplicado a child_safe_mode em FAMILY_SAFETY.md).
    role: Mapped[str] = mapped_column(String, default="user")  # user|admin
    child_safe_mode: Mapped[bool] = mapped_column(Boolean, default=True)
    xp_total: Mapped[int] = mapped_column(Integer, default=0)
    level: Mapped[int] = mapped_column(Integer, default=1)
    # Campo adicionado no Vertical Slice 01 (não estava no DATA_MODEL.md
    # original): API_CONTRACT.md §6 previa "backend registra
    # parental_gate_passed_at na sessão", mas o V1 não tem mecanismo de
    # sessão de servidor (auth é stateless via token) — registrar no
    # profile é a forma mais simples de persistir esse estado sem
    # introduzir um sistema de sessão só para isso. Ver relatório do VS01.
    parental_gate_passed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Territory(Base):
    __tablename__ = "territories"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    challenge_type: Mapped[str] = mapped_column(String, nullable=False)
    requires_subscription: Mapped[bool] = mapped_column(Boolean, default=False)
    free_sample_count: Mapped[int] = mapped_column(Integer, default=0)
    display_order: Mapped[int] = mapped_column(Integer, default=0)


class UserTerritoryProgress(Base):
    __tablename__ = "user_territory_progress"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    territory_id: Mapped[str] = mapped_column(String, primary_key=True)
    xp_in_territory: Mapped[int] = mapped_column(Integer, default=0)
    conquered_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class Challenge(Base):
    __tablename__ = "challenges"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    territory_id: Mapped[str] = mapped_column(String, ForeignKey("territories.id"))
    difficulty_level: Mapped[int] = mapped_column(Integer, default=1)
    prompt: Mapped[str] = mapped_column(Text)
    options: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    correct_answer: Mapped[str] = mapped_column(Text)
    explanation: Mapped[str] = mapped_column(Text)
    age_reviewed: Mapped[bool] = mapped_column(Boolean, default=False)


class ChallengeHint(Base):
    __tablename__ = "challenge_hints"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    challenge_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("challenges.id"))
    hint_level: Mapped[int] = mapped_column(Integer)
    content: Mapped[str] = mapped_column(Text)


class Attempt(Base):
    __tablename__ = "attempts"

    attempt_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    user_id: Mapped[str] = mapped_column(UUIDType)
    challenge_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("challenges.id"))
    submitted_answer: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_correct: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    hints_used: Mapped[int] = mapped_column(Integer, default=0)
    xp_base: Mapped[int | None] = mapped_column(Integer, nullable=True)
    xp_awarded: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Streak(Base):
    __tablename__ = "streaks"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    current_streak: Mapped[int] = mapped_column(Integer, default=0)
    last_played_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    freeze_available: Mapped[bool] = mapped_column(Boolean, default=True)
    freeze_used_this_week: Mapped[bool] = mapped_column(Boolean, default=False)
    week_anchor: Mapped[date | None] = mapped_column(Date, nullable=True)


class Subscription(Base):
    __tablename__ = "subscriptions"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    status: Mapped[str] = mapped_column(String, default="none")  # none|active|expired|cancelled
    google_play_purchase_token: Mapped[str | None] = mapped_column(String, nullable=True)
    validated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class DailyChallengeUsage(Base):
    __tablename__ = "daily_challenge_usage"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    usage_date: Mapped[date] = mapped_column(Date, primary_key=True)
    challenges_consumed: Mapped[int] = mapped_column(Integer, default=0)


class Invite(Base):
    __tablename__ = "invites"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    inviter_user_id: Mapped[str] = mapped_column(UUIDType)
    invite_code: Mapped[str] = mapped_column(String, unique=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class InviteConversion(Base):
    __tablename__ = "invite_conversions"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    invite_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("invites.id"))
    invited_user_id: Mapped[str] = mapped_column(UUIDType)
    converted_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    __table_args__ = (UniqueConstraint("invited_user_id", name="uq_invite_conversion_user"),)
