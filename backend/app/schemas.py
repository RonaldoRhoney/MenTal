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
    # Migration 048 (LGPD, 01/09/2026): user_id vira NULL quando o autor
    # exclui a conta — o feedback (insumo de calibração de dificuldade)
    # é preservado anonimizado, nunca apagado.
    user_id: str | None
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
    # Migration 048 (LGPD, 01/09/2026): user_id vira NULL quando o autor
    # exclui a conta — o comentário (mural público, com resposta do
    # admin) é preservado anonimizado, nunca apagado.
    user_id: str | None
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
    # V4 — Detetive Mental (V4/V4_NOVOS_TERRITORIOS.md §4). 2-3 pistas,
    # em ordem de revelação — o client mostra uma de cada vez antes da
    # pergunta final (`prompt`). None em todo o resto do app.
    clues: list[str] | None = None
    # V4 — Ouvido Afiado (V4/V4_NOVOS_TERRITORIOS.md §3). Tudo-ou-nada,
    # mesmo padrão de video_url/source_name/source_url da Pausa para
    # Aprender de Libras. None em todo o resto do app.
    audio_url: str | None = None
    audio_source_name: str | None = None
    audio_source_url: str | None = None


class ChallengeSearchResponse(BaseModel):
    """
    Busca na Home (pedido de Rhoney, 2026-09-03): "tema, frase ou
    palavra" — found=True traz o desafio já servido (mesma autoridade
    de GET /challenges/next, attempt_id já criado), pronto pro client
    abrir direto em ChallengeScreen. found=False significa "não achamos
    nada pra isso" — o client então oferece registrar como sugestão via
    POST /content-suggestions.
    """

    found: bool
    challenge: ChallengeOut | None = None


class ContentSuggestionRequest(BaseModel):
    query_text: str = Field(min_length=1, max_length=200)


class ContentSuggestionResponse(BaseModel):
    ok: bool = True


class AdminContentSuggestionItem(BaseModel):
    id: str
    query_text: str
    created_at: str


class AdminContentSuggestionListResponse(BaseModel):
    items: list[AdminContentSuggestionItem]


class LearningPauseOut(BaseModel):
    # V3.2 (V3/V3.2_TECNOLOGIA.md §3) — "Pausa para Aprender": leitura
    # pura, sem options/correct_answer/timer (estrutura de conteúdo
    # deliberadamente diferente de ChallengeOut).
    learning_pause_id: str
    territory_id: str
    difficulty_level: int
    text: str
    prompt_image: str | None = None
    # V3.4 (V3/V3.4_LIBRAS.md §3.2) — vídeo institucional opcional, com
    # atribuição de fonte. Tudo-ou-nada: os 3 vêm juntos ou nenhum vem.
    video_url: str | None = None
    source_name: str | None = None
    source_url: str | None = None


class LearningPauseCompleteResponse(BaseModel):
    xp_awarded: int
    already_read_before: bool


class WordPuzzleOut(BaseModel):
    # V3.3 §6 (Jogos de Palavras, Fase 1: Caça-palavras) — a grade
    # inteira já vem resolvida (letras + preenchimento aleatório): não
    # existe "resposta escondida" pra proteger, diferente de ChallengeOut.
    # result_id identifica esta tentativa específica (equivalente ao
    # attempt_id de ChallengeOut) — nasce no servidor com started_at=agora,
    # usado depois em POST /word-puzzles/{result_id}/complete pra calcular
    # o tempo real decorrido (nunca confia em duração vinda do client).
    result_id: str
    puzzle_id: str
    territory_id: str
    difficulty_level: int
    theme: str
    grid_size: int
    grid: list[str]
    words: list[str]


class WordPuzzleCompleteRequest(BaseModel):
    found_words: list[str]


class WordPuzzleCompleteResponse(BaseModel):
    xp_awarded: int
    speed_bonus_xp: int
    already_completed_before: bool


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
    # BUG_PERGUNTAS_REPETINDO_SEQUENCIA.md §2.3 — True quando este era o
    # último item do lote sem repetição daquele território+dificuldade.
    # Client deve voltar à Home em vez de oferecer repetir/seguir (não
    # existe "próximo" real nesse ponto até o lote reembaralhar).
    batch_exhausted: bool = False
    # Pedido de Rhoney (2026-09-02): moedas sobem na tela quando o XP
    # total cruza um múltiplo de 100 OU o saldo de MentalCoins cruza um
    # múltiplo de 50 (services.crossed_coin_milestone) — puramente
    # visual, não é recompensa. Mesma regra de transição dos sinais
    # acima: nunca True de novo numa resposta idempotente reenviada.
    coin_milestone_reached: bool = False


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


class PublicProfileBadgeOut(BaseModel):
    """V4 item 1 — Perfil Público (PERFIL_PUBLICO_E_TORCIDA_V1.md §2):
    só badges CONQUISTADAS aparecem (nunca o catálogo inteiro com
    earned=False como em BadgeOut — não faz sentido mostrar pra outro
    usuário o que ele ainda não desbloqueou)."""

    code: str
    name: str
    description: str
    earned_at: str


class PublicProfileOut(BaseModel):
    """V4 item 1 — Perfil Público de outro usuário
    (PERFIL_PUBLICO_E_TORCIDA_V1.md §2). Regra central do documento:
    nunca expor dado que o próprio usuário não tenha já tornado público
    em algum outro lugar do app — mesmos campos de ProfileOut/
    RankingEntry (nickname, real_name, photo_url só se aprovada), nunca
    e-mail/localização granular/histórico de resposta individual/saldo
    de MentalCoins (decisão explícita: Hall da Fama só expõe o Top 3 da
    semana como reconhecimento pontual, não o saldo de qualquer usuário
    a qualquer momento — expor isso aqui seria uma exposição nova, não
    reaproveitamento de precedente)."""

    user_id: str
    nickname: str
    real_name: str | None
    photo_url: str | None
    level: int
    xp_total: int
    xp_per_level: int
    current_streak: int
    badges: list[PublicProfileBadgeOut]
    worlds: list[WorldProgressOut]
    # Território onde este usuário tem mais XP acumulado — null se ainda
    # não pontuou em nenhum território.
    best_territory_id: str | None
    best_territory_xp: int
    # V4 item 1 — Torcida: quantos incentivos EU (quem está vendo este
    # perfil agora) já mandei pra esta pessoa hoje, agregando os 4 tipos
    # (TORCIDA_MULTIPLA_V2.md §3) — o client usa isso pra decidir se
    # ainda mostra os botões de envio habilitados ou já bateu o teto.
    torcida_sent_today_by_me: int


class TorcidaSendRequest(BaseModel):
    reaction_type: Literal["vibracao", "balao", "coracao", "joinha"]


class TorcidaSendResponse(BaseModel):
    ok: bool = True
    # Total agregado (todos os tipos) já enviado por mim pra esta pessoa
    # hoje, incluindo este envio — permite ao client atualizar o estado
    # dos botões sem precisar de uma segunda chamada.
    sent_today_by_me: int


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
    # V4 item 1 — Perfil Público (PERFIL_PUBLICO_E_TORCIDA_V1.md §3):
    # antes desta feature o Ranking deliberadamente NÃO expunha user_id
    # (só nickname/xp) — a feature de Perfil Público autoriza
    # explicitamente Ranking como ponto de entrada, então precisa dele
    # agora. Nickname/XP continuam sendo o dado "primário" do ranking;
    # user_id só existe pra abrir GET /profile/{id}/public.
    user_id: str
    nickname: str
    avatar_id: str | None = None
    # Revisão 26/08/2026: nome real e foto de perfil (só se aprovada na
    # moderação) passam a ser públicos, reversão da regra anterior.
    real_name: str | None = None
    photo_url: str | None = None
    xp: int
    # RANKING_ENRIQUECIDO_V1.md §2 — resumo de conquistas por linha, pra
    # não exigir abrir o perfil de cada jogador só pra ver o quanto ele
    # evoluiu. Tudo dado já calculado em outro lugar do app (streak,
    # progresso de mundo, badges, MentalCoins, passos) — nenhuma lógica
    # de cálculo nova, só exposição.
    level: int
    current_streak: int
    worlds_completed: int
    worlds_total: int
    badges_count: int
    mentalcoins_balance: int
    total_steps: int


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


class MovementMonthSummaryOut(BaseModel):
    month: int
    total_steps: int
    active_days: int
    # MOVIMENTO_GRAFICOS_RICOS_V1.md §6 — destaca o mês de melhor
    # desempenho no gráfico de Ano.
    is_best: bool = False


class MovementYearlySummaryOut(BaseModel):
    year: int
    months: list[MovementMonthSummaryOut]
    total_steps: int
    active_days: int
    average_steps_per_active_day: int
    best_month: int | None
    total_xp_awarded: int


class MovementGoalRequest(BaseModel):
    # Achado de auditoria de segurança (28/08/2026): só exigia "maior que
    # zero" — uma meta de 1 passo garantia o bônus de meta (config.
    # MOVEMENT_GOAL_BONUS_XP) com esforço zero, todo ciclo.
    daily_goal_steps: int | None = Field(default=None, ge=config.MOVEMENT_MIN_DAILY_GOAL_STEPS)


class MovementGoalResponse(BaseModel):
    daily_goal_steps: int | None


# MOVIMENTO_GRAFICOS_RICOS_V1.md §3 — 6 sessões de 4h do dia, cada uma
# com frase descritiva gerada dinamicamente a partir do padrão real do
# usuário (nunca texto fixo desacoplado do dado).
class MovementDaySessionOut(BaseModel):
    label: str
    emoji: str
    start_hour: int
    end_hour: int
    steps: int
    is_peak: bool
    description: str


class MovementDailyChartOut(BaseModel):
    sessions: list[MovementDaySessionOut]


class MovementMonthDayOut(BaseModel):
    day: int
    steps: int
    is_best: bool = False


class MovementMonthlyChartOut(BaseModel):
    year: int
    month: int
    days: list[MovementMonthDayOut]
    total_steps: int
    active_days: int
    average_steps_per_active_day: int


# MOVIMENTO_GRAFICOS_RICOS_V1.md §7 — histórico completo dia a dia,
# paginado. next_cursor é o cycle_start_at (ISO) do último item da
# página — passar de volta como `before` na próxima chamada.
class MovementHistoryItemOut(BaseModel):
    day_number: int
    date: str
    steps: int
    xp_awarded: int
    cumulative_steps: int
    goal_reached: bool


class MovementHistoryPageOut(BaseModel):
    items: list[MovementHistoryItemOut]
    next_cursor: str | None


class AddFriendRequest(BaseModel):
    invite_code: str


class SendFriendRequestRequest(BaseModel):
    to_user_id: str


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


# AMIGOS_CONVITE_POR_NOME.md §5 — resultado de busca por nome. Nunca
# inclui e-mail ou outro dado sensível: só o que já é público (nome,
# foto, nível), o mínimo necessário para identificar a pessoa certa
# entre homônimos (§4 do doc).
class UserSearchResultOut(BaseModel):
    user_id: str
    nickname: str
    real_name: str | None = None
    photo_url: str | None = None
    level: int
    friendship_status: str | None = None  # None|"pending"|"accepted"


class UserSearchResponse(BaseModel):
    results: list[UserSearchResultOut]


class ShareRewardResponse(BaseModel):
    xp_awarded: int
    already_rewarded_today: bool
    xp_total: int
    level: int


class AppInviteShareRewardResponse(BaseModel):
    xp_awarded: int
    mentalcoins_awarded: int
    already_rewarded_today: bool
    xp_total: int
    level: int
    mentalcoins_balance: int
    coin_milestone_reached: bool = False


class CreateBattleRequest(BaseModel):
    opponent_user_id: str
    territory_id: str
    difficulty_level: int


class CreateBattleResponse(BaseModel):
    battle_id: str
    challenge: ChallengeOut


class BattleOut(BaseModel):
    battle_id: str
    # V4 item 1 — Perfil Público (PERFIL_PUBLICO_E_TORCIDA_V1.md §3):
    # Batalha é um dos pontos de entrada aprovados pra visitar o perfil
    # do oponente — precisa do user_id dele pra isso.
    opponent_user_id: str
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


# U.I/ADMIN_PAINEL_IN_APP_V1.md — painel administrativo leve, dentro do
# próprio app Flutter (visível só pra role=admin). Métricas listadas na
# seção 3 do documento; deliberadamente mais enxuto que o painel externo
# maior (ADMIN_DASHBOARD_V1.md, ainda não implementado).
class AdminTopProgressorOut(BaseModel):
    user_id: str
    nickname: str
    real_name: str | None = None
    photo_url: str | None = None
    level: int
    xp_gained: int
    current_streak: int


class AdminTerritoryAccuracyOut(BaseModel):
    territory_id: str
    total_attempts: int
    accuracy_percent: float


class AdminFeedbackDistributionOut(BaseModel):
    facil: int = 0
    medio: int = 0
    dificil: int = 0
    muito_dificil: int = 0


class AdminDemographicBucketOut(BaseModel):
    label: str
    count: int


class AdminDemographicsOut(BaseModel):
    # Distribuição sobre a base TOTAL de perfis com cadastro completo
    # (onboarding_completed_at preenchido) — não é escopada pelo seletor
    # de período (today/7d/30d), porque gênero/faixa etária/localização
    # são atributos estáveis do perfil, não eventos que aconteceram
    # "dentro" de uma janela de tempo. Só perfis com valor preenchido
    # entram nos buckets — quem não informou não aparece, não vira
    # "outros" (nunca inventar dado que o usuário não deu).
    gender: list[AdminDemographicBucketOut]
    age_range: list[AdminDemographicBucketOut]
    state: list[AdminDemographicBucketOut]
    city: list[AdminDemographicBucketOut]


class AdminMovementMetricsOut(BaseModel):
    # enabled_users é sobre a base TOTAL (ligou o recurso alguma vez),
    # igual à filosofia de AdminDemographicsOut — não escopado pelo
    # período. O resto é escopado pelo período selecionado (today/7d/30d),
    # contado por ciclo iniciado dentro da janela (MovementCycle.
    # cycle_start_at), mesma semântica de "criado dentro do período" já
    # usada em new_signups_in_period.
    enabled_users: int
    active_users_in_period: int
    total_steps_in_period: int
    total_xp_in_period: int
    average_steps_per_active_user: int
    goal_distribution: list[AdminDemographicBucketOut]


class AdminMetricsSummaryOut(BaseModel):
    active_users_today: int
    active_users_week: int
    new_signups_in_period: int
    engaged_users_in_period: int
    average_streak_active_users: float
    top_progressors: list[AdminTopProgressorOut]
    accuracy_by_territory: list[AdminTerritoryAccuracyOut]
    feedback_distribution: AdminFeedbackDistributionOut
    demographics: AdminDemographicsOut
    movement: AdminMovementMetricsOut
