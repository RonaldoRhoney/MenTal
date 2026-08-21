"""
V2 item 7 — Conteúdo educacional avançado (V2_KICKOFF.md §6A). Critério
de fechamento definido antecipadamente (não é mais tarefa contínua sem
fim): cada território ativo precisa de no mínimo 15 desafios, com pelo
menos 4 por nível de dificuldade (1-3). Este teste trava esse piso como
regra permanente — qualquer mudança futura no seed que reduza o volume
de algum território abaixo do critério quebra a suíte, não só uma
observação manual.
"""

from collections import Counter

from app.seed import CHALLENGES, TERRITORIES

MIN_CHALLENGES_PER_TERRITORY = 15
MIN_PER_DIFFICULTY_LEVEL = 4
REQUIRED_DIFFICULTY_LEVELS = (1, 2, 3)


def test_every_active_territory_meets_the_v2_item7_closing_criterion():
    territory_ids = [t["id"] for t in TERRITORIES]
    assert territory_ids, "seed sem território algum — algo está muito errado"

    by_territory = {tid: [] for tid in territory_ids}
    for challenge in CHALLENGES:
        by_territory.setdefault(challenge["territory_id"], []).append(challenge["difficulty_level"])

    failures = []
    for territory_id in territory_ids:
        levels = by_territory[territory_id]
        counts = Counter(levels)
        total = len(levels)

        if total < MIN_CHALLENGES_PER_TERRITORY:
            failures.append(f"{territory_id}: total={total} (mínimo {MIN_CHALLENGES_PER_TERRITORY})")

        for level in REQUIRED_DIFFICULTY_LEVELS:
            if counts.get(level, 0) < MIN_PER_DIFFICULTY_LEVEL:
                failures.append(
                    f"{territory_id} nível {level}: {counts.get(level, 0)} itens (mínimo {MIN_PER_DIFFICULTY_LEVEL})"
                )

    assert not failures, "Território(s) abaixo do critério de fechamento do item 7:\n" + "\n".join(failures)


def test_no_duplicate_prompts_within_text_based_territories():
    # "visual" reaproveita um pequeno conjunto de frases de propósito (o
    # desafio de verdade está nos ícones/cores, não no texto — decisão
    # registrada no item 4) — excluído desta checagem. Todos os outros
    # territórios são baseados em texto puro: prompt duplicado ali é sinal
    # real de curadoria descuidada (item quase copiado sem querer), não
    # um padrão intencional.
    text_based = [c for c in CHALLENGES if c["territory_id"] != "visual"]
    prompts = [c["prompt"] for c in text_based]
    counts = Counter(prompts)
    duplicates = {p: n for p, n in counts.items() if n > 1}
    assert not duplicates, f"Prompts duplicados em território baseado em texto: {duplicates}"


def test_every_challenge_has_valid_answer_and_two_hints():
    for challenge in CHALLENGES:
        if challenge["options"] is not None:
            assert challenge["correct_answer"] in challenge["options"], (
                f"correct_answer fora de options: {challenge['prompt'][:60]}"
            )
        assert len(challenge["hints"]) == 2, f"esperado 2 dicas: {challenge['prompt'][:60]}"
