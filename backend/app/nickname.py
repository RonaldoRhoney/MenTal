import random

ADJECTIVES = ["Curiosa", "Veloz", "Sabida", "Astuta", "Brilhante", "Ligeira", "Esperta", "Atenta"]
NOUNS = ["Coruja", "Raposa", "Andorinha", "Lontra", "Gaivota", "Ariranha", "Tucana", "Jandaia"]


def generate_anonymous_nickname() -> str:
    return f"{random.choice(NOUNS)}-{random.choice(ADJECTIVES)}"
