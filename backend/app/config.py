import os

DATABASE_URL = os.environ.get("MENTAL_DATABASE_URL", "sqlite:///./mental_dev.db")

SUPABASE_JWT_SECRET = os.environ.get("SUPABASE_JWT_SECRET")

DAILY_FREE_CHALLENGE_LIMIT = 8
HINT_PENALTY_FACTOR = 0.25
STREAK_FREEZE_PER_WEEK = 1

# Decisões de implementação do Vertical Slice 01, sem dado real ainda
# (TERRITORIES.md §3 e GAMIFICATION.md §4 deixavam esses valores em
# aberto) — centralizadas aqui de propósito, a pedido de Rhoney, para
# serem achadas e ajustadas num único lugar quando houver telemetria real.
CONQUEST_XP_THRESHOLD = 200
XP_PER_LEVEL = 100
XP_BASE_BY_DIFFICULTY = {1: 10, 2: 20, 3: 30, 4: 40, 5: 50}
XP_BASE_DEFAULT = 20

# Dificuldade adaptativa (ADAPTIVE_DIFFICULTY.md §6, fórmula em aberto na
# Foundation): janela de tentativas recentes observada e limiares de
# acerto que sobem/descem 1 nível de dificuldade.
ADAPTIVE_DIFFICULTY_WINDOW = 5
ADAPTIVE_DIFFICULTY_MIN_SAMPLE = 3
ADAPTIVE_DIFFICULTY_UP_THRESHOLD = 0.8
ADAPTIVE_DIFFICULTY_DOWN_THRESHOLD = 0.4
ADAPTIVE_DIFFICULTY_MIN_LEVEL = 1
ADAPTIVE_DIFFICULTY_MAX_LEVEL = 5
