from app.scoring import xp_awarded, hint_penalty_factor


def test_hint_penalty_factor_matches_api_contract_table():
    # Tabela de referência travada em API_CONTRACT.md §4
    assert hint_penalty_factor(0) == 1.0
    assert hint_penalty_factor(1) == 0.75
    assert hint_penalty_factor(2) == 0.50
    assert hint_penalty_factor(3) == 0.25
    assert hint_penalty_factor(4) == 0.0
    assert hint_penalty_factor(10) == 0.0  # piso em 0, nunca negativo


def test_xp_awarded_examples_from_api_contract():
    assert xp_awarded(20, 0) == 20
    assert xp_awarded(20, 1) == 15
    assert xp_awarded(20, 2) == 10
    assert xp_awarded(20, 3) == 5
    assert xp_awarded(20, 4) == 0
