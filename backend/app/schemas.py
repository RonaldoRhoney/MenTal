from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, Field

from . import config


class AgeGateRequest(BaseModel):
    """MENTAL-DIR-001/POL-002 (24/08/2026): MENTAL é exclusivo pra
    maiores de 18 anos — confirmação única, sem mais bifurcação
    child/adult. age_confirmed precisa ser True pra avançar; False não
    cria nem atualiza perfil (routers/age_gate.py rejeita antes)."""

    age_confirmed: bool


class AgeGateResponse(BaseModel):
    nickname: str
    age_confirmed_at: datetime
    terms_version_accepted: str


class LevelFeedbackRequest(BaseModel):
    """FEEDBACK_POS_NIVEL.md — coleta pura, nunca afeta hint_penalty_factor
    nem qualquer mecânica adaptativa. challenge_id identifica o "nível"
    (território + difficulty_level do desafio recém-respondido)."""

    challenge_id: str
    action: Literal["repeat", "continue"]
    difficulty_rating: Literal["facil", "medio", "dificil", "muito_dificil"]
    comment: str | None = Field(default=None, max_length=1000)


class LevelFeedbackResponse(BaseModel):
    ok: bool = True


class AdminLevelFeedbackItem(BaseModel):
    id: str
    user_id: str
    territory_id: str
    challenge_id: str
    action: str
    difficulty_rating: str
    comment: str | None
    created_at: datetime


class AppFeedbackRequest(BaseModel):
    """Menu de feedback geral (26/08/2026) — comentário livre sobre o
    app, sem estar amarrado a um nível/desafio específico."""

    comment: str = Field(min_length=1, max_length=2000)


class AppFeedbackResponse(BaseModel):
    ok: bool = True


class ReplyAppFeedbackRequest(BaseModel):
    reply: str = Field(min_length=1, max_length=2000)


class ReactToAppFeedbackRequest(BaseModel):
    reaction_type: Literal["like", "love"]


class PublicAppFeedbackItem(BaseModel):
    """Mural público de feedback (29/08/2026, decisão de Rhoney) —
    visível a TODOS os usuários, não só ao autor + admin. my_reactions
    lista os tipos ('like'/'love') que o USUÁRIO ATUAL já deu neste
    feedback, pra o client saber qual botão destacar como já ativado."""

    id: str
    user_id: str
    user_nickname: str
    comment: str
    created_at: datetime
    admin_reply: str | None = None
    admin_reply_at: datetime | None = None
    like_count: int = 0
    love_count: int = 0
    my_reactions: list[str] = []


class PublicAppFeedbackListResponse(BaseModel):
    items: list[PublicAppFeedbackItem]


class MyAppFeedbackListResponse(BaseModel):
    items: list[MyAppFeedbackItem]


class ChallengeOut(BaseModel):
    challenge_id: str
    # Achado de auditoria de segurança (28/08/2026): attempt_id agora
    # nasce no servidor (junto do served_at usado pro bônus de
    # velocidade), não mais gerado livremente pelo client — ver
    # routers/challenges.py::next_challenge. None só no fluxo de
    # batalha, que continua usando GET /battles/{id}/my-challenge (o
    # client ainda gera o próprio attempt_id nesse caso específico).
    attempt_id: str | None = None
    territory_id: str
    difficulty_level: int
    prompt: str
    options: list[str] | None
    hints_available: int
    # V2 item 15 — Palavras Relâmpago. Só preenchido quando mode=
    # "relampago" foi pedido em GET /challenges/next; None em todo o
    # resto do app (inclusive o formato digitado normal de Palavras).
    time_limit_seconds: int | None = None
    # CONHECIMENTO_CONTEUDO_GERAL_E_IMAGEM.md §3 — enriquecimento visual
    # opcional (emoji), nunca obrigatório. None na grande maioria dos
    # desafios, sempre foi assim e continua assim.
    prompt_image: str | None = None


class HintRequest(BaseModel):
    attempt_id: str


class HintResponse(BaseModel):
    hint_level: int
    content: str


class AnswerRequest(BaseModel):
    attempt_id: str
    submitted_answer: str
    # V2 item 15 — Palavras Relâmpago. response_time_ms só é enviado no
    # modo relâmpago; ausente em toda resposta digitada normal.
    # timed_out=True força is_correct=False independente de
    # submitted_answer — o backend nunca confia em "acertei mesmo sem
    # escolher a tempo" vindo do cliente.
    response_time_ms: int | None = None
    timed_out: bool = False


class StreakOut(BaseModel):
    current_streak: int
    freeze_available: bool


class TerritoryProgressOut(BaseModel):
    xp_in_territory: int
    conquered: bool


class BadgeOut(BaseModel):
    code: str
    name: str
    description: str
    earned: bool
    earned_at: str | None


class BadgesResponse(BaseModel):
    badges: list[BadgeOut]


class AnswerResponse(BaseModel):
    is_correct: bool
    correct_answer: str
    explanation: str
    xp_base: int
    hints_used: int
    xp_awarded: int
    streak: StreakOut
    territory_progress: TerritoryProgressOut
    # MICROINTERACTIONS.md — sinais de evento raro/significativo para o
    # client decidir celebração (som+animação), calculados aqui porque o
    # backend é a única autoridade sobre "isso realmente aconteceu agora"
    # (mesma regra de XP/score/desbloqueio). Nunca True numa resposta
    # idempotente reenviada — só na primeira vez que a resposta é computada.
    level_up: bool = False
    new_level: int | None = None
    territory_just_conquered: bool = False
    streak_just_extended: bool = False
    newly_awarded_badges: list[BadgeOut] = []
    # V2 item 10 — Mundos completos (V2_KICKOFF.md §2/§6A). Mesma regra dos
    # sinais acima: True só na resposta exata que fecha o último território
    # do mundo, nunca de novo depois.
    world_just_completed: bool = False
    completed_world_name: str | None = None
    world_completion_bonus_xp: int = 0
    # V2 item 15 — Palavras Relâmpago. timed_out=True sinaliza pro
    # client mostrar a copy suave ("Quase lá! Tenta de novo"), nunca o
    # feedback padrão de erro (PALAVRAS_RELAMPAGO.md §3, Princípio de
    # Não-Humilhação). speed_bonus_xp já vem somado em xp_awarded — este
    # campo é só o detalhamento pra exibição ("+X XP de bônus de
    # velocidade!").
    timed_out: bool = False
    speed_bonus_xp: int = 0
    # V2 item 13 — Disputa territorial (TERRITORY_DISPUTE.md, aprovado
    # 2026-08-22). True só na resposta exata em que você assume a
    # liderança de XP no território entre seus amigos (mesma regra de
    # transição dos sinais acima, nunca True de novo enquanto continuar
    # líder). dethroned_nickname vem preenchido só quando havia um
    # detentor anterior real (nunca na primeira vez que alguém pontua
    # nesse território sem rival ainda).
    territory_detentor_gained: bool = False
    dethroned_nickname: str | None = None


class ProgressTerritoryOut(BaseModel):
    territory_id: str
    xp_in_territory: int
    unlocked: bool
    conquered: bool
    conquest_threshold: int
    # V2 item 13 — Disputa territorial. Sempre relativo a você + seus
    # amigos confirmados (nunca global) — null quando ninguém no grupo
    # tem XP nesse território ainda.
    detentor_nickname: str | None = None
    is_detentor: bool = False


class WorldProgressOut(BaseModel):
    world_id: str
    name: str
    territory_ids: list[str]
    completed: bool


class BlockOut(BaseModel):
    """Bloco (BLOCOS_MENUS.md) — puramente organização de menu, sem
    estado de progressão (diferente de WorldProgressOut, que tem
    `completed`). Só existe pra agrupar territórios visualmente."""

    block_id: str
    name: str
    territory_ids: list[str]


class ProgressResponse(BaseModel):
    xp_total: int
    level: int
    xp_per_level: int
    territories: list[ProgressTerritoryOut]
    worlds: list[WorldProgressOut]
    blocks: list[BlockOut]
    streak: StreakOut


class SubscriptionStatusResponse(BaseModel):
    status: str
    expires_at: str | None


class ValidateReceiptRequest(BaseModel):
    purchase_token: str


class RankingEntry(BaseModel):
    rank: int
    nickname: str
    avatar_id: str | None = None
    # Revisão 26/08/2026: nome real e foto de perfil (só se aprovada na
    # moderação) passam a ser públicos, reversão da regra anterior.
    real_name: str | None = None
    photo_url: str | None = None
    xp: int


class RankingResponse(BaseModel):
    window: str
    entries: list[RankingEntry]
    me: RankingEntry | None


class TerritoryStatsOut(BaseModel):
    territory_id: str
    total_attempts: int
    total_correct: int
    accuracy: float
    current_difficulty_level: int
    xp_in_territory: int
    conquered: bool


class StatsResponse(BaseModel):
    xp_total: int
    level: int
    total_attempts: int
    total_correct: int
    accuracy: float
    total_hints_used: int
    hint_free_correct: int
    current_streak: int
    longest_streak: int
    badges_earned: int
    badges_total: int
    by_territory: list[TerritoryStatsOut]


class PushTokenRequest(BaseModel):
    push_token: str


class NotificationPreferencesRequest(BaseModel):
    reengagement_enabled: bool
    social_enabled: bool


class NotificationPreferencesResponse(BaseModel):
    reengagement_enabled: bool
    social_enabled: bool


class MovementSnapshotOut(BaseModel):
    recorded_at: datetime
    steps_total: int


class MovementCycleOut(BaseModel):
    id: str
    cycle_start_at: datetime
    cycle_end_at: datetime
    steps_collected: int
    xp_awarded: int
    # Histórico intradiário real (um ponto por coleta feita nesse ciclo)
    # — gráfico de linha da tela Movimento. Vazio pra ciclos que nunca
    # tiveram nenhuma coleta ainda.
    snapshots: list[MovementSnapshotOut] = []


class MovementStatusResponse(BaseModel):
    movement_enabled: bool
    daily_goal_steps: int | None
    current_cycle: MovementCycleOut | None
    pending_report_cycle: MovementCycleOut | None
    # Últimos ciclos (mais recente primeiro, inclui o atual se existir) —
    # gráfico semanal de barras. Cada item é um dia/ciclo de 24h.
    recent_cycles: list[MovementCycleOut] = []


class MovementCollectRequest(BaseModel):
    steps: int = Field(ge=0)
    cycle_id: str | None = None


class MovementCollectResponse(BaseModel):
    cycle: MovementCycleOut
    xp_awarded: int
    level_up: bool = False
    new_level: int | None = None
    goal_reached: bool = False
    checkpoints_reached: int = 0
    # MentalCoins por passo (29/08/2026) — devolvido direto aqui pra tela
    # de Movimento poder atualizar o saldo sem precisar de mais uma
    # chamada de rede a cada coleta (a coleta ficou muito mais frequente
    # com a coleta automática em segundo plano).
    mentalcoins_awarded: int = 0


class MovementGoalRequest(BaseModel):
    # Achado de auditoria de segurança (28/08/2026): só exigia "maior que
    # zero" — uma meta de 1 passo garantia o bônus de meta (config.
    # MOVEMENT_GOAL_BONUS_XP) com esforço zero, todo ciclo.
    daily_goal_steps: int | None = Field(default=None, ge=config.MOVEMENT_MIN_DAILY_GOAL_STEPS)


class MovementGoalResponse(BaseModel):
    daily_goal_steps: int | None


class AddFriendRequest(BaseModel):
    invite_code: str


class FriendRequestOut(BaseModel):
    friendship_id: str
    from_user_id: str
    from_nickname: str


class FriendRequestsResponse(BaseModel):
    requests: list[FriendRequestOut]


class FriendOut(BaseModel):
    user_id: str
    nickname: str
    avatar_id: str | None = None
    real_name: str | None = None
    photo_url: str | None = None
    xp_total: int
    level: int


class FriendsResponse(BaseModel):
    friends: list[FriendOut]


class ShareRewardResponse(BaseModel):
    xp_awarded: int
    already_rewarded_today: bool
    xp_total: int
    level: int


class CreateBattleRequest(BaseModel):
    opponent_user_id: str
    territory_id: str
    difficulty_level: int


class CreateBattleResponse(BaseModel):
    battle_id: str
    challenge: ChallengeOut


class BattleOut(BaseModel):
    battle_id: str
    opponent_nickname: str
    opponent_avatar_id: str | None = None
    opponent_real_name: str | None = None
    opponent_photo_url: str | None = None
    territory_id: str
    difficulty_level: int
    role: str  # "challenger" | "opponent"
    status: str  # "pending" | "resolved"
    i_answered: bool
    opponent_answered: bool
    winner: str | None = None  # "me" | "opponent" | "tie" | None (ainda pending)
    win_bonus_xp: int = 0


class BattlesResponse(BaseModel):
    battles: list[BattleOut]


GenderValue = Literal["masculino", "feminino", "nao_binario", "prefiro_nao_informar"]
# Revisão 28/08/2026 (decisão de Rhoney): novas faixas etárias — 4
# faixas em vez das 5 anteriores (18-25/26-30/31-45/46-50/51+).
AgeRangeValue = Literal["18-25", "26-35", "36-45", "46+"]


class ProfileOut(BaseModel):
    nickname: str
    avatar_id: str | None
    # Revisão 26/08/2026: real_name agora também aparece em FriendOut/
    # RankingEntry/BattleOut (decisão de Rhoney, reverte a regra
    # anterior de "nunca público").
    real_name: str | None
    # Upload de foto real (26/08/2026, bucket privado desde 28/08/2026)
    # — photo_url aqui é sempre uma URL ASSINADA de curta duração
    # (services.own_photo_url), gerada na hora, nunca um link fixo.
    # photo_moderation_status é sempre visível pro PRÓPRIO dono (pra ele
    # saber se está pendente/aprovada/rejeitada), mas o link em si só
    # aparece pra outros usuários (Friends/Ranking/Battles) quando
    # 'approved' — USER_PROFILE.md §3.1, fail-closed.
    photo_url: str | None
    photo_moderation_status: str
    location_state: str | None
    location_country: str | None
    location_public: bool
    # Achado real (2026-08-26): o client mostrava a tela de confirmação
    # de maioridade a cada novo login, mesmo pra quem já tinha confirmado
    # antes — o estado só vivia em memória no app, nunca era checado
    # contra o backend. Expor aqui permite ao client pular a tela quando
    # já não-nulo, perguntando só uma vez por conta (nunca de novo).
    age_confirmed_at: datetime | None
    # Cadastro mínimo obrigatório (26/08/2026) — mesmo padrão acima:
    # onboarding_completed_at permite ao client pular a tela de cadastro
    # quando os 5 campos já foram preenchidos antes.
    city: str | None
    gender: str | None
    age_range: str | None
    onboarding_completed_at: datetime | None
    # Exposto pro client conseguir mostrar/esconder telas admin-only (ex.:
    # feedback dos usuários) sem duplicar essa checagem em endpoint
    # nenhum — a AUTORIZAÇÃO de verdade continua sempre no backend
    # (routers já checam role == "admin" antes de qualquer leitura), isto
    # aqui só decide o que aparece na UI.
    role: str


class UpdateProfileRequest(BaseModel):
    avatar_id: str | None = None
    # Achado de auditoria de segurança (28/08/2026): real_name é exibido
    # publicamente no ranking global desde a revisão de 27/08 (USER_
    # PROFILE.md), mas nunca teve limite de tamanho — texto livre sem
    # teto e sem moderação, visível pra toda a base. max_length não
    # resolve moderação de conteúdo (isso é uma pendência maior, sem
    # solução hoje), mas fecha o caso mais barato de abuso (payload
    # gigante/spam longo).
    real_name: str | None = Field(default=None, max_length=100)
    location_state: str | None = Field(default=None, max_length=100)
    location_country: str | None = Field(default=None, max_length=100)
    location_public: bool = False
    city: str | None = Field(default=None, max_length=100)
    gender: GenderValue | None = None
    age_range: AgeRangeValue | None = None
    # Upload de foto real (26/08/2026) — client já fez o upload direto
    # pro Supabase Storage e manda aqui o PATH resultante dentro do
    # bucket (ex.: "{user_id}/photo.jpg"), nunca uma URL — bucket
    # privado desde 28/08/2026 (DIR-001/POL-002), então uma URL pública
    # fixa não faria mais sentido nem funcionaria pra leitura. Um path
    # novo (diferente do já salvo) reseta a moderação pra 'pending'.
    photo_path: str | None = None


class ModerateProfilePhotoRequest(BaseModel):
    approved: bool


class AdminPendingPhotoItem(BaseModel):
    user_id: str
    nickname: str
    # URL assinada de curta duração (services.own_photo_url) — o admin
    # precisa conseguir VER a foto pra moderar, mesmo o bucket sendo
    # privado.
    photo_url: str | None = None


class ReportUserRequest(BaseModel):
    reported_user_id: str
    reason: str = Field(max_length=500)


class BlockUserRequest(BaseModel):
    blocked_user_id: str


class BlockedUserOut(BaseModel):
    user_id: str
    nickname: str
    real_name: str | None = None
    photo_url: str | None = None


class BlockedUsersResponse(BaseModel):
    blocked: list[BlockedUserOut]


class AdminReportItem(BaseModel):
    id: str
    reporter_user_id: str
    reported_user_id: str
    reported_nickname: str
    reported_photo_url: str | None = None
    reason: str
    created_at: datetime


class MentalCoinsBalanceOut(BaseModel):
    balance: int
    cycle_start: date
    cycle_end: date


class MentalCoinsTransactionOut(BaseModel):
    amount: int
    reason: str
    created_at: datetime


class MentalCoinsHallOfFameEntryOut(BaseModel):
    category: Literal["xp_daily", "steps_week", "steps_day"]
    rank: int | None = None
    reference_date: date | None = None
    user_id: str
    nickname: str
    real_name: str | None = None
    amount: int
    metric_value: int


class MentalCoinsCatalogItemOut(BaseModel):
    id: str
    name: str
    description: str
    cost: int
    item_type: str
    redeemed: bool


class RedeemMentalCoinsItemRequest(BaseModel):
    item_id: str


class MentalCoinsTransactionsResponse(BaseModel):
    transactions: list[MentalCoinsTransactionOut]


class MentalCoinsHallOfFameResponse(BaseModel):
    entries: list[MentalCoinsHallOfFameEntryOut]


class MentalCoinsCatalogResponse(BaseModel):
    items: list[MentalCoinsCatalogItemOut]
