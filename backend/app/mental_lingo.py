"""
MENTAL LINGO — assistente de voz do Mundo dos Idiomas.

MUNDO/Mundo_dos_Idiomas/Mental_Lingo/MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md
(aprovado por Rhoney, 23/09/2026, escolha explícita entre 3 opções de
escopo): "V1 100% custo zero" — nenhuma IA generativa, nenhuma API paga,
nenhum RAG. O reconhecimento de fala acontece no APARELHO (client,
pacote speech_to_text sobre o SpeechRecognizer nativo do Android — ver
pubspec.yaml); este módulo só recebe o TEXTO já transcrito e responde
por CONSULTA direta ao vocabulário já curado do Mundo dos Idiomas —
nunca gera texto novo, nunca "alucina" uma tradução. A resposta é
sempre um `explanation` que já existe no banco (mesmo texto que o
jogador veria completando o Desafio normalmente, ver
scripts/convert_idiomas_content.py) — zero geração, 100% conteúdo
aprovado.

100% dos prompts de Idiomas seguem só 2 templates fixos (confirmado por
levantamento no conteúdo real, ver services.extract_portuguese_meaning)
— é o que torna esse lookup confiável sem precisar de fuzzy match/IA.

Escopo de idioma: só idiomas falados (Inglês, Espanhol, Francês) — Libras
é língua visual-espacial, sem componente sonoro (MUNDO_IDIOMAS_AUDIO_E_
LIBRAS_V1.md), então fica fora do voz-e-resposta; uma pergunta sobre
Libras recebe uma resposta textual explicando o motivo, nunca um erro.
"""

import re

from sqlalchemy import select
from sqlalchemy.orm import Session

from . import config, models, wiktionary
from .services import extract_portuguese_meaning
from .timeutil import utcnow

_LANGUAGE_KEYWORDS: dict[str, tuple[str, ...]] = {
    "ingles": ("inglês", "ingles", "english"),
    "espanhol": ("espanhol", "spanish", "español"),
    "frances": ("francês", "frances", "french", "français"),
}

_LIBRAS_KEYWORDS = ("libras", "língua de sinais", "lingua de sinais", "linguagem de sinais")

# Frases-gatilho reconhecidas na fala já transcrita — cobre as formas
# mais naturais de perguntar. Ordem importa: os 3 primeiros padrões
# capturam a palavra E o idioma-alvo juntos; o último ("o que
# significa X") não menciona idioma nenhum de propósito (o jogador não
# sabe de qual idioma a palavra é — é o próprio Mental Lingo quem
# descobre, buscando nos 3 idiomas ao mesmo tempo).
_ASK_PATTERNS = [
    re.compile(r"^como (?:se|é que se) (?:escreve|diz|fala)\s+(.+?)\s+em\s+(\w+)\??$", re.IGNORECASE),
    re.compile(r"^traduz[ao]?\s+(?:a palavra\s+)?(.+?)\s+(?:para|em)\s+(\w+)\??$", re.IGNORECASE),
    re.compile(r"^qual\s+(?:é\s+)?a\s+tradu[çc][ãa]o\s+de\s+(.+?)\s+(?:para|em)\s+(\w+)\??$", re.IGNORECASE),
    re.compile(r"^o que\s+(?:significa|quer dizer)\s+(.+?)\??$", re.IGNORECASE),
]


def _normalize(text: str) -> str:
    return text.strip().strip("?!.").strip()


def _detect_language(text: str) -> str | None:
    lowered = text.lower()
    for block_id, keywords in _LANGUAGE_KEYWORDS.items():
        if any(keyword in lowered for keyword in keywords):
            return block_id
    return None


def _extract_word(question: str) -> tuple[str | None, str | None]:
    """(palavra perguntada, palavra-idioma capturada pelo padrão — pode
    ser None quando o padrão não menciona idioma, ex.: "o que significa
    X")."""
    q = _normalize(question)
    for pattern in _ASK_PATTERNS:
        m = pattern.match(q)
        if m:
            groups = m.groups()
            word = groups[0].strip(" '\"")
            lang_word = groups[1] if len(groups) > 1 else None
            return word or None, lang_word
    return None, None


def _language_of_territory(territory_id: str) -> str:
    for block_id in _LANGUAGE_KEYWORDS:
        if territory_id.startswith(block_id):
            return block_id
    return "ingles"  # nunca deveria acontecer — territory_ids vêm de IDIOMA_TERRITORY_IDS


def _not_understood() -> dict:
    return {
        "found": False,
        "answer_text": "Não entendi a pergunta. Tente algo como \"como se escreve casa em inglês?\" ou \"o que significa house?\".",
        "matched_word": None,
        "target_language": None,
    }


MAX_GAP_WORD_LEN = 80


def _record_gap(db: Session, word: str, target: str | None) -> None:
    """Registra a lacuna (só agregado, sem usuário). Falha aqui nunca pode
    derrubar a resposta ao jogador — é só telemetria de curadoria."""
    key = word.strip().lower()[:MAX_GAP_WORD_LEN]
    if not key:
        return
    try:
        row = db.get(models.MentalLingoGap, (key, target or ""))
        if row is None:
            db.add(models.MentalLingoGap(word=key, target_language=target or ""))
        else:
            row.times_asked += 1
            row.last_asked_at = utcnow()
        db.commit()
    except Exception:
        db.rollback()


def answer_question(db: Session, question: str) -> dict:
    question = (question or "").strip()
    if not question:
        return _not_understood()

    lowered = question.lower()
    if any(keyword in lowered for keyword in _LIBRAS_KEYWORDS):
        return {
            "found": False,
            "answer_text": (
                "O MENTAL LINGO por voz ainda não responde sobre Libras — é uma língua "
                "visual-espacial, sem pronúncia falada. Dá uma olhada na seção de Libras "
                "aqui no Mundo dos Idiomas."
            ),
            "matched_word": None,
            "target_language": None,
        }

    word, lang_word = _extract_word(question)
    if word is None:
        return _not_understood()
    word_norm = word.strip().lower()

    target = _detect_language(lang_word) if lang_word else None
    territory_ids = (
        [tid for tid in config.IDIOMA_TERRITORY_IDS if tid.startswith(target)]
        if target is not None
        else list(config.IDIOMA_TERRITORY_IDS)
    )
    challenges = db.execute(
        select(models.Challenge).where(models.Challenge.territory_id.in_(territory_ids))
    ).scalars().all()

    # 1) a palavra perguntada é o termo em PORTUGUÊS (ex.: "casa" -> "House").
    for challenge in challenges:
        meaning = extract_portuguese_meaning(challenge.prompt)
        if meaning and meaning.strip().lower() == word_norm:
            return {
                "found": True,
                "answer_text": challenge.explanation,
                "matched_word": word,
                "target_language": _language_of_territory(challenge.territory_id),
            }

    # 2) a palavra perguntada é o termo NO IDIOMA-ALVO (ex.: "house" -> "casa").
    for challenge in challenges:
        if challenge.correct_answer.strip().lower() == word_norm:
            return {
                "found": True,
                "answer_text": challenge.explanation,
                "matched_word": word,
                "target_language": _language_of_territory(challenge.territory_id),
            }

    _record_gap(db, word, target)
    suggestion = _suggestion_for(db, word_norm, target)
    if suggestion is not None:
        reviewed = suggestion.status == "approved"
        text = suggestion.answer_text if reviewed else f"{suggestion.answer_text} (Fonte: Wikcionário — ainda não revisado.)"
        return {
            "found": True,
            "answer_text": text,
            "matched_word": word,
            "target_language": target or "ingles",
            "suggestion_key": {"word": suggestion.word, "target_language": suggestion.target_language},
            "reviewed": reviewed,
        }
    return {
        "found": False,
        "answer_text": (
            f"Ainda não tenho '{word}' no vocabulário do Mundo dos Idiomas. "
            "Anotei o pedido: as palavras mais procuradas entram no vocabulário depois de revisadas."
        ),
        "matched_word": word,
        "target_language": target,
    }


def _suggestion_for(db: Session, word_norm: str, target: str | None) -> models.MentalLingoSuggestion | None:
    """Sugestão aberta (Wikcionário), só Português -> Inglês; cacheada. 'rejected' nunca é servida."""
    if target not in (None, "ingles"):
        return None
    key = word_norm[:MAX_GAP_WORD_LEN]
    row = db.get(models.MentalLingoSuggestion, (key, "ingles"))
    if row is not None:
        return None if row.status == "rejected" else row
    if " " in key:  # só palavra isolada: frase inteira o Wikcionário não traduz
        return None
    glosses = wiktionary.glosses_pt_to_en(key)
    if not glosses:
        return None
    text = f"'{key}' em inglês pode ser: {', '.join(glosses)}."
    row = models.MentalLingoSuggestion(word=key, target_language="ingles", answer_text=text)
    try:
        db.add(row)
        db.commit()
    except Exception:
        db.rollback()
        return None
    return row


def vote(db: Session, word: str, target_language: str, useful: bool) -> bool:
    row = db.get(models.MentalLingoSuggestion, (word, target_language))
    if row is None:
        return False
    if useful:
        row.useful_votes += 1
    else:
        row.wrong_votes += 1
    db.commit()
    return True
