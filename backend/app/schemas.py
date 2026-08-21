from pydantic import BaseModel


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


class AnswerResponse(BaseModel):
    is_correct: bool
    correct_answer: str
    explanation: str
    xp_base: int
    hints_used: int
    xp_awarded: int
    streak: StreakOut
    territory_progress: TerritoryProgressOut


class ProgressTerritoryOut(BaseModel):
    territory_id: str
    xp_in_territory: int
    unlocked: bool
    conquered: bool
    conquest_threshold: int


class ProgressResponse(BaseModel):
    xp_total: int
    level: int
    xp_per_level: int
    territories: list[ProgressTerritoryOut]
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


class BadgeOut(BaseModel):
    code: str
    name: str
    description: str
    earned: bool
    earned_at: str | None


class BadgesResponse(BaseModel):
    badges: list[BadgeOut]
