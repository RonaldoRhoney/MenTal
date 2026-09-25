"""
My_Mental_AI — agente do usuário (pedido de Rhoney, 21/09/2026): dicas,
considerações e recomendações personalizadas a partir do DESEMPENHO DO PRÓPRIO
USUÁRIO (onde vai melhor, onde focar, o que falta para conquistar territórios e
completar Mundos, ranking, XP, sequência, economia de moedas).

Regras de desenho:
- CUSTO ZERO (regra do projeto): é análise por REGRAS sobre dados que já existem
  no banco — nenhuma API de IA generativa/paga. O app chama de "análise do seu
  desempenho", sem prometer IA generativa.
- Só dados do próprio usuário. Do ranking sai apenas um número (a diferença de XP
  para o próximo colocado), nunca a identidade de outra pessoa.
- Só o servidor decide o que recomendar; o client só exibe e navega.
- Textos em português; {territory} é resolvido pelo client (o nome do território
  vive no l10n do app).
"""

from datetime import timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from . import config, economy, models, services
from .timeutil import brasilia_today, naive, utcnow

MIN_ATTEMPTS_FOR_ACCURACY = 10
STREAK_MILESTONES = sorted(config.STREAK_MILESTONE_REWARDS)


def _card(card_id: str, priority: int, title: str, body: str, action: dict | None = None, territory_id: str | None = None) -> dict:
    return {"id": card_id, "priority": priority, "title": title, "body": body, "action": action, "territory_id": territory_id}


def _territory_stats(db: Session, user_id: str) -> dict[str, dict]:
    """Respostas por território (uma consulta só): total, acertos, dicas."""
    stats: dict[str, dict] = {}
    attempts = db.execute(
        select(models.Challenge.territory_id, models.Attempt.is_correct, models.Attempt.hints_used, models.Attempt.created_at)
        .join(models.Attempt, models.Attempt.challenge_id == models.Challenge.id)
        .where(models.Attempt.user_id == user_id)
        .where(models.Attempt.is_correct.is_not(None))
        .where(models.Attempt.is_review.is_(False))
    ).all()
    for territory_id, is_correct, hints, created_at in attempts:
        s = stats.setdefault(territory_id, {"total": 0, "correct": 0, "hints": 0, "last": None})
        created_at = naive(created_at)
        if created_at is not None and (s["last"] is None or created_at > s["last"]):
            s["last"] = created_at
        s["total"] += 1
        s["correct"] += 1 if is_correct else 0
        s["hints"] += hints or 0
    return stats


def _weekly_rank(db: Session, user_id: str, since) -> tuple[int | None, int, int | None]:
    """(posição, meu XP na semana, XP que falta para ultrapassar o próximo). Só números."""
    sums = (
        select(models.Attempt.user_id.label("uid"), func.sum(models.Attempt.xp_awarded).label("xp"))
        .where(models.Attempt.created_at >= since)
        .where(models.Attempt.is_correct.is_(True))
        .group_by(models.Attempt.user_id)
        .subquery()
    )
    mine = db.execute(select(sums.c.xp).where(sums.c.uid == user_id)).scalar_one_or_none() or 0
    if mine <= 0:
        return None, 0, None
    ahead = db.execute(select(func.count()).select_from(sums).where(sums.c.xp > mine)).scalar_one()
    next_xp = db.execute(select(func.min(sums.c.xp)).where(sums.c.xp > mine)).scalar_one_or_none()
    return ahead + 1, int(mine), (int(next_xp) - int(mine) + 1 if next_xp is not None else None)


def build_world_coach_tip(db: Session, user_id: str, world_id: str) -> dict | None:
    """
    My_Mental_AI DENTRO de cada Mundo (pedido de Rhoney, 23/09/2026): a
    dica genérica saiu da Home (ficava "muito poluída") e virou UMA dica
    focada no desempenho do usuário NAQUELE Mundo, mostrada dentro dele
    (_WorldDetailScreen no client). Mundo dos Idiomas fica de fora —
    ganhará agente próprio ("Mental Lingo", ainda não implementado); o
    client não chama este endpoint pra ele, e não há nada especial a
    fazer aqui além de retornar None se o Mundo não existir/não tiver
    território (mesma decisão de nunca inferir automaticamente).

    Retorna no máximo UM cartão (não uma lista) — diferente de
    build_coach (Home antiga tinha um "painel"; aqui é só um card
    pequeno dentro da tela do Mundo).
    """
    world = db.get(models.World, world_id)
    if world is None:
        return None
    territory_ids = set(
        db.execute(select(models.Territory.id).where(models.Territory.world_id == world_id)).scalars().all()
    )
    if not territory_ids:
        return None

    stats = {tid: s for tid, s in _territory_stats(db, user_id).items() if tid in territory_ids}
    progress = {
        p.territory_id: p
        for p in db.execute(
            select(models.UserTerritoryProgress)
            .where(models.UserTerritoryProgress.user_id == user_id)
            .where(models.UserTerritoryProgress.territory_id.in_(territory_ids))
        ).scalars().all()
    }
    total_attempts = sum(s["total"] for s in stats.values())
    threshold = config.CONQUEST_XP_THRESHOLD
    conquered = {tid for tid, p in progress.items() if p.conquered_at is not None}

    # Fatos reais do desempenho neste Mundo (sempre exibidos no corpo da dica).
    total_correct = sum(s["correct"] for s in stats.values())
    total_hints = sum(s["hints"] for s in stats.values())
    hint_rate = total_hints / total_attempts if total_attempts else 0.0
    accuracy_pct = int(round(total_correct / total_attempts * 100)) if total_attempts else 0
    facts = f"Neste Mundo: {total_attempts} respostas, {total_correct} certas ({accuracy_pct}%)."
    last_dates = [s["last"] for s in stats.values() if s["last"] is not None]
    # naive(): timestamptz volta aware do Postgres (ver timeutil.naive)
    days_idle = (utcnow() - naive(max(last_dates))).days if last_dates else None
    rated = [(s["correct"] / s["total"], tid, s["total"], s["correct"]) for tid, s in stats.items() if s["total"] >= MIN_ATTEMPTS_FOR_ACCURACY]
    never_played = [tid for tid in sorted(territory_ids) if tid not in stats]
    missing = len(territory_ids) - len(conquered)

    # 1) Território perto de ser conquistado (números reais de XP)
    near = [(p.xp_in_territory, tid) for tid, p in progress.items() if p.conquered_at is None and p.xp_in_territory >= 0.6 * threshold]
    if near:
        xp, tid = max(near)
        return _card("world_close_to_conquest", 90, "Falta pouco para conquistar",
                     f"{facts} Você tem {xp} de {threshold} XP em {{territory}}; faltam {threshold - xp} XP para conquistar.",
                     {"type": "territory", "territory_id": tid}, tid)

    # 2) Território mais fraco (taxa real < 60%, com amostra mínima)
    if rated:
        low = min(rated)
        if low[0] < 0.6:
            tip = " Você usa dica em boa parte das respostas — tente responder antes de pedir dica." if hint_rate >= 0.5 else ""
            return _card("world_weakest", 85, "Ponto fraco neste Mundo",
                         f"{facts} Seu pior território é {{territory}}: {low[3]} certas em {low[2]} respostas ({int(low[0] * 100)}%).{tip}",
                         {"type": "territory", "territory_id": low[1]}, low[1])

    # 3) Dependência de dicas (cada dica reduz o XP)
    if total_attempts >= MIN_ATTEMPTS_FOR_ACCURACY and hint_rate >= 0.8:
        return _card("world_hints", 78, "Muitas dicas usadas",
                     f"{facts} Você usou {total_hints} dicas em {total_attempts} respostas. Cada dica reduz o XP ganho.", None)

    # 4) Território que você nunca respondeu
    if never_played and total_attempts > 0:
        return _card("world_unexplored", 74, "Território ainda não jogado",
                     f"{facts} Você ainda não respondeu nada em {{territory}}.",
                     {"type": "territory", "territory_id": never_played[0]}, never_played[0])

    # 5) Progresso do Mundo (faltam N territórios)
    if missing > 0 and conquered:
        pick = max((tid for tid in territory_ids if tid not in conquered), key=lambda t: progress[t].xp_in_territory if t in progress else 0)
        pct = int(len(conquered) / len(territory_ids) * 100)
        return _card("world_progress", 72, f"{world.name}: {pct}% conquistado",
                     f"{facts} Faltam {missing} território(s) para completar (bônus de {config.WORLD_COMPLETION_BONUS_XP} XP e distintivo). Maior avanço entre os faltantes: {{territory}}.",
                     {"type": "territory", "territory_id": pick}, pick)

    # 6) Parado há muito tempo
    if days_idle is not None and days_idle >= 14:
        return _card("world_idle", 66, "Faz tempo que você não joga aqui",
                     f"{facts} Sua última resposta neste Mundo foi há {days_idle} dias.", None)

    # 7) Território mais forte
    if rated:
        high = max(rated)
        if high[0] >= 0.75:
            return _card("world_strongest", 60, "Seu melhor território",
                         f"{facts} Em {{territory}} você acertou {high[3]} de {high[2]} ({int(high[0] * 100)}%). O Relâmpago aí rende XP extra a quem acerta rápido.",
                         {"type": "territory", "territory_id": high[1], "relampago": True}, high[1])

    # 8) Mundo já 100% conquistado
    if missing == 0 and conquered:
        return _card("world_completed", 50, f"{world.name} completo",
                     f"{facts} Todos os territórios estão conquistados; refazê-los só serve para reforçar.", None)

    # 9) Sem dado suficiente — diz isso, sem inventar diagnóstico
    if total_attempts == 0:
        return _card("world_newcomer", 45, f"Sem dados em {world.name}",
                     "Você ainda não respondeu nada aqui, então não há análise possível. Com 10 respostas em um território já dá para medir sua taxa de acerto.", None)
    return _card("world_generic", 40, "Dados ainda insuficientes",
                 f"{facts} Nenhum território tem as {MIN_ATTEMPTS_FOR_ACCURACY} respostas mínimas para apontar ponto forte ou fraco.", None)


def build_coach(db: Session, user_id: str) -> dict:
    profile = services.get_or_create_profile(db, user_id)
    streak = services.get_or_create_streak(db, user_id)
    now = utcnow()
    today = now.date()
    cards: list[dict] = []

    stats = _territory_stats(db, user_id)
    total_attempts = sum(s["total"] for s in stats.values())
    total_correct = sum(s["correct"] for s in stats.values())
    total_hints = sum(s["hints"] for s in stats.values())
    progress = {
        p.territory_id: p
        for p in db.execute(select(models.UserTerritoryProgress).where(models.UserTerritoryProgress.user_id == user_id)).scalars().all()
    }
    territories = db.execute(select(models.Territory)).scalars().all()

    # 1) Reparo de sequência (urgente: janela curta)
    offer = economy.streak_repair_offer(streak, today)
    if offer is not None:
        balance = db.get(models.MentalCoinsBalance, user_id)
        coins = balance.balance if balance else 0
        cards.append(
            _card(
                "streak_repair", 100, "Sua sequência pode ser recuperada",
                f"Sua sequência de {offer.streak_to_restore} dias quebrou. Você pode repará-la por {config.STREAK_REPAIR_COST} MentalCoins até {offer.expires_on.strftime('%d/%m')}"
                + ("." if coins >= config.STREAK_REPAIR_COST else f" — mas você tem {coins} moedas.")
                , {"type": "mentalcoins"},
            )
        )

    # 2) Teto diário de XP
    earned = economy.daily_answer_xp_earned(db, user_id, brasilia_today())
    cap = config.DAILY_ANSWER_XP_CAP
    if earned >= cap:
        cards.append(_card("daily_cap", 92, "Você bateu o teto de XP de hoje",
                           f"Você já ganhou {cap} XP de resposta hoje. Seu progresso nos territórios continua contando; o XP de perfil volta amanhã. Hoje, o Movimento (passos) e as Batalhas ainda rendem.",
                           {"type": "movement"}))
    elif earned >= 0.8 * cap:
        cards.append(_card("daily_cap", 88, "Perto do teto de XP de hoje",
                           f"Você já fez {earned} de {cap} XP de resposta hoje. Depois disso o XP de perfil para até amanhã (o progresso nos territórios continua).", None))

    # 3) Território perto de ser conquistado
    threshold = config.CONQUEST_XP_THRESHOLD
    near = [
        (p.xp_in_territory, tid) for tid, p in progress.items() if p.conquered_at is None and p.xp_in_territory >= 0.6 * threshold
    ]
    if near:
        xp, tid = max(near)
        cards.append(_card("close_to_conquest", 82, "Falta pouco para conquistar",
                           f"Você tem {xp} de {threshold} XP em {{territory}}. Faltam {threshold - xp} XP para conquistar.",
                           {"type": "territory", "territory_id": tid}, tid))

    # 4) Mundo mais perto de ser completado
    conquered = {tid for tid, p in progress.items() if p.conquered_at is not None}
    best_world = None
    for world in db.execute(select(models.World)).scalars().all():
        tids = [t.id for t in territories if t.world_id == world.id]
        if not tids:
            continue
        done = len([t for t in tids if t in conquered])
        missing = len(tids) - done
        if missing == 0 or done == 0:
            continue
        ratio = done / len(tids)
        if best_world is None or ratio > best_world[0]:
            best_world = (ratio, world, missing, [t for t in tids if t not in conquered])
    if best_world and best_world[0] >= 0.3:
        ratio, world, missing, remaining = best_world
        pick = max(remaining, key=lambda t: progress[t].xp_in_territory if t in progress else 0)
        cards.append(_card("world_closest", 76, f"{world.name}: {int(ratio * 100)}% conquistado",
                           f"Faltam {missing} território(s) para completar o {world.name} (bônus de {config.WORLD_COMPLETION_BONUS_XP} XP e distintivo). Um bom próximo passo: {{territory}}.",
                           {"type": "territory", "territory_id": pick}, pick))

    # 5) Onde reforçar / onde vai melhor (números reais; dica de "usar dicas" só se os dados mostram uso alto)
    rated = [(s["correct"] / s["total"], tid, s["total"], s["correct"], s["hints"]) for tid, s in stats.items() if s["total"] >= MIN_ATTEMPTS_FOR_ACCURACY]
    if rated:
        low = min(rated)
        if low[0] < 0.6:
            tip = " Você usa dica em boa parte das respostas — tente responder antes de pedir dica." if low[4] / low[2] >= 0.5 else ""
            cards.append(_card("weakest", 72, "Seu ponto mais fraco",
                               f"Em {{territory}} você acertou {low[3]} de {low[2]} respostas ({int(low[0] * 100)}%).{tip}",
                               {"type": "territory", "territory_id": low[1]}, low[1]))
        high = max(rated)
        if high[0] >= 0.75 and high[1] != low[1]:
            cards.append(_card("strongest", 52, "Onde você vai melhor",
                               f"Em {{territory}} você acertou {high[3]} de {high[2]} respostas ({int(high[0] * 100)}%). O Relâmpago aí rende XP extra a quem acerta rápido.",
                               {"type": "territory", "territory_id": high[1], "relampago": True}, high[1]))

    # 6) Ranking semanal
    rank, weekly_xp, gap = _weekly_rank(db, user_id, now - timedelta(days=7))
    if rank is not None:
        if rank == 1:
            body = f"Você lidera a semana com {weekly_xp} XP. Mantenha o ritmo para continuar no topo."
        elif gap is not None:
            body = f"Você está em #{rank} na semana ({weekly_xp} XP). Faltam {gap} XP para ultrapassar quem está à frente."
        else:
            body = f"Você está em #{rank} na semana ({weekly_xp} XP)."
        cards.append(_card("ranking", 66, "Seu ranking da semana", body, {"type": "ranking"}))

    # 7) Sequência
    if streak.current_streak > 0:
        nxt = next((m for m in STREAK_MILESTONES if m > streak.current_streak), None)
        if nxt:
            kind, value = config.STREAK_MILESTONE_REWARDS[nxt]
            reward = f"{value} XP" if kind == "xp" else f"{value} MentalCoins"
            cards.append(_card("streak", 60, f"Sequência de {streak.current_streak} dias",
                               f"Faltam {nxt - streak.current_streak} dia(s) para o marco de {nxt} dias (+{reward}). Jogue todo dia, mesmo que pouco.", None))
    else:
        cards.append(_card("streak", 58, "Comece sua sequência hoje",
                           "Responder ao menos um desafio por dia forma sua sequência e desbloqueia bônus nos marcos de 7, 15, 30 e 100 dias.", None))

    # 8) Boost
    if economy.active_boost_expiry(db, user_id, now) is None:
        balance = db.get(models.MentalCoinsBalance, user_id)
        coins = balance.balance if balance else 0
        week_xp = weekly_xp
        if coins >= config.XP_BOOST_COST and week_xp >= 7 * 20 and earned < 0.5 * cap:
            cards.append(_card("boost", 46, "Vale ativar o boost de XP",
                               f"Você joga com regularidade e tem {coins} MentalCoins. O boost de +{config.XP_BOOST_PERCENT}% custa {config.XP_BOOST_COST} e dura 24h — use num dia em que for jogar bastante (o teto de {cap} XP continua valendo).",
                               {"type": "mentalcoins"}))

    # 9) Dicas
    if total_correct >= 10 and total_hints / max(total_attempts, 1) >= 0.8:
        cards.append(_card("hints", 42, "Use menos dicas",
                           "Você usa muitas dicas por resposta. Cada dica reduz o XP ganho: tente responder primeiro e peça dica só se travar.", None))

    # 10) O que você ainda não explorou
    friends = len(services.get_friend_user_ids(db, user_id))
    if not profile.movement_enabled:
        cards.append(_card("explore_movement", 34, "Ative o Movimento",
                           "Seus passos viram XP e MentalCoins todo dia, sem precisar responder nada — bom para os dias em que o teto de XP já foi atingido.",
                           {"type": "movement"}))
    elif friends == 0:
        cards.append(_card("explore_friends", 33, "Jogue com amigos",
                           "Adicione amigos para desafiá-los em Batalhas, mandar Torcida e subir juntos no ranking entre amigos.", {"type": "friends"}))

    # 11) Boas-vindas / como usar melhor (sempre presente)
    if total_attempts < 10:
        cards.append(_card("newcomer", 70, "Bem-vindo ao My_Mental_AI",
                           "Responda alguns desafios em territórios diferentes: com 10 respostas em cada um eu consigo dizer onde você vai melhor e onde vale reforçar.", None))
    cards.append(_card("how_to", 10, "Como aproveitar melhor o app",
                       "1) Jogue um pouco todo dia (sequência rende bônus). 2) Depois de errar, leia a explicação: é assim que se fixa. 3) Use o Relâmpago nos temas em que você já vai bem. 4) Nos idiomas, ouça as palavras. 5) Complete os territórios de um Mundo para ganhar o bônus de Mundo.", None))

    cards.sort(key=lambda c: -c["priority"])
    return {
        "name": "My_Mental_AI",
        "summary": {
            "total_answers": total_attempts,
            "accuracy": (total_correct / total_attempts) if total_attempts else 0.0,
            "weekly_xp": weekly_xp,
            "weekly_rank": rank,
            "streak": streak.current_streak,
            "daily_xp": earned,
            "daily_xp_cap": cap,
        },
        "daily_tip": cards[0] if cards else None,
        "cards": cards[:9],
    }
