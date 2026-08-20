"""
Fórmula de penalidade de dica — fonte de verdade travada em
docs/00_DISCOVERY/RISKS_AND_OPEN_DECISIONS.md §1 e
docs/01_FOUNDATION/API_CONTRACT.md §4. Qualquer divergência entre este
código e aqueles documentos é bug, não interpretação válida.
"""

from . import config


def hint_penalty_factor(hints_used: int) -> float:
    return max(0.0, 1.0 - config.HINT_PENALTY_FACTOR * hints_used)


def xp_awarded(xp_base: int, hints_used: int) -> int:
    return round(xp_base * hint_penalty_factor(hints_used))


def xp_base_for(difficulty_level: int) -> int:
    return config.XP_BASE_BY_DIFFICULTY.get(difficulty_level, config.XP_BASE_DEFAULT)


def level_from_xp(xp_total: int) -> int:
    # Nível sobe a cada config.XP_PER_LEVEL de XP acumulado — decisão
    # tomada no Vertical Slice 01 (GAMIFICATION.md deixava a fórmula em
    # aberto), simples e linear de propósito para o V1; pode ser revisada
    # com dado real de uso. Valor centralizado em config.py, não aqui.
    return 1 + xp_total // config.XP_PER_LEVEL
