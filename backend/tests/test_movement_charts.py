"""
MOVIMENTO_GRAFICOS_RICOS_V1.md — sessões de 4h do dia (com frase
descritiva dinâmica e destaque de pico), granularidade diária dentro do
mês, e histórico paginado com acumulado. Mesmo padrão de
test_movement.py: chama /movement/collect com `movement.utcnow`
monkeypatched pra controlar em que ponto do dia/mês cada coleta cai.
"""

import uuid
from datetime import timedelta

from app import config, models, movement
from app.db import SessionLocal
from app.timeutil import utcnow

from .conftest import auth_header


def _enable_movement(client, headers) -> None:
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    client.post("/movement/enable", headers=headers)


def test_daily_chart_distributes_steps_into_6_sessions_and_flags_peak(client, monkeypatch):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    _enable_movement(client, headers)

    cycle_start, _ = movement._cycle_window_for(utcnow())

    # Sessão 0 (00h-04h): 1.000 passos às 01h.
    monkeypatch.setattr(movement, "utcnow", lambda: cycle_start + timedelta(hours=1))
    client.post("/movement/collect", json={"steps": 1000}, headers=headers)

    # Sessão 2 (08h-12h): +5.000 passos às 09h — vira o pico do dia.
    monkeypatch.setattr(movement, "utcnow", lambda: cycle_start + timedelta(hours=9))
    client.post("/movement/collect", json={"steps": 5000}, headers=headers)

    # Sessão 5 (20h-24h): +200 passos às 21h.
    monkeypatch.setattr(movement, "utcnow", lambda: cycle_start + timedelta(hours=21))
    client.post("/movement/collect", json={"steps": 200}, headers=headers)

    resp = client.get("/movement/daily-chart", headers=headers)
    assert resp.status_code == 200
    sessions = resp.json()["sessions"]

    assert len(sessions) == 6
    assert [s["label"] for s in sessions] == [
        "Madrugada", "Início da manhã", "Fim da manhã",
        "Início da tarde", "Fim da tarde", "Noite",
    ]
    assert sessions[0]["steps"] == 1000
    assert sessions[1]["steps"] == 0
    assert sessions[2]["steps"] == 5000
    assert sessions[5]["steps"] == 200

    assert sessions[2]["is_peak"] is True
    assert all(not s["is_peak"] for i, s in enumerate(sessions) if i != 2)
    assert "Pico do dia" in sessions[2]["description"]
    # Sessões zeradas descrevem inatividade — nunca um texto genérico
    # desacoplado do dado real.
    assert "parado" in sessions[1]["description"].lower()


def test_daily_chart_with_no_activity_yet_has_no_peak_and_neutral_description(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    _enable_movement(client, headers)

    sessions = client.get("/movement/daily-chart", headers=headers).json()["sessions"]
    assert all(s["steps"] == 0 for s in sessions)
    assert all(not s["is_peak"] for s in sessions)
    assert all("ainda" in s["description"].lower() or "nenhum" in s["description"].lower() for s in sessions)


def test_monthly_chart_aggregates_per_day_and_flags_best_day(client, monkeypatch):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    _enable_movement(client, headers)

    cycle_start, _ = movement._cycle_window_for(utcnow())

    # Dia corrente: 2.000 passos.
    monkeypatch.setattr(movement, "utcnow", lambda: cycle_start + timedelta(hours=2))
    client.post("/movement/collect", json={"steps": 2000}, headers=headers)

    # Dia anterior (mesmo mês, quase certo — só falha nos primeiros dias
    # do mês, aceitável pro nível de rigor deste teste): 9.000 passos,
    # vira o melhor dia.
    yesterday_start = cycle_start - timedelta(days=1)
    monkeypatch.setattr(movement, "utcnow", lambda: yesterday_start + timedelta(hours=2))
    client.post("/movement/collect", json={"steps": 9000}, headers=headers)

    now_brazil = utcnow().replace(tzinfo=None)
    resp = client.get(
        "/movement/monthly-chart",
        params={"year": cycle_start.year, "month": cycle_start.month},
        headers=headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["total_steps"] == 11000
    assert data["active_days"] == 2
    by_day = {d["day"]: d for d in data["days"]}
    assert by_day[cycle_start.day]["steps"] == 2000
    assert by_day[yesterday_start.day]["steps"] == 9000
    assert by_day[yesterday_start.day]["is_best"] is True
    assert by_day[cycle_start.day]["is_best"] is False


def test_history_page_has_sequential_day_number_and_running_cumulative(client, monkeypatch):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    _enable_movement(client, headers)

    cycle_start, _ = movement._cycle_window_for(utcnow())

    monkeypatch.setattr(movement, "utcnow", lambda: cycle_start - timedelta(days=1, hours=-2))
    client.post("/movement/collect", json={"steps": 1000}, headers=headers)

    monkeypatch.setattr(movement, "utcnow", lambda: cycle_start + timedelta(hours=2))
    client.post("/movement/collect", json={"steps": 500}, headers=headers)

    resp = client.get("/movement/history", headers=headers)
    assert resp.status_code == 200
    items = resp.json()["items"]

    # Mais recente primeiro.
    assert items[0]["steps"] == 500
    assert items[0]["cumulative_steps"] == 1500
    assert items[1]["steps"] == 1000
    assert items[1]["cumulative_steps"] == 1000
    # Numeração sequencial cresce com o tempo — dia mais antigo tem
    # day_number menor.
    assert items[1]["day_number"] < items[0]["day_number"]


def test_history_page_respects_daily_goal_for_goal_reached_flag(client, monkeypatch):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    _enable_movement(client, headers)
    client.put("/movement/goal", json={"daily_goal_steps": config.MOVEMENT_MIN_DAILY_GOAL_STEPS}, headers=headers)

    monkeypatch.setattr(movement, "utcnow", lambda: movement._cycle_window_for(utcnow())[0] + timedelta(hours=1))
    client.post("/movement/collect", json={"steps": config.MOVEMENT_MIN_DAILY_GOAL_STEPS}, headers=headers)

    items = client.get("/movement/history", headers=headers).json()["items"]
    assert items[0]["goal_reached"] is True


def test_yearly_summary_flags_best_month(client, monkeypatch):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    _enable_movement(client, headers)

    monkeypatch.setattr(movement, "utcnow", lambda: movement._cycle_window_for(utcnow())[0] + timedelta(hours=1))
    client.post("/movement/collect", json={"steps": 3000}, headers=headers)

    data = client.get("/movement/yearly-summary", headers=headers).json()
    months = {m["month"]: m for m in data["months"]}
    current_month = movement._cycle_window_for(utcnow())[0].month
    assert months[current_month]["is_best"] is True
