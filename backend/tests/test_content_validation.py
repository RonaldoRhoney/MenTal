"""
Validação de conteúdo curado (backend/content/README.md). Só testa
ESTRUTURA — nunca a correção factual do conteúdo em si.
"""

from app.content_validation import validate_content, validate_learning_pauses

KNOWN_TERRITORIES = {"conhecimento", "numeros", "libras"}


def _valid_item(**overrides):
    item = {
        "territory_id": "conhecimento",
        "difficulty_level": 1,
        "prompt": "Qual é a capital do Brasil?",
        "options": ["Rio de Janeiro", "São Paulo", "Brasília", "Salvador"],
        "correct_answer": "Brasília",
        "explanation": "Brasília é a capital federal do Brasil desde 1960.",
        "hints": ["Não é a mais populosa.", "Inaugurada em 1960."],
        "age_reviewed": True,
    }
    item.update(overrides)
    return item


def test_valid_item_has_no_errors():
    errors = validate_content([_valid_item()], KNOWN_TERRITORIES, set())
    assert errors == []


def test_missing_field_is_reported():
    item = _valid_item()
    del item["explanation"]
    errors = validate_content([item], KNOWN_TERRITORIES, set())
    assert any("campos faltando" in e for e in errors)


def test_unknown_territory_is_reported():
    errors = validate_content([_valid_item(territory_id="territorio_que_nao_existe")], KNOWN_TERRITORIES, set())
    assert any("não existe" in e for e in errors)


def test_invalid_difficulty_level_is_reported():
    errors = validate_content([_valid_item(difficulty_level=5)], KNOWN_TERRITORIES, set())
    assert any("difficulty_level" in e for e in errors)


def test_wrong_number_of_options_is_reported():
    errors = validate_content([_valid_item(options=["A", "B", "C"])], KNOWN_TERRITORIES, set())
    assert any("4 alternativas" in e for e in errors)


def test_duplicate_options_are_reported():
    errors = validate_content([_valid_item(options=["A", "A", "B", "C"])], KNOWN_TERRITORIES, set())
    assert any("repetidas" in e for e in errors)


def test_correct_answer_not_in_options_is_reported():
    errors = validate_content([_valid_item(correct_answer="Não está nas opções")], KNOWN_TERRITORIES, set())
    assert any("não está em options" in e for e in errors)


def test_wrong_number_of_hints_is_reported():
    errors = validate_content([_valid_item(hints=["Só uma dica"])], KNOWN_TERRITORIES, set())
    assert any("2 dicas" in e for e in errors)


def test_age_reviewed_false_is_reported():
    errors = validate_content([_valid_item(age_reviewed=False)], KNOWN_TERRITORIES, set())
    assert any("age_reviewed" in e for e in errors)


def test_empty_prompt_is_reported():
    errors = validate_content([_valid_item(prompt="   ")], KNOWN_TERRITORIES, set())
    assert any("prompt não pode ser vazio" in e for e in errors)


def test_duplicate_prompt_against_existing_is_reported():
    existing = {("conhecimento", "Qual é a capital do Brasil?")}
    errors = validate_content([_valid_item()], KNOWN_TERRITORIES, existing)
    assert any("já existe um desafio" in e for e in errors)


def test_duplicate_prompt_within_file_is_reported():
    errors = validate_content([_valid_item(), _valid_item()], KNOWN_TERRITORIES, set())
    assert any("duplicado dentro do próprio arquivo" in e for e in errors)


def test_same_prompt_different_territory_is_not_a_duplicate():
    items = [_valid_item(territory_id="conhecimento"), _valid_item(territory_id="numeros")]
    errors = validate_content(items, KNOWN_TERRITORIES, set())
    assert errors == []


def test_prompt_image_is_optional_absent_is_fine():
    item = _valid_item()
    assert "prompt_image" not in item
    errors = validate_content([item], KNOWN_TERRITORIES, set())
    assert errors == []


def test_prompt_image_valid_emoji_is_fine():
    errors = validate_content([_valid_item(prompt_image="🏛️")], KNOWN_TERRITORIES, set())
    assert errors == []


def test_prompt_image_empty_string_is_reported():
    errors = validate_content([_valid_item(prompt_image="   ")], KNOWN_TERRITORIES, set())
    assert any("prompt_image" in e for e in errors)


def _valid_pause(**overrides):
    item = {
        "territory_id": "libras",
        "difficulty_level": 1,
        "text": "O sinal de 'obrigado(a)' em Libras tem origem em...",
        "age_reviewed": True,
    }
    item.update(overrides)
    return item


def test_learning_pause_without_video_fields_has_no_errors():
    errors = validate_learning_pauses([_valid_pause()], KNOWN_TERRITORIES, set())
    assert errors == []


def test_learning_pause_with_all_three_video_fields_has_no_errors():
    errors = validate_learning_pauses(
        [
            _valid_pause(
                video_url="https://dicionario.ines.gov.br/exemplo",
                source_name="INES",
                source_url="https://www.ines.gov.br",
            )
        ],
        KNOWN_TERRITORIES,
        set(),
    )
    assert errors == []


def test_learning_pause_with_only_video_url_is_reported():
    errors = validate_learning_pauses(
        [_valid_pause(video_url="https://dicionario.ines.gov.br/exemplo")], KNOWN_TERRITORIES, set()
    )
    assert any("vídeo institucional" in e for e in errors)


def test_learning_pause_with_video_url_and_source_name_but_no_source_url_is_reported():
    errors = validate_learning_pauses(
        [_valid_pause(video_url="https://dicionario.ines.gov.br/exemplo", source_name="INES")],
        KNOWN_TERRITORIES,
        set(),
    )
    assert any("vídeo institucional" in e for e in errors)
