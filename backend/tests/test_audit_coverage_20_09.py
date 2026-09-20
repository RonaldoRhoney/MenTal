"""
Lacunas de cobertura apontadas pela auditoria de 20/09/2026 (agente
mental-testing): autenticação JWT, age gate sistêmico, regras de lote,
apuração semanal tudo-ou-nada, desempate do Top 3, dia de Brasília no
endpoint, job de recuperação, Constelação (guardas), add_profile_xp,
máscara de bloqueio nas respostas do mural e varredura de conteúdo real.
"""

import time
import uuid
from datetime import date, datetime, timedelta

import jwt
import pytest
from fastapi.routing import APIRoute

from app import config, mentalcoins, models, rewards, scheduler, seed, services, timeutil
from app.db import SessionLocal
from app.main import app
from app.timeutil import utcnow

from .conftest import auth_header
from .test_celebration_signals import _answer_correctly
from .test_rewards_fase2 import _new_user, _xp

# ---------------------------------------------------------------- C1: JWT


def _hs256(secret: str, **overrides) -> str:
    payload = {"sub": str(uuid.uuid4()), "aud": "authenticated", "exp": int(time.time()) + 300}
    payload.update(overrides)
    return jwt.encode({k: v for k, v in payload.items() if v is not None}, secret, algorithm="HS256")


@pytest.fixture
def hs256_mode(monkeypatch):
    monkeypatch.setattr(config, "SUPABASE_URL", None)
    monkeypatch.setattr(config, "SUPABASE_JWT_SECRET", "segredo-de-teste-com-32-bytes-ou-mais!!")
    return config.SUPABASE_JWT_SECRET


def test_sem_header_authorization_401(client):
    resp = client.get("/profile")
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "UNAUTHENTICATED"


def test_hs256_token_valido_autentica(client, hs256_mode):
    resp = client.get("/profile", headers={"Authorization": f"Bearer {_hs256(hs256_mode)}"})
    assert resp.status_code == 200


def test_hs256_expirado_assinatura_errada_audience_errada_e_sem_sub_401(client, hs256_mode):
    bad = {
        "expirado": _hs256(hs256_mode, exp=int(time.time()) - 10),
        "assinatura_errada": _hs256("outro-segredo-de-teste-com-32-bytes!!!!!"),
        "audience_errada": _hs256(hs256_mode, aud="anon"),
        "sem_sub": _hs256(hs256_mode, sub=None),
    }
    for name, token in bad.items():
        resp = client.get("/profile", headers={"Authorization": f"Bearer {token}"})
        assert resp.status_code == 401, name
        assert resp.json()["error"]["code"] == "INVALID_TOKEN", name


def test_alg_none_e_rejeitado(client, hs256_mode):
    token = jwt.encode({"sub": str(uuid.uuid4()), "aud": "authenticated"}, key=None, algorithm="none")
    resp = client.get("/profile", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 401


def test_com_secret_configurado_uuid_puro_nao_e_aceito(client, hs256_mode):
    # O modo DEV_INSECURE (token = user_id) nunca pode vazar pra produção.
    resp = client.get("/profile", headers=auth_header(str(uuid.uuid4())))
    assert resp.status_code == 401


# ---------------------------------------------------------- C2: age gate

# Rotas que deliberadamente NÃO exigem maioridade confirmada (GET /profile e
# /age-gate precisam funcionar antes da confirmação; admin decide por role).
AGE_GATE_ALLOWLIST_PREFIXES = ("/age-gate", "/admin/")
AGE_GATE_ALLOWLIST_EXACT = {("GET", "/profile"), ("PUT", "/profile"), ("GET", "/health")}


def test_toda_rota_exige_age_confirmado_exceto_allowlist(client):
    """Uma rota nova sem o gate faz este teste falhar — força decisão explícita."""
    user = str(uuid.uuid4())
    headers = auth_header(user)  # usuário SEM /age-gate confirmado
    leaks = []
    for route in app.routes:
        if not isinstance(route, APIRoute):
            continue
        path = route.path
        if path.startswith(AGE_GATE_ALLOWLIST_PREFIXES):
            continue
        url = "".join(part if not part.startswith("{") else str(uuid.uuid4()) for part in path.replace("}", "}\x00").replace("{", "\x00{").split("\x00"))
        for method in route.methods - {"HEAD", "OPTIONS"}:
            if (method, path) in AGE_GATE_ALLOWLIST_EXACT:
                continue
            resp = client.request(method, url, headers=headers, json={} if method in {"POST", "PUT", "PATCH"} else None)
            detail = resp.json() if resp.headers.get("content-type", "").startswith("application/json") else {}
            code = (detail.get("error") or {}).get("code") if isinstance(detail, dict) else None
            if not (resp.status_code == 403 and code == "AGE_NOT_CONFIRMED"):
                leaks.append((method, path, resp.status_code, code))
    assert leaks == [], f"rotas sem gate de maioridade (decida: incluir na allowlist ou proteger): {leaks}"


# ----------------------------------------------------------- C3: lote +3/+5


def _batch(user: str, answers: list[tuple[bool, int]], start: datetime, territory="numeros", level=1):
    """Cria um lote de tentativas respondidas e devolve (attempt final, challenge)."""
    with SessionLocal() as db:
        challenges = (
            db.query(models.Challenge)
            .filter(models.Challenge.territory_id == territory, models.Challenge.difficulty_level == level)
            .limit(len(answers))
            .all()
        )
        assert len(challenges) == len(answers)
        last = None
        for i, ((correct, hints), challenge) in enumerate(zip(answers, challenges)):
            attempt = models.Attempt(
                attempt_id=str(uuid.uuid4()),
                user_id=user,
                challenge_id=challenge.id,
                is_correct=correct,
                hints_used=hints,
                timed=False,
                was_last_of_batch=(i == len(answers) - 1),
                created_at=start + timedelta(seconds=i),
            )
            db.add(attempt)
            last = attempt
        db.commit()
        return last.attempt_id, challenges[-1].id


def _pay_batch(user: str, attempt_id: str, challenge_id: str) -> int:
    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        before = profile.xp_total
        attempt = db.get(models.Attempt, attempt_id)
        challenge = db.get(models.Challenge, challenge_id)
        rewards.on_batch_completed(db, profile, attempt, challenge)
        db.refresh(profile)
        return profile.xp_total - before


def test_lote_perfeito_paga_3_mais_5_e_o_replay_nao_paga_de_novo(client):
    user, _ = _new_user(client)
    attempt_id, challenge_id = _batch(user, [(True, 0), (True, 0)], datetime(2026, 1, 1, 10, 0))
    assert _pay_batch(user, attempt_id, challenge_id) == config.BATCH_COMPLETE_BONUS_XP + config.BATCH_PERFECT_BONUS_XP
    assert _pay_batch(user, attempt_id, challenge_id) == 0  # replay da última resposta
    with SessionLocal() as db:
        assert rewards.has_claim(db, user, f"batch:{attempt_id}") and rewards.has_claim(db, user, f"batchperfect:{attempt_id}")


def test_lote_com_erro_ou_dica_paga_so_os_3(client):
    for answers in ([(True, 0), (False, 0)], [(True, 0), (True, 1)]):
        user, _ = _new_user(client)
        attempt_id, challenge_id = _batch(user, answers, datetime(2026, 1, 2, 10, 0))
        assert _pay_batch(user, attempt_id, challenge_id) == config.BATCH_COMPLETE_BONUS_XP


def test_lote_de_uma_resposta_so_nao_e_perfeito(client):
    user, _ = _new_user(client)
    attempt_id, challenge_id = _batch(user, [(True, 0)], datetime(2026, 1, 3, 10, 0))
    assert config.BATCH_PERFECT_MIN_ANSWERS >= 2
    assert _pay_batch(user, attempt_id, challenge_id) == config.BATCH_COMPLETE_BONUS_XP


def test_lote_seguinte_nao_herda_o_erro_do_lote_anterior(client):
    user, _ = _new_user(client)
    first, c1 = _batch(user, [(True, 0), (False, 0)], datetime(2026, 1, 4, 10, 0))
    assert _pay_batch(user, first, c1) == config.BATCH_COMPLETE_BONUS_XP
    second, c2 = _batch(user, [(True, 0), (True, 0)], datetime(2026, 1, 4, 11, 0))
    assert _pay_batch(user, second, c2) == config.BATCH_COMPLETE_BONUS_XP + config.BATCH_PERFECT_BONUS_XP


# --------------------------------------------- C4/A1/A3: apuração semanal


def _attempt_xp(user: str, xp: int, when: datetime) -> None:
    with SessionLocal() as db:
        db.add(models.Attempt(attempt_id=str(uuid.uuid4()), user_id=user, challenge_id=str(uuid.uuid4()), is_correct=True, xp_awarded=xp, created_at=when))
        db.commit()


def _balance(user: str) -> int:
    with SessionLocal() as db:
        row = db.get(models.MentalCoinsBalance, user)
        return row.balance if row else 0


def test_apuracao_que_falha_no_meio_nao_deixa_ciclo_marcado_nem_pago_pela_metade(monkeypatch):
    start = date(2019, 3, 4)  # segunda
    users = [str(uuid.uuid4()) for _ in range(3)]
    for i, u in enumerate(users):
        _attempt_xp(u, 100 - i, datetime(2019, 3, 5, 10, i))

    real_credit = mentalcoins.credit
    calls = {"n": 0}

    def flaky(db, user_id, amount, reason, commit=True):
        calls["n"] += 1
        if calls["n"] == 2:
            raise RuntimeError("falha simulada")
        return real_credit(db, user_id, amount, reason, commit=commit)

    monkeypatch.setattr(mentalcoins, "credit", flaky)
    with SessionLocal() as db:
        with pytest.raises(RuntimeError):
            mentalcoins.run_weekly_apuration(db, start, start + timedelta(days=6))
    # nada pago, nada marcado: o job de recuperação pode tentar de novo
    assert all(_balance(u) == 0 for u in users)
    with SessionLocal() as db:
        assert db.get(models.MentalCoinsProcessedCycle, start) is None

    monkeypatch.setattr(mentalcoins, "credit", real_credit)
    with SessionLocal() as db:
        result = mentalcoins.run_weekly_apuration(db, start, start + timedelta(days=6))
    assert result["already_processed"] is False
    assert [_balance(u) for u in users] == list(config.MENTALCOINS_XP_DAILY_REWARDS[:3])


def test_top3_diario_com_empate_no_teto_e_deterministico():
    start = date(2019, 4, 1)
    users = [str(uuid.uuid4()) for _ in range(4)]
    for i, u in enumerate(users):  # todos batem o teto; o primeiro a terminar vence
        _attempt_xp(u, config.DAILY_ANSWER_XP_CAP, datetime(2019, 4, 2, 9, i))
    with SessionLocal() as db:
        mentalcoins.run_weekly_apuration(db, start, start + timedelta(days=6))
    assert [_balance(u) for u in users] == [*config.MENTALCOINS_XP_DAILY_REWARDS[:3], 0]


def test_catchup_job_apura_o_ciclo_fechado_uma_vez_so(monkeypatch):
    start = date(2019, 5, 6)
    user = str(uuid.uuid4())
    _attempt_xp(user, 50, datetime(2019, 5, 8, 10, 0))
    monkeypatch.setattr(mentalcoins, "last_closed_cycle_bounds", lambda now=None: (start, start + timedelta(days=6)))
    scheduler._run_mentalcoins_catchup_job()
    first = _balance(user)
    assert first == config.MENTALCOINS_XP_DAILY_REWARDS[0]
    scheduler._run_mentalcoins_catchup_job()  # 09:00 depois do job de segunda 08:00
    assert _balance(user) == first


def test_catchup_job_engole_excecao(monkeypatch):
    monkeypatch.setattr(mentalcoins, "last_closed_cycle_bounds", lambda now=None: (_ for _ in ()).throw(RuntimeError("x")))
    scheduler._run_mentalcoins_catchup_job()  # não levanta


def test_scheduler_registra_apuracao_de_segunda_e_recuperacao_diaria(monkeypatch):
    added = []

    class FakeScheduler:
        def add_job(self, func, trigger, **kwargs):
            added.append((func.__name__, trigger, kwargs))

        def start(self):
            pass

    monkeypatch.setattr(scheduler, "_scheduler", None)
    monkeypatch.setattr(scheduler, "BackgroundScheduler", lambda: FakeScheduler())
    monkeypatch.setattr(config, "NOTIFICATION_SCHEDULER_ENABLED", False)
    monkeypatch.setattr(config, "MENTALCOINS_SCHEDULER_ENABLED", True)
    scheduler.start_scheduler()
    monkeypatch.setattr(scheduler, "_scheduler", None)
    names = {name: kwargs for name, _, kwargs in added}
    assert names["_run_mentalcoins_job"]["day_of_week"] == "mon" and names["_run_mentalcoins_job"]["hour"] == 8
    assert names["_run_mentalcoins_catchup_job"]["hour"] == 9
    assert all(k["timezone"] == config.MENTALCOINS_TIMEZONE for k in names.values())


# --------------------------------------------- A2: dia de Brasília (endpoint)


def test_teto_vira_a_meia_noite_de_brasilia_no_endpoint(client, monkeypatch):
    user, headers = _new_user(client)
    monkeypatch.setattr(timeutil, "utcnow", lambda: datetime(2026, 9, 21, 1, 0))  # 22:00 do dia 20 em Brasília
    assert timeutil.brasilia_today() == date(2026, 9, 20)
    _answer_correctly(client, headers, "numeros")
    with SessionLocal() as db:
        assert db.get(models.DailyAnswerXp, (user, date(2026, 9, 20))) is not None
        assert db.get(models.DailyAnswerXp, (user, date(2026, 9, 21))) is None


# ------------------------------------------------ A4: guardas da Constelação


def _idioma_challenge(prompt="Como se escreve 'casa' em inglês?", answer="House"):
    with SessionLocal() as db:
        challenge = models.Challenge(
            territory_id="ingles_basico", difficulty_level=1, prompt=prompt, options=[answer, "x", "y", "z"], correct_answer=answer, explanation="x", age_reviewed=True
        )
        db.add(challenge)
        db.commit()
        db.refresh(challenge)
        return challenge.id


def _served_attempt(user: str, challenge_id: str, correct=True, age_hours=0):
    with SessionLocal() as db:
        db.add(
            models.Attempt(
                attempt_id=str(uuid.uuid4()), user_id=user, challenge_id=challenge_id, is_correct=correct, created_at=utcnow() - timedelta(hours=age_hours)
            )
        )
        db.commit()


def test_constelacao_resposta_errada_tambem_libera_a_rodada(client):
    user, headers = _new_user(client)
    cid = _idioma_challenge()
    _served_attempt(user, cid, correct=False)
    assert client.get(f"/challenges/{cid}/word-constellation", headers=headers).status_code == 200


def test_constelacao_resposta_muito_antiga_nao_libera(client):
    user, headers = _new_user(client)
    cid = _idioma_challenge()
    _served_attempt(user, cid, age_hours=config.WORD_CONSTELLATION_MAX_AGE_HOURS + 1)
    assert client.get(f"/challenges/{cid}/word-constellation", headers=headers).status_code == 403


def test_constelacao_territorio_bloqueado_403(client, monkeypatch):
    user, headers = _new_user(client)
    cid = _idioma_challenge()
    _served_attempt(user, cid)
    monkeypatch.setattr(services, "is_territory_unlocked", lambda *a, **k: False)
    resp = client.get(f"/challenges/{cid}/word-constellation", headers=headers)
    assert resp.status_code == 403 and resp.json()["error"]["code"] == "TERRITORY_LOCKED"


def test_constelacao_rate_limit_429(client, monkeypatch):
    user, headers = _new_user(client)
    cid = _idioma_challenge()
    _served_attempt(user, cid)
    monkeypatch.setattr(config, "RATE_LIMIT_WORD_CONSTELLATION", (2, 60.0))
    codes = [client.get(f"/challenges/{cid}/word-constellation", headers=headers).status_code for _ in range(4)]
    assert codes[:2] == [200, 200] and 429 in codes[2:]


# ------------------------------------------------ A5: add_profile_xp atômico


def test_add_profile_xp_soma_recalcula_nivel_e_ignora_zero_e_negativo(client):
    user, _ = _new_user(client)
    with SessionLocal() as db:
        profile = db.get(models.Profile, user)
        services.add_profile_xp(db, profile, 0)
        services.add_profile_xp(db, profile, -5)
        assert profile.xp_total == 0
        services.add_profile_xp(db, profile, config.XP_PER_LEVEL * 2 + 1)
        db.commit()
        assert profile.xp_total == config.XP_PER_LEVEL * 2 + 1
        assert profile.level >= 3


def test_add_profile_xp_preserva_mudanca_pendente_e_soma_sobre_o_valor_do_banco(client):
    user, _ = _new_user(client)
    with SessionLocal() as stale_db, SessionLocal() as other_db:
        stale = stale_db.get(models.Profile, user)  # xp_total lido = 0
        other = other_db.get(models.Profile, user)
        services.add_profile_xp(other_db, other, 10)
        other_db.commit()
        stale.last_share_reward_date = date(2026, 1, 1)  # mudança pendente
        services.add_profile_xp(stale_db, stale, 5)  # soma em SQL: 10 + 5, não 0 + 5
        stale_db.commit()
        assert stale.xp_total == 15
        assert stale.last_share_reward_date == date(2026, 1, 1)


# ------------------------------------------- A6: mural — bloqueio nas respostas


def test_resposta_de_usuario_bloqueado_aparece_como_generica_sem_nome_real(client):
    _, viewer = _new_user(client)
    other_id, other = _new_user(client)
    # comentário do "viewer" e resposta do "other"
    client.post("/feedback", json={"comment": f"Comentário {uuid.uuid4()}"}, headers=viewer)
    items = client.get("/feedback", headers=viewer).json()["items"]
    fid = items[0]["id"]
    client.post(f"/feedback/{fid}/replies", json={"comment": "resposta do bloqueado"}, headers=other)
    # viewer bloqueia other
    assert client.post("/social/block", json={"blocked_user_id": other_id}, headers=viewer).status_code == 200
    item = next(i for i in client.get("/feedback", headers=viewer).json()["items"] if i["id"] == fid)
    reply = item["replies"][0]
    assert reply["user_nickname"] == "Usuário" and reply["user_real_name"] is None


# ------------------------------------------------ conteúdo real (premissa)


def test_todo_desafio_idiomas_de_palavra_unica_tem_significado_extraivel_e_distratores():
    """A lição de 19/09 (~55 itens quebrados) virou teste permanente: 100% do conteúdo real."""
    by_territory: dict[str, list[dict]] = {}
    for item in seed.CHALLENGES:
        if item["territory_id"] in config.IDIOMA_TERRITORY_IDS and " " not in item["correct_answer"].strip():
            by_territory.setdefault(item["territory_id"], []).append(item)
    assert by_territory, "nenhum desafio de Idiomas de uma palavra encontrado"
    for territory, items in by_territory.items():
        for item in items:
            assert services.extract_portuguese_meaning(item["prompt"]) is not None, item["prompt"]
        words = {i["correct_answer"].strip().lower() for i in items}
        assert len(words) >= 4, f"{territory}: menos de 4 palavras distintas — a Constelação ficaria degenerada"
