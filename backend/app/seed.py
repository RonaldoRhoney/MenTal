from sqlalchemy.orm import Session

from . import models

TERRITORIES = [
    {"id": "palavras", "challenge_type": "palavras", "requires_subscription": False, "free_sample_count": 0, "display_order": 1},
    {"id": "numeros", "challenge_type": "numeros", "requires_subscription": False, "free_sample_count": 0, "display_order": 2},
    {"id": "logica", "challenge_type": "logica", "requires_subscription": True, "free_sample_count": 2, "display_order": 3},
    {"id": "conhecimento", "challenge_type": "conhecimento", "requires_subscription": True, "free_sample_count": 2, "display_order": 4},
]

CHALLENGES = [
    # Palavras
    {
        "territory_id": "palavras", "difficulty_level": 1,
        "prompt": "Qual é o antônimo de 'grande'?",
        "options": ["Enorme", "Pequeno", "Alto", "Largo"],
        "correct_answer": "Pequeno",
        "explanation": "Antônimo é a palavra de sentido oposto — o oposto de 'grande' é 'pequeno'.",
        "age_reviewed": True,
        "hints": ["Pense no oposto de tamanho.", "Começa com 'P'."],
    },
    {
        "territory_id": "palavras", "difficulty_level": 2,
        "prompt": "Reordene as letras 'ROVLI' para formar uma palavra.",
        "options": None,
        "correct_answer": "LIVRO",
        "explanation": "As letras R-O-V-L-I formam 'LIVRO'.",
        "age_reviewed": True,
        "hints": ["É um objeto que se lê.", "Tem 5 letras e começa com L."],
    },
    # Números
    {
        "territory_id": "numeros", "difficulty_level": 1,
        "prompt": "Quanto é 6 + 7?",
        "options": ["12", "13", "14", "11"],
        "correct_answer": "13",
        "explanation": "6 + 7 = 13.",
        "age_reviewed": True,
        "hints": ["É maior que 12.", "É um número ímpar."],
    },
    {
        "territory_id": "numeros", "difficulty_level": 2,
        "prompt": "Complete a sequência: 2, 4, 8, 16, ?",
        "options": ["24", "32", "20", "18"],
        "correct_answer": "32",
        "explanation": "Cada número é o dobro do anterior: 16 × 2 = 32.",
        "age_reviewed": True,
        "hints": ["Cada número é o dobro do anterior.", "16 vezes 2."],
    },
    # Lógica
    {
        "territory_id": "logica", "difficulty_level": 1,
        "prompt": "Qual item não pertence ao grupo: Maçã, Banana, Cenoura, Uva?",
        "options": ["Maçã", "Banana", "Cenoura", "Uva"],
        "correct_answer": "Cenoura",
        "explanation": "Maçã, banana e uva são frutas; cenoura é um legume.",
        "age_reviewed": True,
        "hints": ["Três deles crescem em árvores ou parreiras.", "Um deles é um legume, não fruta."],
    },
    # Conhecimento
    {
        "territory_id": "conhecimento", "difficulty_level": 1,
        "prompt": "Qual é a capital do Brasil?",
        "options": ["Rio de Janeiro", "São Paulo", "Brasília", "Salvador"],
        "correct_answer": "Brasília",
        "explanation": "Brasília é a capital federal do Brasil desde 1960.",
        "age_reviewed": True,
        "hints": ["Não é a cidade mais populosa do país.", "Foi inaugurada em 1960."],
    },
]


def seed_if_empty(db: Session) -> None:
    if db.query(models.Territory).count() > 0:
        return

    for t in TERRITORIES:
        db.add(models.Territory(**t))
    db.commit()

    for c in CHALLENGES:
        hints = c.pop("hints")
        challenge = models.Challenge(**c)
        db.add(challenge)
        db.commit()
        db.refresh(challenge)
        for level, content in enumerate(hints, start=1):
            db.add(models.ChallengeHint(challenge_id=challenge.id, hint_level=level, content=content))
        db.commit()
