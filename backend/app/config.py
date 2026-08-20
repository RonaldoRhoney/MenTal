import os

DATABASE_URL = os.environ.get("MENTAL_DATABASE_URL", "sqlite:///./mental_dev.db")

# SUPABASE_URL (ex.: "https://xxxx.supabase.co") ativa a validação real de
# token via JWKS (chave pública do projeto, buscada em
# {SUPABASE_URL}/auth/v1/.well-known/jwks.json — não é segredo, pode ficar
# em variável de ambiente comum). Projeto MENTAL usa assinatura assimétrica
# ES256 (ECC P-256) como chave atual, não o modelo legado de segredo
# compartilhado HS256 — confirmado no painel do projeto em 2026-08-19
# (Settings → API → JWT Keys mostra "Legacy HS256" como PREVIOUS KEY, não
# CURRENT KEY). SUPABASE_JWT_SECRET fica como fallback só para projeto que
# ainda esteja no modelo legado.
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_JWT_SECRET = os.environ.get("SUPABASE_JWT_SECRET")

# MONETIZATION_UPDATE_FREE_LAUNCH.md: MENTAL lança 100% gratuito. Quando
# false (default), toda checagem de "território exige assinatura" é
# ignorada em services.is_territory_unlocked — ponto único de verificação,
# nunca espalhado por múltiplos arquivos, para que ativar cobrança no
# futuro seja só mudar esta env var. Nenhuma tabela/endpoint de assinatura
# é removida — a estrutura inteira continua existindo, só não é aplicada.
MONETIZATION_ENABLED = os.environ.get("MONETIZATION_ENABLED", "false").lower() == "true"

# Limite diário: 8 (original) → 20 (decisão de Rhoney, 2026-08-19) → 24
# (MONETIZATION_UPDATE_FREE_LAUNCH.md §3, 2026-08-20). Com o lançamento
# 100% gratuito, a única função deste limite deixou de ser "incentivo a
# assinar" e passou a ser puramente hábito/retenção via streak — por isso
# o valor final é mais alto que os dois anteriores, calibrados quando o
# limite ainda carregava pressão de conversão. Continua ativo mesmo com
# MONETIZATION_ENABLED=false (não tem relação com dinheiro, é ritmo de
# uso). Centralizado aqui — nunca hardcoded em mais de um lugar.
DAILY_FREE_CHALLENGE_LIMIT = 24
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

# Parental gate (MONETIZATION.md §5): correção de segurança pedida por
# Rhoney na revisão do Vertical Slice 01 — parental_gate_passed_at NÃO
# pode valer para sempre depois de passado uma vez (cenário de risco real:
# criança usa o celular do adulto meses depois, já logado, e o backend
# aceitaria a compra achando que o gate "já foi validado"). A janela é
# curta o suficiente para completar o fluxo de checkout em andamento,
# curta demais para servir de autorização permanente.
PARENTAL_GATE_VALIDITY_MINUTES = 10
