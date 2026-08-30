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

        key = (territory_id, item["text"])
        if key in existing_texts:
            errors.append(f"{prefix}: já existe uma Pausa para Aprender com esse texto nesse território")
        if key in seen_in_file:
            errors.append(f"{prefix}: texto duplicado dentro do próprio arquivo, no mesmo território")
        seen_in_file.add(key)

    return errors
