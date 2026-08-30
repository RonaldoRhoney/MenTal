"""
Gera grades de Caça-palavras a partir de listas de palavras curadas
(V3.3 §6, Jogos de Palavras — Fase 1). Nunca roda em runtime: a grade
é gerada UMA VEZ aqui, validada (scripts/validate_content.py equivalente
pra este formato é content_validation.validate_word_puzzles) e só então
carregada no banco — mesmo espírito determinístico/auditável de todo
conteúdo do MENTAL, mesmo sendo "gerado" em vez de "escrito à mão".

Entrada: backend/content/<nome>.json no formato:
[
  {"tema": "Animais", "grade_recomendada": "8x8", "palavras": ["GATO", ...]}
]

Saída: backend/content/<nome>_grades.json no schema real de WordPuzzle
(territory_id, difficulty_level, theme, grid_size, grid, words,
age_reviewed=false — curador confirma depois de revisar a grade gerada).

Uso:
    cd backend && python3 scripts/generate_word_search.py content/<nome>.json content/<nome>_grades.json <territory_id>
"""

import json
import random
import sys

DIRECTIONS = [(0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)]
ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

# Grade maior = dificuldade maior — mesma decisão já aprovada (8x8/10x10/
# 12x12 mapeando pra difficulty_level 1/2/3).
GRID_SIZE_TO_DIFFICULTY = {8: 1, 10: 2, 12: 3}


def _place_word(grid: list[list[str]], word: str, size: int, rng: random.Random) -> bool:
    positions = [(r, c) for r in range(size) for c in range(size)]
    rng.shuffle(positions)
    directions = list(DIRECTIONS)
    rng.shuffle(directions)

    for row, col in positions:
        for d_row, d_col in directions:
            end_row = row + d_row * (len(word) - 1)
            end_col = col + d_col * (len(word) - 1)
            if not (0 <= end_row < size and 0 <= end_col < size):
                continue
            cells = [(row + d_row * i, col + d_col * i) for i in range(len(word))]
            if all(grid[r][c] in (None, word[i]) for i, (r, c) in enumerate(cells)):
                for i, (r, c) in enumerate(cells):
                    grid[r][c] = word[i]
                return True
    return False


def _try_generate_grid(words: list[str], size: int, rng: random.Random) -> list[list[str | None]] | None:
    # Palavras mais longas primeiro — mais fácil de encaixar antes da
    # grade ficar cheia (achado real: ordem aleatória falhava a colocar
    # palavras longas em grades pequenas com mais frequência).
    ordered = sorted(words, key=len, reverse=True)
    grid: list[list[str | None]] = [[None] * size for _ in range(size)]

    for word in ordered:
        if not _place_word(grid, word, size, rng):
            return None
    return grid


def generate_grid(words: list[str], size: int, seed: int | None = None, max_attempts: int = 500) -> list[str]:
    for word in words:
        if len(word) > size:
            raise ValueError(f"Palavra {word!r} ({len(word)} letras) não cabe numa grade {size}x{size}")

    # Encaixe guloso sem backtracking: a ORDEM/posição em que as palavras
    # caem importa, e uma combinação de várias palavras do tamanho exato
    # da grade pode genuinamente não caber numa tentativa específica,
    # mesmo cabendo geometricamente (achado real gerando "Profissões":
    # 4 palavras de 10 letras numa grade 10x10 — a primeira tentativa
    # falhou, a 2ª coube). Tenta várias sementes antes de desistir, em
    # vez de reportar erro numa única tentativa de sorte ruim.
    base_seed = seed if seed is not None else random.randrange(2**31)
    for attempt in range(max_attempts):
        rng = random.Random(base_seed + attempt)
        grid = _try_generate_grid(words, size, rng)
        if grid is not None:
            for r in range(size):
                for c in range(size):
                    if grid[r][c] is None:
                        grid[r][c] = rng.choice(ALPHABET)
            return ["".join(row) for row in grid]

    raise ValueError(f"Não foi possível encaixar todas as palavras na grade {size}x{size} depois de {max_attempts} tentativas — tente uma grade maior")


def main() -> None:
    if len(sys.argv) != 4:
        print("Uso: python3 scripts/generate_word_search.py content/<entrada>.json content/<saida>.json <territory_id>")
        sys.exit(1)

    input_path, output_path, territory_id = sys.argv[1], sys.argv[2], sys.argv[3]
    with open(input_path, encoding="utf-8") as f:
        data = json.load(f)

    grid_sizes_ascending = sorted(GRID_SIZE_TO_DIFFICULTY)
    puzzles = []
    for tema in data["temas"]:
        size = int(tema["grade_recomendada"].split("x")[0])
        if size not in GRID_SIZE_TO_DIFFICULTY:
            print(f"❌ grade_recomendada {tema['grade_recomendada']!r} não mapeia pra nenhuma dificuldade conhecida ({GRID_SIZE_TO_DIFFICULTY})")
            sys.exit(1)

        words = [w.upper() for w in tema["palavras"]]
        # A soma do comprimento das palavras pode não caber na grade
        # recomendada mesmo geometricamente (achado real gerando este
        # lote: "Profissões" tinha 103 letras pra 100 células de uma
        # grade 10x10) — sobe pro próximo tamanho conhecido em vez de
        # falhar, avisando a mudança pra quem curou decidir se aceita ou
        # prefere cortar palavras da lista.
        candidate_sizes = [s for s in grid_sizes_ascending if s >= size]
        grid = None
        used_size = size
        for candidate_size in candidate_sizes:
            try:
                grid = generate_grid(words, candidate_size)
                used_size = candidate_size
                break
            except ValueError:
                continue
        if grid is None:
            print(f"❌ tema {tema['tema']!r}: não coube nem na maior grade disponível ({candidate_sizes[-1]}x{candidate_sizes[-1]}) — reduza a lista de palavras")
            sys.exit(1)
        if used_size != size:
            print(f"⚠️  tema {tema['tema']!r}: grade recomendada {size}x{size} era pequena demais para a lista — usada {used_size}x{used_size}")

        difficulty_level = GRID_SIZE_TO_DIFFICULTY[used_size]
        size = used_size

        puzzles.append(
            {
                "territory_id": territory_id,
                "difficulty_level": difficulty_level,
                "theme": tema["tema"],
                "grid_size": size,
                "grid": grid,
                "words": words,
                "age_reviewed": False,
            }
        )

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(puzzles, f, ensure_ascii=False, indent=2)

    print(f"✅ {len(puzzles)} grade(s) gerada(s) em {output_path}")


if __name__ == "__main__":
    main()
