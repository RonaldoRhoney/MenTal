"""
Validação de conteúdo curado (backend/content/README.md). Só valida
ESTRUTURA (campos presentes, tipos, consistência interna) — nunca julga
se o conteúdo em si é factualmente correto ou apropriado, isso é
responsabilidade de quem curou (RISKS_AND_OPEN_DECISIONS.md §2:
conteúdo curado manualmente, nunca gerado/validado por IA).
"""

REQUIRED_FIELDS = {"territory_id", "difficulty_level", "prompt", "options", "correct_answer", "explanation", "hints", "age_reviewed"}


def validate_content(items: list[dict], known_territory_ids: set[str], existing_prompts: set[tuple[str, str]]) -> list[str]:
    """
    Retorna a lista de erros encontrados (vazia = tudo certo). Nunca
    lança exceção — quem chama decide o que fazer com os erros (CLI
    imprime e aborta antes de tocar o banco).
    """
    errors: list[str] = []
    seen_in_file: set[tuple[str, str]] = set()

    for idx, item in enumerate(items):
        prefix = f"item {idx} ({item.get('prompt', '<sem prompt>')!r})"

        missing = REQUIRED_FIELDS - item.keys()
        if missing:
            errors.append(f"{prefix}: campos faltando: {sorted(missing)}")
            continue  # sem os campos básicos, não dá pra validar o resto

        territory_id = item["territory_id"]
        if territory_id not in known_territory_ids:
            errors.append(f"{prefix}: territory_id {territory_id!r} não existe (veja app/seed.py TERRITORIES)")

        if item["difficulty_level"] not in (1, 2, 3):
            errors.append(f"{prefix}: difficulty_level precisa ser 1, 2 ou 3 (veio {item['difficulty_level']!r})")

        options = item["options"]
        if not isinstance(options, list) or len(options) != 4:
            errors.append(f"{prefix}: options precisa ter exatamente 4 alternativas (veio {len(options) if isinstance(options, list) else type(options).__name__})")
        elif len(set(options)) != len(options):
            errors.append(f"{prefix}: options tem alternativas repetidas: {options}")
        elif item["correct_answer"] not in options:
            errors.append(f"{prefix}: correct_answer {item['correct_answer']!r} não está em options {options}")

        hints = item["hints"]
        if not isinstance(hints, list) or len(hints) != 2:
            errors.append(f"{prefix}: hints precisa ter exatamente 2 dicas (veio {len(hints) if isinstance(hints, list) else type(hints).__name__})")

        if item["age_reviewed"] is not True:
            errors.append(f"{prefix}: age_reviewed precisa ser true — confirme manualmente que o conteúdo é apropriado pro público misto antes de marcar")

        if not item["prompt"].strip():
            errors.append(f"{prefix}: prompt não pode ser vazio")

        # CONHECIMENTO_CONTEUDO_GERAL_E_IMAGEM.md §3 — opcional, nunca
        # obrigatório. Só valida quando presente (chave pode nem existir
        # no item, diferente dos campos de REQUIRED_FIELDS).
        prompt_image = item.get("prompt_image")
        if prompt_image is not None and not (isinstance(prompt_image, str) and prompt_image.strip()):
            errors.append(f"{prefix}: prompt_image, quando presente, precisa ser uma string não vazia")

        # V4 — Detetive Mental (V4/V4_NOVOS_TERRITORIOS.md §4). Opcional
        # em qualquer outro território (None, mesmo padrão de
        # prompt_image), mas OBRIGATÓRIO em detetive_mental — sem pistas,
        # o desafio vira um MCQ comum e a mecânica do bloco não existe.
        clues = item.get("clues")
        if territory_id == "detetive_mental" and not clues:
            errors.append(f"{prefix}: território 'detetive_mental' precisa do campo 'clues' (2-3 pistas)")
        if clues is not None:
            if not isinstance(clues, list) or not (2 <= len(clues) <= 3) or not all(isinstance(c, str) and c.strip() for c in clues):
                errors.append(f"{prefix}: clues, quando presente, precisa ser uma lista de 2 a 3 strings não vazias")

        # V4 — Ouvido Afiado (V4/V4_NOVOS_TERRITORIOS.md §3). Tudo-ou-
        # nada: audio_url OBRIGATÓRIO em ouvido_afiado (sem áudio não há
        # desafio), e audio_source_name/audio_source_url OBRIGATÓRIOS
        # junto — mesma disciplina de atribuição de fonte já usada em
        # video_url/source_name/source_url na Pausa para Aprender de
        # Libras, aqui tratada como piso mínimo de compliance de
        # licenciamento (nunca embutir áudio sem crédito rastreável).
        audio_url = item.get("audio_url")
        audio_source_name = item.get("audio_source_name")
        audio_source_url = item.get("audio_source_url")
        if territory_id == "ouvido_afiado":
            if not audio_url:
                errors.append(f"{prefix}: território 'ouvido_afiado' precisa do campo 'audio_url'")
            if not audio_source_name or not audio_source_url:
                errors.append(f"{prefix}: território 'ouvido_afiado' precisa de 'audio_source_name' e 'audio_source_url' (atribuição de licença)")
        if audio_url is not None and not (isinstance(audio_url, str) and audio_url.startswith("https://")):
            errors.append(f"{prefix}: audio_url, quando presente, precisa ser uma URL https válida")

        key = (territory_id, item["prompt"])
        if key in existing_prompts:
            errors.append(f"{prefix}: já existe um desafio com esse prompt nesse território (em app/seed.py ou já carregado no banco)")
        if key in seen_in_file:
            errors.append(f"{prefix}: prompt duplicado dentro do próprio arquivo, no mesmo território")
        seen_in_file.add(key)

    return errors


# V3.2 (V3/V3.2_TECNOLOGIA.md §3) — "Pausa para Aprender": estrutura de
# conteúdo NOVA, sem options/correct_answer/hints/timer (é leitura, não
# desafio) — validação própria, formato de arquivo próprio
# (backend/content/README.md §"Pausa para Aprender").
LEARNING_PAUSE_REQUIRED_FIELDS = {"territory_id", "difficulty_level", "text", "age_reviewed"}


def validate_learning_pauses(items: list[dict], known_territory_ids: set[str], existing_texts: set[tuple[str, str]]) -> list[str]:
    """Mesmo contrato de validate_content (nunca lança, retorna lista de erros)."""
    errors: list[str] = []
    seen_in_file: set[tuple[str, str]] = set()

    for idx, item in enumerate(items):
        prefix = f"item {idx} ({item.get('text', '<sem texto>')[:40]!r})"

        missing = LEARNING_PAUSE_REQUIRED_FIELDS - item.keys()
        if missing:
            errors.append(f"{prefix}: campos faltando: {sorted(missing)}")
            continue

        territory_id = item["territory_id"]
        if territory_id not in known_territory_ids:
            errors.append(f"{prefix}: territory_id {territory_id!r} não existe (veja app/seed.py TERRITORIES)")

        if item["difficulty_level"] not in (1, 2, 3):
            errors.append(f"{prefix}: difficulty_level precisa ser 1, 2 ou 3 (veio {item['difficulty_level']!r})")

        if item["age_reviewed"] is not True:
            errors.append(f"{prefix}: age_reviewed precisa ser true — confirme manualmente que o conteúdo é apropriado pro público misto antes de marcar")

        if not item["text"].strip():
            errors.append(f"{prefix}: text não pode ser vazio")

        prompt_image = item.get("prompt_image")
        if prompt_image is not None and not (isinstance(prompt_image, str) and prompt_image.strip()):
            errors.append(f"{prefix}: prompt_image, quando presente, precisa ser uma string não vazia")

        # V3.4 (V3/V3.4_LIBRAS.md §2/§3.2) — vídeo de referência é
        # tudo-ou-nada: se um dos 3 campos vier preenchido, os outros
        # dois também precisam vir (nunca vídeo sem atribuição de fonte,
        # nunca fonte "solta" sem vídeo nem vídeo sem link de origem).
        video_url = item.get("video_url")
        source_name = item.get("source_name")
        source_url = item.get("source_url")
        video_fields = {"video_url": video_url, "source_name": source_name, "source_url": source_url}
        present = {k: v for k, v in video_fields.items() if v is not None and str(v).strip()}
        if present and len(present) != 3:
            missing_video_fields = sorted(set(video_fields) - set(present))
            errors.append(f"{prefix}: vídeo institucional precisa de video_url + source_name + source_url juntos (faltando: {missing_video_fields})")

        key = (territory_id, item["text"])
        if key in existing_texts:
            errors.append(f"{prefix}: já existe uma Pausa para Aprender com esse texto nesse território")
        if key in seen_in_file:
            errors.append(f"{prefix}: texto duplicado dentro do próprio arquivo, no mesmo território")
        seen_in_file.add(key)

    return errors


WORD_PUZZLE_REQUIRED_FIELDS = {"territory_id", "difficulty_level", "theme", "grid_size", "grid", "words", "age_reviewed"}


def validate_word_puzzles(items: list[dict], known_territory_ids: set[str], existing_themes: set[tuple[str, str]]) -> list[str]:
    """
    V3.3 §6 (Jogos de Palavras — Caça-palavras). Valida a GRADE em si,
    não só metadados: cada palavra de `words` precisa de fato existir na
    grade numa linha reta (horizontal/vertical/diagonal, direção normal
    ou invertida) — a mesma checagem que o próprio jogo faria pra
    aceitar uma palavra encontrada, aplicada aqui pra pegar erro de
    geração ANTES de publicar (grade e palavras vêm de
    scripts/generate_word_search.py, nunca digitadas à mão, mas o
    script pode ter bug — validar de novo aqui é defesa em profundidade).
    """
    errors: list[str] = []
    seen_in_file: set[tuple[str, str]] = set()

    directions = [(0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)]

    def _word_exists_in_grid(grid: list[str], word: str) -> bool:
        size = len(grid)
        for row in range(size):
            for col in range(size):
                for d_row, d_col in directions:
                    end_row = row + d_row * (len(word) - 1)
                    end_col = col + d_col * (len(word) - 1)
                    if not (0 <= end_row < size and 0 <= end_col < size):
                        continue
                    found = "".join(grid[row + d_row * i][col + d_col * i] for i in range(len(word)))
                    if found == word:
                        return True
        return False

    for idx, item in enumerate(items):
        prefix = f"item {idx} ({item.get('theme', '<sem tema>')!r})"

        missing = WORD_PUZZLE_REQUIRED_FIELDS - item.keys()
        if missing:
            errors.append(f"{prefix}: campos faltando: {sorted(missing)}")
            continue

        territory_id = item["territory_id"]
        if territory_id not in known_territory_ids:
            errors.append(f"{prefix}: territory_id {territory_id!r} não existe (veja app/seed.py TERRITORIES)")

        if item["difficulty_level"] not in (1, 2, 3):
            errors.append(f"{prefix}: difficulty_level precisa ser 1, 2 ou 3 (veio {item['difficulty_level']!r})")

        if item["age_reviewed"] is not True:
            errors.append(f"{prefix}: age_reviewed precisa ser true — confirme manualmente que o conteúdo é apropriado pro público misto antes de marcar")

        grid = item["grid"]
        grid_size = item["grid_size"]
        if not isinstance(grid, list) or len(grid) != grid_size or any(not isinstance(r, str) or len(r) != grid_size for r in grid):
            errors.append(f"{prefix}: grid precisa ser uma lista de {grid_size} strings de {grid_size} caracteres cada")
            continue

        words = item["words"]
        if not isinstance(words, list) or not words:
            errors.append(f"{prefix}: words precisa ser uma lista não vazia")
            continue

        for word in words:
            if not _word_exists_in_grid(grid, word):
                errors.append(f"{prefix}: palavra {word!r} não foi encontrada em nenhuma linha reta da grade — erro de geração")

        key = (territory_id, item["theme"])
        if key in existing_themes:
            errors.append(f"{prefix}: já existe um Caça-palavras com esse tema nesse território")
        if key in seen_in_file:
            errors.append(f"{prefix}: tema duplicado dentro do próprio arquivo, no mesmo território")
        seen_in_file.add(key)

    return errors
