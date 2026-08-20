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
    {
        "territory_id": "palavras", "difficulty_level": 1,
        "prompt": "Qual é o sinônimo de 'feliz'?",
        "options": ["Alegre", "Triste", "Cansado", "Calmo"],
        "correct_answer": "Alegre",
        "explanation": "Sinônimo é a palavra de sentido parecido — 'alegre' tem o mesmo sentido de 'feliz'.",
        "age_reviewed": True,
        "hints": ["É um sentimento positivo.", "Começa com 'A'."],
    },
    {
        "territory_id": "palavras", "difficulty_level": 2,
        "prompt": "Reordene as letras 'SALCA' para formar uma palavra.",
        "options": None,
        "correct_answer": "CASAL",
        "explanation": "As letras S-A-L-C-A formam 'CASAL'.",
        "age_reviewed": True,
        "hints": ["É uma dupla de pessoas.", "Tem 5 letras e começa com C."],
    },
    {
        "territory_id": "palavras", "difficulty_level": 3,
        "prompt": "Qual destas palavras é antônimo de 'rápido'?",
        "options": ["Lento", "Veloz", "Ligeiro", "Ágil"],
        "correct_answer": "Lento",
        "explanation": "'Lento' é o oposto de 'rápido'; as outras opções são sinônimos de 'rápido'.",
        "age_reviewed": True,
        "hints": ["É o oposto de velocidade alta.", "Começa com 'L'."],
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
    {
        "territory_id": "numeros", "difficulty_level": 1,
        "prompt": "Quanto é 9 - 4?",
        "options": ["4", "5", "6", "3"],
        "correct_answer": "5",
        "explanation": "9 - 4 = 5.",
        "age_reviewed": True,
        "hints": ["É um número ímpar.", "Está entre 4 e 6."],
    },
    {
        "territory_id": "numeros", "difficulty_level": 2,
        "prompt": "Complete a sequência: 1, 1, 2, 3, 5, ?",
        "options": ["6", "7", "8", "9"],
        "correct_answer": "8",
        "explanation": "Cada número é a soma dos dois anteriores (sequência de Fibonacci): 3 + 5 = 8.",
        "age_reviewed": True,
        "hints": ["Some os dois números anteriores.", "3 + 5."],
    },
    {
        "territory_id": "numeros", "difficulty_level": 3,
        "prompt": "Quanto é 7 × 6?",
        "options": ["40", "42", "48", "36"],
        "correct_answer": "42",
        "explanation": "7 × 6 = 42.",
        "age_reviewed": True,
        "hints": ["É maior que 40.", "É um número par."],
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
    {
        "territory_id": "logica", "difficulty_level": 1,
        "prompt": "Qual número não pertence ao grupo: 2, 4, 6, 9?",
        "options": ["2", "4", "6", "9"],
        "correct_answer": "9",
        "explanation": "2, 4 e 6 são pares; 9 é o único número ímpar do grupo.",
        "age_reviewed": True,
        "hints": ["Três deles são números pares.", "Um deles é ímpar."],
    },
    {
        "territory_id": "logica", "difficulty_level": 2,
        "prompt": "Se hoje é terça-feira, que dia da semana será depois de amanhã?",
        "options": ["Quarta", "Quinta", "Sexta", "Segunda"],
        "correct_answer": "Quinta",
        "explanation": "Terça + 2 dias = quinta-feira.",
        "age_reviewed": True,
        "hints": ["Conte dois dias a partir de terça.", "Não é quarta, é um dia depois dela."],
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
    {
        "territory_id": "conhecimento", "difficulty_level": 1,
        "prompt": "Qual é o maior oceano do mundo?",
        "options": ["Atlântico", "Pacífico", "Índico", "Ártico"],
        "correct_answer": "Pacífico",
        "explanation": "O Oceano Pacífico é o maior e mais profundo oceano do mundo.",
        "age_reviewed": True,
        "hints": ["Fica entre a Ásia e as Américas.", "Começa com 'P'."],
    },
    {
        "territory_id": "conhecimento", "difficulty_level": 1,
        "prompt": "Em que país fica a Torre Eiffel?",
        "options": ["França", "Itália", "Espanha", "Alemanha"],
        "correct_answer": "França",
        "explanation": "A Torre Eiffel fica em Paris, capital da França.",
        "age_reviewed": True,
        "hints": ["É o mesmo país da cidade de Paris.", "Começa com 'F'."],
    },
    {
        "territory_id": "conhecimento", "difficulty_level": 2,
        "prompt": "Quantos planetas existem no Sistema Solar?",
        "options": ["7", "8", "9", "10"],
        "correct_answer": "8",
        "explanation": "O Sistema Solar tem 8 planetas — Plutão foi reclassificado como planeta anão em 2006.",
        "age_reviewed": True,
        "hints": ["É menos do que 9.", "Termina em Netuno, não em Plutão."],
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
