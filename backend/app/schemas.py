from datetime import datetime

from pydantic import BaseModel, Field


class AgeGateRequest(BaseModel):
    age_mode: str  # "child" | "adult"


class AgeGateResponse(BaseModel):
    child_safe_mode: bool
    nickname: str


class ChallengeOut(BaseModel):
    challenge_id: str
    territory_id: str
    difficulty_level: int
    prompt: str
    options: list[str] | None
    hints_available: int


class HintRequest(BaseModel):
    attempt_id: str


class HintResponse(BaseModel):
    hint_level: int
    content: str


class AnswerRequest(BaseModel):
    attempt_id: str
    submitted_answer: str


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


class ProgressTerritoryOut(BaseModel):
    territory_id: str
    xp_in_territory: int
    unlocked: bool
    conquered: bool
    conquest_threshold: int


class WorldProgressOut(BaseModel):
    world_id: str
    name: str
    territory_ids: list[str]
    completed: bool


class ProgressResponse(BaseModel):
    xp_total: int
    level: int
    xp_per_level: int
    territories: list[ProgressTerritoryOut]
    worlds: list[WorldProgressOut]
    streak: StreakOut


class SubscriptionStatusResponse(BaseModel):
    status: str
    expires_at: str | None


class ValidateReceiptRequest(BaseModel):
    purchase_token: str


class RankingEntry(BaseModel):
    rank: int
    nickname: str
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


class MovementCycleOut(BaseModel):
    id: str
    cycle_start_at: datetime
    cycle_end_at: datetime
    steps_collected: int
    xp_awarded: int


class MovementStatusResponse(BaseModel):
    movement_enabled: bool
    daily_goal_steps: int | None
    current_cycle: MovementCycleOut | None
    pending_report_cycle: MovementCycleOut | None


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


class MovementGoalRequest(BaseModel):
    daily_goal_steps: int | None = Field(default=None, gt=0)


class MovementGoalResponse(BaseModel):
    daily_goal_steps: int | None


class AddFriendRequest(BaseModel):
    invite_code: str


class FriendOut(BaseModel):
    nickname: str
    xp_total: int
    level: int


class FriendsResponse(BaseModel):
    friends: list[FriendOut]
