"""
REGRA_OFICIAL_GAMIFICACAO_MENTAL.md — Fase 2 (19/09/2026): recompensas
novas. Cada regra tem (a) o caso que paga e (b) o caso anti-farm que NÃO
paga de novo — o segundo é o que mais importa, é a integridade da
economia (área que o agente mental-security revisa).
"""

import uuid
from datetime import date, timedelta

from app import config, models, rewards
from app.db import SessionLocal

from .conftest import auth_header
from .test_battles import _make_friends


def _new_user(client) -> tuple[str, dict]:
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    return user, headers


def _xp(client, headers) -> int:
    return client.get("/progress", headers=headers).json()["xp_total"]


def _coins(user: str) -> int:
    with SessionLocal() as db:
        row = db.get(models.MentalCoinsBalance, user)
        return row.balance if row else 0


# ------------------------------------------------------------- 4.1 login
def test_login_diario_paga_1_xp_uma_vez_por_dia(client):
    user, headers = _new_user(client)
    first = _xp(client, headers)  # 1ª chamada do dia já inclui o +1 do login
    assert first == config.LOGIN_DAILY_XP
    assert _xp(client, headers) == first  # N chamadas no mesmo dia não pagam de novo


def test_login_diario_paga_1_moeda_a_cada_2_dias(client):
    user, _ = _new_user(client)
    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        rewards.daily_login(db, profile, date(2026, 1, 1))
    assert _coins(user) == 0  # 1º login: só a meia moeda acumulada, saldo inteiro continua 0
    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        rewards.daily_login(db, profile, date(2026, 1, 1))  # mesmo dia: nada
    assert _coins(user) == 0
    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        rewards.daily_login(db, profile, date(2026, 1, 2))
    assert _coins(user) == config.LOGIN_COIN_AMOUNT  # 2 logins pagos -> 1 moeda


# ------------------------------------------------------------- 5 streak
def test_marco_de_streak_7_paga_xp_e_nao_repete_no_mesmo_dia(client):
    user, _ = _new_user(client)
    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        before = profile.xp_total
        rewards.on_streak_extended(db, profile, 7, date.today())
        rewards.on_streak_extended(db, profile, 7, date.today())  # duplicado
        assert profile.xp_total == before + 15


def test_marco_de_streak_30_paga_moedas_e_100_paga_mais(client):
    user, _ = _new_user(client)
    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        rewards.on_streak_extended(db, profile, 30, date.today())
        rewards.on_streak_extended(db, profile, 100, date.today())
    assert _coins(user) == 75 + 250


def test_streak_sem_marco_nao_paga_nada(client):
    user, _ = _new_user(client)
    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        before = profile.xp_total
        rewards.on_streak_extended(db, profile, 8, date.today())
        assert profile.xp_total == before
    assert _coins(user) == 0


def test_badges_de_streak_30_e_100_existem_no_catalogo(client):
    _, headers = _new_user(client)
    codes = {b["code"] for b in client.get("/badges", headers=headers).json()["badges"]}
    assert {"streak_30", "streak_100"} <= codes


# ------------------------------------------------------------ 3.2 amigos
def test_marco_de_5_amigos_paga_1_xp_uma_vez_por_marco(client):
    user, headers = _new_user(client)
    _xp(client, headers)  # consome o XP do login antes de medir
    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        before = profile.xp_total
    # 5 amizades confirmadas
    for _ in range(5):
        other = str(uuid.uuid4())
        _make_friends(client, user, other)
    with SessionLocal() as db:
        after = db.get(models.Profile, user).xp_total
    assert after == before + config.FRIEND_MILESTONE_XP
    # chamar de novo não repete o marco
    with SessionLocal() as db:
        rewards.on_friend_added(db, user)
        assert db.get(models.Profile, user).xp_total == after


# --------------------------------------------------------------- 3.3 torcida
def test_torcida_a_amigo_paga_1_xp_por_dia(client):
    a, b = str(uuid.uuid4()), str(uuid.uuid4())
    headers_a, _ = _make_friends(client, a, b)
    base = _xp(client, headers_a)
    client.post(f"/profile/{b}/torcida", json={"reaction_type": "joinha"}, headers=headers_a)
    assert _xp(client, headers_a) == base + config.TORCIDA_FRIEND_DAILY_XP
    client.post(f"/profile/{b}/torcida", json={"reaction_type": "coracao"}, headers=headers_a)
    assert _xp(client, headers_a) == base + config.TORCIDA_FRIEND_DAILY_XP  # 2ª do dia não paga


def test_torcida_a_desconhecido_nao_paga_xp(client):
    a, _ = _new_user(client)
    stranger, stranger_headers = _new_user(client)
    headers_a = auth_header(a)
    base = _xp(client, headers_a)
    client.post(f"/profile/{stranger}/torcida", json={"reaction_type": "joinha"}, headers=headers_a)
    assert _xp(client, headers_a) == base


# ----------------------------------------------------------- 4.3 feedback
def test_feedback_paga_5_xp_por_semana_e_exige_texto_minimo(client):
    _, headers = _new_user(client)
    base = _xp(client, headers)
    client.post("/feedback", json={"comment": "ok"}, headers=headers)  # curto demais
    assert _xp(client, headers) == base
    client.post("/feedback", json={"comment": "Gostei muito do app, parabéns!"}, headers=headers)
    assert _xp(client, headers) == base + config.FEEDBACK_WEEKLY_XP
    client.post("/feedback", json={"comment": "Outro comentário longo na mesma semana"}, headers=headers)
    assert _xp(client, headers) == base + config.FEEDBACK_WEEKLY_XP  # 2º da semana não paga


# -------------------------------------------------- 3.1 sequência social
def test_sequencia_social_de_7_dias_paga_10_xp_e_so_repete_em_nova_sequencia(client):
    user, _ = _new_user(client)
    today = date.today()
    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        before = profile.xp_total
        for back in range(6, 0, -1):  # 6 dias anteriores
            rewards.record_friend_interaction(db, user, today - timedelta(days=back))
        assert profile.xp_total == before  # ainda não fechou 7
        rewards.record_friend_interaction(db, user, today)  # 7º dia
        assert profile.xp_total == before + config.FRIEND_INTERACTION_STREAK_XP
        rewards.record_friend_interaction(db, user, today + timedelta(days=1))  # 8º dia
        assert profile.xp_total == before + config.FRIEND_INTERACTION_STREAK_XP  # não repete


def test_sequencia_social_com_dia_faltando_nao_paga(client):
    user, _ = _new_user(client)
    today = date.today()
    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        before = profile.xp_total
        for back in (6, 5, 4, 2, 1, 0):  # falta o dia -3
            rewards.record_friend_interaction(db, user, today - timedelta(days=back))
        assert profile.xp_total == before


# ------------------------------------------------------------ 2.2 Movimento
def test_7_dias_ativos_de_movimento_paga_10_moedas_uma_vez(client):
    user, _ = _new_user(client)
    today = date.today()
    for back in range(6, 0, -1):
        with SessionLocal() as db:
            rewards.on_movement_active_day(db, user, today - timedelta(days=back))
    assert _coins(user) == 0
    with SessionLocal() as db:
        rewards.on_movement_active_day(db, user, today)
        rewards.on_movement_active_day(db, user, today)  # duplicado
    assert _coins(user) == config.MOVEMENT_ACTIVE_STREAK_COINS


# ---------------------------------------------------------- claim genérico
def test_claim_e_idempotente(client):
    user, _ = _new_user(client)
    with SessionLocal() as db:
        assert rewards.try_claim(db, user, "teste:1") is True
        db.commit()
        assert rewards.try_claim(db, user, "teste:1") is False


def test_falha_numa_recompensa_nunca_propaga(client):
    user, _ = _new_user(client)

    def boom(db, *args):
        raise RuntimeError("falha simulada")

    with SessionLocal() as db:
        rewards.safely(boom, db)  # não levanta


# --------------------------- achados da revisão de segurança (20/09/2026)
def test_pergunta_achada_por_busca_nao_paga_bonus_de_lote(client):
    """Achado A2: GET /challenges/search serve com was_last_of_batch=True
    (não há 'próximo' num resultado de busca) — sem o marcador is_search,
    toda pergunta avulsa pagaria +3 XP de lote."""
    from app.seed import CHALLENGES

    user, headers = _new_user(client)
    sample = next(c for c in CHALLENGES if c["territory_id"] == "numeros")
    base = _xp(client, headers)  # já inclui o XP do login

    found = client.get("/challenges/search", params={"q": sample["prompt"][:20]}, headers=headers).json()["challenge"]
    correct = next(c["correct_answer"] for c in CHALLENGES if c["prompt"] == found["prompt"])
    result = client.post(
        f"/challenges/{found['challenge_id']}/answer",
        json={"attempt_id": found["attempt_id"], "submitted_answer": correct},
        headers=headers,
    ).json()

    assert result["is_correct"] is True
    assert _xp(client, headers) == base + result["xp_awarded"]  # sem +3 de lote
    with SessionLocal() as db:
        assert db.get(models.RewardClaim, (user, f"batch:{found['attempt_id']}")) is None


def test_reward_claims_referencia_o_usuario_com_cascade_na_migration():
    """Achado A1: LGPD — excluir a conta apaga o histórico de recompensas."""
    import pathlib

    sql = (pathlib.Path(__file__).resolve().parents[1] / "migrations" / "082_reward_claims_e_badges_streak.sql").read_text(encoding="utf-8")
    assert "references auth.users(id) on delete cascade" in sql
