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

    # V2 item 8 — Notificações (NOTIFICATIONS.md). Preferência é por
    # categoria (§4: "toggle para desativar cada categoria separadamente")
    # e vive no backend, não só localmente no aparelho como o toggle de
    # som (MICROINTERACTIONS.md) — quem decide SE notifica é o job
    # agendado no backend (services.run_notification_checks), então ele
    # precisa conhecer a preferência, não só o client.
    push_token: Mapped[str | None] = mapped_column(String, nullable=True)
    notif_reengagement_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    notif_social_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    # Atualizado a cada GET /progress (Home carrega isso sempre que abre)
    # — é o sinal de "o jogador de fato usou o app", não só "fez uma
    # requisição qualquer".
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    # Evita notificar de novo dentro da MESMA janela de inatividade
    # (NOTIFICATIONS.md §2: "no máximo uma notificação de reengajamento
    # por janela de inatividade") — guarda em qual das duas janelas (24h
    # ou 48h) a última notificação de reengajamento já foi enviada.
    last_reengagement_notified_window: Mapped[str | None] = mapped_column(String, nullable=True)  # "24h" | "48h"
    # Última posição conhecida no ranking semanal — permite detectar a
    # TRANSIÇÃO exata de "ultrapassado agora" (mesmo princípio já usado
    # em level_up/territory_just_conquered: nunca notificar de novo pela
    # mesma posição já notificada).
    last_known_weekly_rank: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # V2 item 9 — Contador de passos (STEP_COUNTER_MOVIMENTO.md §2). O
    # ciclo de 24h é âncorado no momento da PRIMEIRA ativação, não num
    # horário fixo do sistema — este campo nunca muda depois de setado
    # (desativar/reativar preserva o horário original, mesmo raciocínio
    # de não recomeçar streak à toa).
    movement_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    movement_cycle_anchor_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    # Meta diária OPCIONAL definida pelo próprio usuário (pedido de
    # Rhoney, 2026-08-21) — nunca imposta pelo sistema. Null = sem meta
    # (comportamento padrão, só o bônus escalonado por faixa se aplica).
    # Ultrapassar a própria meta paga um bônus extra (config.
    # MOVEMENT_GOAL_BONUS_XP), separado do bônus de faixa — recompensa
    # especificamente superar o que a PESSOA se propôs, não o volume
    # absoluto de passos (que já é recompensado pela faixa).
    movement_daily_goal_steps: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Recompensa por compartilhar conquista (pedido de Rhoney, 2026-08-22:
    # "compartilhando seus desempenhos... o usuário ganha xp"). O app não
    # tem como confirmar que o compartilhamento via OS share sheet foi de
    # fato concluído (share_plus só confirma que o sheet foi aberto) —
    # por isso a defesa contra farm não é "verificar o compartilhamento",
    # é um teto de 1 recompensa por dia civil (UTC), igual ao resto do
    # backend que trata data como referência UTC única.
    last_share_reward_date: Mapped[date | None] = mapped_column(Date, nullable=True)


class MovementCycle(Base):
    """
    Um registro por janela de 24h do contador de passos de um usuário
    (STEP_COUNTER_MOVIMENTO.md §2/§4). `steps_collected` e `xp_awarded`
    acumulam a cada coleta parcial dentro da MESMA janela — nunca
    recalculados do zero, para permitir múltiplas coletas parciais sem
    perder o que já foi convertido. `report_sent` evita reenviar o
    relatório de fim de ciclo mais de uma vez (mesmo padrão de
    last_reengagement_notified_window em Profile). `goal_bonus_awarded`
    evita pagar o bônus de meta mais de uma vez por ciclo mesmo com
    várias coletas parciais depois de já ter cruzado a meta.
    """

    __tablename__ = "movement_cycles"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(UUIDType, index=True)
    cycle_start_at: Mapped[datetime] = mapped_column(DateTime)
    cycle_end_at: Mapped[datetime] = mapped_column(DateTime)
    steps_collected: Mapped[int] = mapped_column(Integer, default=0)
    xp_awarded: Mapped[int] = mapped_column(Integer, default=0)
    report_sent: Mapped[bool] = mapped_column(Boolean, default=False)
    goal_bonus_awarded: Mapped[bool] = mapped_column(Boolean, default=False)
    # Checkpoints intradiários (pedido de Rhoney, 2026-08-21): as 24h são
    # divididas em config.MOVEMENT_CHECKPOINT_PARTS partes iguais; os
    # primeiros PARTS-1 fechamentos (a última coincide com o fim do
    # próprio ciclo, já coberto por xp_awarded/goal_bonus_awarded) pagam
    # um bônus extra se o total acumulado até aquele ponto já bate a
    # faixa de MOVEMENT_STEP_TIERS proporcional ao tempo decorrido.
    # Bitmask (bit i = checkpoint i já pago) evita pagar de novo.
    checkpoint_bonus_mask: Mapped[int] = mapped_column(Integer, default=0)


class World(Base):
    """
    V2 item 10 — Mundos completos (V2_KICKOFF.md §2/§6A). Agrupa
    territórios tematicamente relacionados (aprovado por Rhoney,
    2026-08-22): Mundo da Linguagem (palavras/textos/enigmas) e Mundo da
    Mente Lógica (números/lógica/visual/conhecimento). "Mundo completo"
    nunca é armazenado — é sempre derivado em tempo real a partir de
    UserTerritoryProgress.conquered_at (mesma disciplina de nunca ter
    duas fontes de verdade pro mesmo fato, já usada em badges).
    """

    __tablename__ = "worlds"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, default=0)


class Territory(Base):
    __tablename__ = "territories"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    challenge_type: Mapped[str] = mapped_column(String, nullable=False)
    requires_subscription: Mapped[bool] = mapped_column(Boolean, default=False)
    free_sample_count: Mapped[int] = mapped_column(Integer, default=0)
    display_order: Mapped[int] = mapped_column(Integer, default=0)
    world_id: Mapped[str | None] = mapped_column(String, ForeignKey("worlds.id"), nullable=True)


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
    # ARCHITECTURE_UPDATE_I18N_READY.md §3: nasce desde já, mesmo com 100%
    # dos registros em 'pt-BR' hoje — evita migração de schema dolorosa
    # quando o 2º idioma for adicionado (só inserir novos registros com
    # language_code diferente, sem alteração estrutural).
    language_code: Mapped[str] = mapped_column(String, default="pt-BR")


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
    # V2 item 15 — Palavras Relâmpago (PALAVRAS_RELAMPAGO.md, aprovado
    # 2026-08-22). Só preenchido em tentativas do modo relâmpago; null em
    # todo o resto do app. speed_bonus_xp guardado à parte (não só somado
    # em xp_awarded) pra reenvio idempotente do mesmo attempt_id devolver
    # o mesmo detalhamento, sem precisar recalcular.
    response_time_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    timed_out: Mapped[bool] = mapped_column(Boolean, default=False)
    speed_bonus_xp: Mapped[int] = mapped_column(Integer, default=0)


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


class Friendship(Base):
    """
    V2 item 12 — Amigos (V2_KICKOFF.md §6A, aprovado 2026-08-22). N:N de
    verdade — deliberadamente NÃO reaproveita InviteConversion, que tem
    UniqueConstraint("invited_user_id") pensado pra atribuição de
    crescimento (1 resposta só pra "quem trouxe esse usuário"), o que
    limitaria cada jogador a um único amigo pra sempre. Usa o MESMO
    invite_code/deep link já existente como ponto de entrada (nenhuma
    tela nova de convite), só grava o resultado numa tabela separada.
    Par sempre canônico (user_id_a < user_id_b como string) — evita
    duas linhas pra mesma amizade dependendo de quem adicionou quem.
    """

    __tablename__ = "friendships"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    user_id_a: Mapped[str] = mapped_column(UUIDType, index=True)
    user_id_b: Mapped[str] = mapped_column(UUIDType, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    __table_args__ = (UniqueConstraint("user_id_a", "user_id_b", name="uq_friendship_pair"),)


class Badge(Base):
    """
    Catálogo de badges/conquistas — V2 item 1 (V2_KICKOFF.md §6A).
    `criteria_type` é avaliado por services.check_and_award_badges contra
    dado que já existe (Attempt, UserTerritoryProgress, Streak) — nenhuma
    contagem nova precisa ser mantida só para badges. `criteria_value` é
    o limiar numérico; para critérios sem limiar (ex.: "conquistar todos
    os territórios", que deve reagir a quantos territórios existirem no
    momento, não a um número fixo hoje) o valor fica 0 e é ignorado.
    """

    __tablename__ = "badges"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    code: Mapped[str] = mapped_column(String, unique=True)
    name: Mapped[str] = mapped_column(String)
    description: Mapped[str] = mapped_column(Text)
    criteria_type: Mapped[str] = mapped_column(String)
    criteria_value: Mapped[int] = mapped_column(Integer, default=0)
    display_order: Mapped[int] = mapped_column(Integer, default=0)


class UserBadge(Base):
    __tablename__ = "user_badges"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    badge_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("badges.id"), primary_key=True)
    earned_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
