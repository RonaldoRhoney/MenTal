from sqlalchemy.orm import Session

from . import models

# V2 item 10 — Mundos completos (V2_KICKOFF.md §2/§6A). Agrupamento
# aprovado por Rhoney em 2026-08-22 — ver comentário em models.World.
WORLDS = [
    {"id": "linguagem", "name": "Mundo da Linguagem", "display_order": 1},
    {"id": "mente_logica", "name": "Mundo da Mente Lógica", "display_order": 2},
]

TERRITORIES = [
    {"id": "palavras", "challenge_type": "palavras", "requires_subscription": False, "free_sample_count": 0, "display_order": 1, "world_id": "linguagem"},
    {"id": "numeros", "challenge_type": "numeros", "requires_subscription": False, "free_sample_count": 0, "display_order": 2, "world_id": "mente_logica"},
    {"id": "logica", "challenge_type": "logica", "requires_subscription": True, "free_sample_count": 2, "display_order": 3, "world_id": "mente_logica"},
    {"id": "conhecimento", "challenge_type": "conhecimento", "requires_subscription": True, "free_sample_count": 2, "display_order": 4, "world_id": "mente_logica"},
    # V2 item 2 — Enigmas/charadas (V2_KICKOFF.md §6A). Reaproveita 100% do
    # fluxo de desafio existente — nenhum campo/modelo novo. Tratado como
    # território "avançado" (mesmo tier de logica/conhecimento), decisão
    # de produto tomada aqui por não ter sido especificada: charadas pedem
    # mais raciocínio que os territórios gratuitos (palavras/números
    # diretos), revisável quando houver dado real de uso.
    {"id": "enigmas", "challenge_type": "enigmas", "requires_subscription": True, "free_sample_count": 2, "display_order": 5, "world_id": "linguagem"},
    # V2 item 3 — Textos (interpretação/inferência, V2_KICKOFF.md §6A).
    # Mesmo reaproveitamento de fluxo dos itens 1-2 — só o parágrafo-base
    # fica no campo "prompt" (sem campo novo no modelo). Mesmo tier
    # avançado de logica/conhecimento/enigmas.
    {"id": "textos", "challenge_type": "textos", "requires_subscription": True, "free_sample_count": 2, "display_order": 6, "world_id": "linguagem"},
    # V2 item 4 — Desafios visuais (V2_KICKOFF.md §6A). Decisão de
    # armazenamento (confirmada com Rhoney antes de codar, régua
    # Free-First): NENHUMA imagem real é usada — as opções são ícones
    # vetoriais do próprio Flutter (forma+preenchimento+cor), codificados
    # como string no campo "options" já existente (formato
    # "forma_preenchimento_cor_índice", decodificado em
    # client/lib/visual_options.dart). Custo zero com certeza absoluta —
    # sem Supabase Storage, sem rede, funciona offline, sem migration além
    # da linha de território. Mesmo tier avançado dos demais territórios
    # novos da V2.
    {"id": "visual", "challenge_type": "visual", "requires_subscription": True, "free_sample_count": 2, "display_order": 7, "world_id": "mente_logica"},
]

# V2 item 1 — Badges/Conquistas (V2_KICKOFF.md §6A). Catálogo curado à
# mão, mesmo conteúdo espelhado em migrations/004_badges.sql.
BADGES = [
    {
        "code": "first_conquest", "name": "Primeira Conquista",
        "description": "Conquiste seu primeiro território.",
        "criteria_type": "territory_conquered_count", "criteria_value": 1, "display_order": 1,
    },
    {
        "code": "collector", "name": "Colecionador",
        "description": "Conquiste todos os territórios disponíveis.",
        "criteria_type": "all_territories_conquered", "criteria_value": 0, "display_order": 2,
    },
    {
        "code": "iron_streak", "name": "Sequência de Ferro",
        "description": "Mantenha uma sequência de 7 dias seguidos.",
        "criteria_type": "streak_days", "criteria_value": 7, "display_order": 3,
    },
    {
        "code": "sharp_mind", "name": "Mente Afiada",
        "description": "Responda corretamente 50 desafios no total.",
        "criteria_type": "total_correct_answers", "criteria_value": 50, "display_order": 4,
    },
    {
        "code": "no_help_needed", "name": "Sem Ajuda",
        "description": "Responda corretamente 10 desafios sem usar nenhuma dica.",
        "criteria_type": "hint_free_correct_answers", "criteria_value": 10, "display_order": 5,
    },
]


def _visual_option(shape: str, fill: str, color: str, index: int) -> str:
    # Formato "forma_preenchimento_cor_índice" — o índice existe só para
    # garantir strings únicas por desafio (cada RadioListTile precisa de
    # um value distinto), nunca é exibido nem interpretado visualmente.
    # Espelhado em client/lib/visual_options.dart (parseVisualOption).
    return f"{shape}_{fill}_{color}_{index}"


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
    {
        "territory_id": "palavras", "difficulty_level": 1,
        "prompt": "Qual é o antônimo de 'claro'?",
        "options": ["Escuro", "Brilhante", "Visível", "Aceso"],
        "correct_answer": "Escuro",
        "explanation": "'Escuro' é o oposto de 'claro'.",
        "age_reviewed": True,
        "hints": ["Pense na falta de luz.", "Começa com 'E'."],
    },
    {
        "territory_id": "palavras", "difficulty_level": 1,
        "prompt": "Qual é o sinônimo de 'bonito'?",
        "options": ["Belo", "Feio", "Comum", "Grande"],
        "correct_answer": "Belo",
        "explanation": "'Belo' tem o mesmo sentido de 'bonito'.",
        "age_reviewed": True,
        "hints": ["É uma palavra elogiosa sobre aparência.", "Começa com 'B'."],
    },
    {
        "territory_id": "palavras", "difficulty_level": 1,
        "prompt": "Qual é o antônimo de 'quente'?",
        "options": ["Frio", "Morno", "Ardente", "Quieto"],
        "correct_answer": "Frio",
        "explanation": "'Frio' é o oposto de 'quente'.",
        "age_reviewed": True,
        "hints": ["Pense em temperatura baixa.", "Começa com 'F'."],
    },
    {
        "territory_id": "palavras", "difficulty_level": 2,
        "prompt": "Reordene as letras 'DERTA' para formar uma palavra.",
        "options": None,
        "correct_answer": "TARDE",
        "explanation": "As letras D-E-R-T-A formam 'TARDE'.",
        "age_reviewed": True,
        "hints": ["É um período do dia.", "Vem depois do meio-dia."],
    },
    {
        "territory_id": "palavras", "difficulty_level": 2,
        "prompt": "Reordene as letras 'EDREV' para formar uma palavra.",
        "options": None,
        "correct_answer": "VERDE",
        "explanation": "As letras E-D-R-E-V formam 'VERDE'.",
        "age_reviewed": True,
        "hints": ["É uma cor.", "É a cor das folhas."],
    },
    {
        "territory_id": "palavras", "difficulty_level": 3,
        "prompt": "Qual destas palavras é sinônimo de 'perspicaz'?",
        "options": ["Esperto", "Distraído", "Lento", "Confuso"],
        "correct_answer": "Esperto",
        "explanation": "'Perspicaz' descreve quem percebe as coisas rapidamente — o mesmo sentido de 'esperto'.",
        "age_reviewed": True,
        "hints": ["É uma qualidade de quem entende rápido.", "Começa com 'E'."],
    },
    {
        "territory_id": "palavras", "difficulty_level": 3,
        "prompt": "Qual destas palavras é antônimo de 'generoso'?",
        "options": ["Mesquinho", "Gentil", "Amável", "Solidário"],
        "correct_answer": "Mesquinho",
        "explanation": "'Mesquinho' é o oposto de 'generoso' — quem não gosta de compartilhar.",
        "age_reviewed": True,
        "hints": ["É quem não gosta de dar ou compartilhar.", "Começa com 'M'."],
    },
    # V2 item 7 — Conteúdo educacional avançado (V2_KICKOFF.md §6A):
    # critério de fechamento é mínimo 15 desafios por território, 4+ por
    # nível 1-3. "Palavras" tinha 12 (5/4/3) — 3 itens novos abaixo levam
    # a 15 (5/5/5).
    {
        "territory_id": "palavras", "difficulty_level": 2,
        "prompt": "Reordene as letras 'OMDNU' para formar uma palavra.",
        "options": None,
        "correct_answer": "MUNDO",
        "explanation": "As letras O-M-D-N-U formam 'MUNDO'.",
        "age_reviewed": True,
        "hints": ["É o planeta em que vivemos, em outra palavra.", "Tem 5 letras e começa com M."],
    },
    {
        "territory_id": "palavras", "difficulty_level": 3,
        "prompt": "Qual destas palavras é sinônimo de 'árduo'?",
        "options": ["Difícil", "Fácil", "Leve", "Rápido"],
        "correct_answer": "Difícil",
        "explanation": "'Árduo' descreve algo que exige muito esforço — o mesmo sentido de 'difícil'.",
        "age_reviewed": True,
        "hints": ["É o oposto de 'fácil'.", "Descreve uma tarefa que exige muito esforço."],
    },
    {
        "territory_id": "palavras", "difficulty_level": 3,
        "prompt": "Qual destas palavras é antônimo de 'humilde'?",
        "options": ["Arrogante", "Modesto", "Simples", "Gentil"],
        "correct_answer": "Arrogante",
        "explanation": "'Arrogante' é o oposto de 'humilde' — quem se acha superior aos outros.",
        "age_reviewed": True,
        "hints": ["É quem se acha melhor que os outros.", "Começa com 'A'."],
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
    {
        "territory_id": "numeros", "difficulty_level": 1,
        "prompt": "Quanto é 15 - 7?",
        "options": ["7", "8", "9", "6"],
        "correct_answer": "8",
        "explanation": "15 - 7 = 8.",
        "age_reviewed": True,
        "hints": ["É um número par.", "Está entre 6 e 9."],
    },
    {
        "territory_id": "numeros", "difficulty_level": 1,
        "prompt": "Quanto é 4 × 3?",
        "options": ["10", "11", "12", "14"],
        "correct_answer": "12",
        "explanation": "4 × 3 = 12.",
        "age_reviewed": True,
        "hints": ["É um número par.", "É maior que 10."],
    },
    {
        "territory_id": "numeros", "difficulty_level": 1,
        "prompt": "Quanto é 20 ÷ 4?",
        "options": ["4", "5", "6", "8"],
        "correct_answer": "5",
        "explanation": "20 ÷ 4 = 5.",
        "age_reviewed": True,
        "hints": ["É um número ímpar.", "É menor que 6."],
    },
    {
        "territory_id": "numeros", "difficulty_level": 2,
        "prompt": "Complete a sequência: 3, 6, 9, 12, ?",
        "options": ["14", "15", "16", "18"],
        "correct_answer": "15",
        "explanation": "Cada número aumenta 3: 12 + 3 = 15.",
        "age_reviewed": True,
        "hints": ["Cada número é 3 a mais que o anterior.", "12 + 3."],
    },
    {
        "territory_id": "numeros", "difficulty_level": 2,
        "prompt": "Complete a sequência: 100, 90, 80, 70, ?",
        "options": ["50", "60", "65", "75"],
        "correct_answer": "60",
        "explanation": "Cada número diminui 10: 70 - 10 = 60.",
        "age_reviewed": True,
        "hints": ["Cada número é 10 a menos que o anterior.", "70 - 10."],
    },
    {
        "territory_id": "numeros", "difficulty_level": 3,
        "prompt": "Quanto é 9 × 9?",
        "options": ["72", "81", "91", "99"],
        "correct_answer": "81",
        "explanation": "9 × 9 = 81.",
        "age_reviewed": True,
        "hints": ["É maior que 72.", "Termina em 1."],
    },
    {
        "territory_id": "numeros", "difficulty_level": 3,
        "prompt": "Quanto é 144 ÷ 12?",
        "options": ["10", "11", "12", "13"],
        "correct_answer": "12",
        "explanation": "144 ÷ 12 = 12.",
        "age_reviewed": True,
        "hints": ["É um número par.", "É maior que 10."],
    },
    # V2 item 7 — "Números" tinha 12 (5/4/3) — 3 itens novos abaixo levam
    # a 15 (5/5/5).
    {
        "territory_id": "numeros", "difficulty_level": 2,
        "prompt": "Complete a sequência: 1, 3, 6, 10, ?",
        "options": ["13", "14", "15", "16"],
        "correct_answer": "15",
        "explanation": "Cada número soma um valor que cresce em 1 a cada passo (+2, +3, +4, +5): 10 + 5 = 15.",
        "age_reviewed": True,
        "hints": ["A diferença entre os números aumenta a cada passo.", "De 6 para 10 somou 4; e agora?"],
    },
    {
        "territory_id": "numeros", "difficulty_level": 3,
        "prompt": "Quanto é 8 × 7?",
        "options": ["54", "56", "58", "64"],
        "correct_answer": "56",
        "explanation": "8 × 7 = 56.",
        "age_reviewed": True,
        "hints": ["É um número par.", "É maior que 50 e menor que 60."],
    },
    {
        "territory_id": "numeros", "difficulty_level": 3,
        "prompt": "Quanto é 13 × 4?",
        "options": ["48", "50", "52", "56"],
        "correct_answer": "52",
        "explanation": "13 × 4 = 52.",
        "age_reviewed": True,
        "hints": ["É um número par.", "Some 13 quatro vezes."],
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
    {
        "territory_id": "logica", "difficulty_level": 1,
        "prompt": "Qual item não pertence ao grupo: Círculo, Quadrado, Triângulo, Vermelho?",
        "options": ["Círculo", "Quadrado", "Triângulo", "Vermelho"],
        "correct_answer": "Vermelho",
        "explanation": "Círculo, quadrado e triângulo são formas geométricas; vermelho é uma cor.",
        "age_reviewed": True,
        "hints": ["Três deles são formas geométricas.", "Um deles é uma cor."],
    },
    {
        "territory_id": "logica", "difficulty_level": 1,
        "prompt": "Qual item não pertence ao grupo: Cachorro, Gato, Cavalo, Cadeira?",
        "options": ["Cachorro", "Gato", "Cavalo", "Cadeira"],
        "correct_answer": "Cadeira",
        "explanation": "Cachorro, gato e cavalo são animais; cadeira é um objeto.",
        "age_reviewed": True,
        "hints": ["Três deles são seres vivos.", "Um deles é um móvel."],
    },
    {
        "territory_id": "logica", "difficulty_level": 1,
        "prompt": "Se A é maior que B, e B é maior que C, quem é o menor dos três?",
        "options": ["A", "B", "C", "Não dá para saber"],
        "correct_answer": "C",
        "explanation": "Se A > B e B > C, então C é o menor dos três.",
        "age_reviewed": True,
        "hints": ["Ordene do maior para o menor.", "É a última letra da comparação."],
    },
    {
        "territory_id": "logica", "difficulty_level": 2,
        "prompt": "Se ontem foi sexta-feira, qual dia será amanhã?",
        "options": ["Domingo", "Segunda", "Sábado", "Sexta"],
        "correct_answer": "Domingo",
        "explanation": "Se ontem foi sexta, hoje é sábado, então amanhã é domingo.",
        "age_reviewed": True,
        "hints": ["Primeiro descubra que dia é hoje.", "Hoje é sábado."],
    },
    {
        "territory_id": "logica", "difficulty_level": 2,
        "prompt": "Numa fila, Ana está na frente de Beto, e Beto está na frente de Carla. Quem está no fim da fila?",
        "options": ["Ana", "Beto", "Carla", "Nenhum"],
        "correct_answer": "Carla",
        "explanation": "A ordem da fila é Ana, Beto, Carla — Carla é a última.",
        "age_reviewed": True,
        "hints": ["Desenhe a ordem da fila.", "É a última pessoa mencionada."],
    },
    {
        "territory_id": "logica", "difficulty_level": 2,
        "prompt": "Complete a sequência: 1, 4, 9, 16, ?",
        "options": ["20", "24", "25", "23"],
        "correct_answer": "25",
        "explanation": "São os quadrados dos números 1, 2, 3, 4, 5: 5 × 5 = 25.",
        "age_reviewed": True,
        "hints": ["São números ao quadrado (1×1, 2×2, 3×3...).", "5 × 5."],
    },
    {
        "territory_id": "logica", "difficulty_level": 3,
        "prompt": "Todos os xis são yis. Alguns yis são zis. Podemos afirmar que todos os xis são zis?",
        "options": ["Sim", "Não", "Depende", "Sempre"],
        "correct_answer": "Não",
        "explanation": "Só sabemos que ALGUNS yis são zis — não há garantia de que os xis estejam entre esses.",
        "age_reviewed": True,
        "hints": ["'Alguns' não significa 'todos'.", "Não há informação suficiente para garantir isso."],
    },
    {
        "territory_id": "logica", "difficulty_level": 3,
        "prompt": "Num grupo de 5 amigos, cada um cumprimenta todos os outros uma vez com um aperto de mão. Quantos apertos de mão acontecem no total?",
        "options": ["8", "9", "10", "12"],
        "correct_answer": "10",
        "explanation": "Cada um dos 5 cumprimenta os outros 4, mas cada aperto é contado uma vez: (5×4)/2 = 10.",
        "age_reviewed": True,
        "hints": ["Não conte o mesmo aperto duas vezes.", "(5 × 4) ÷ 2."],
    },
    {
        "territory_id": "logica", "difficulty_level": 3,
        "prompt": "Qual número não pertence ao grupo: 3, 5, 7, 8, 11?",
        "options": ["3", "5", "7", "8"],
        "correct_answer": "8",
        "explanation": "3, 5, 7 e 11 são números primos; 8 é o único que não é primo.",
        "age_reviewed": True,
        "hints": ["Quatro deles só podem ser divididos por 1 e por si mesmos.", "Um deles é par e tem outros divisores."],
    },
    # V2 item 7 — "Lógica" tinha 12 (5/4/3) — 3 itens novos abaixo levam
    # a 15 (5/5/5).
    {
        "territory_id": "logica", "difficulty_level": 2,
        "prompt": "Se depois de amanhã é quarta-feira, que dia é hoje?",
        "options": ["Domingo", "Segunda", "Terça", "Quarta"],
        "correct_answer": "Segunda",
        "explanation": "Se depois de amanhã é quarta, amanhã é terça — e hoje é segunda.",
        "age_reviewed": True,
        "hints": ["Conte dois dias para trás a partir de quarta-feira.", "É o primeiro dia da semana de trabalho."],
    },
    {
        "territory_id": "logica", "difficulty_level": 3,
        "prompt": "Todos os gatos são mamíferos. Nenhum mamífero é réptil. Podemos afirmar que nenhum gato é réptil?",
        "options": ["Sim", "Não", "Só às vezes", "Impossível saber"],
        "correct_answer": "Sim",
        "explanation": "Se todo gato é mamífero e nenhum mamífero é réptil, então nenhum gato pode ser réptil — a conclusão é válida.",
        "age_reviewed": True,
        "hints": ["Junte as duas frases: gato → mamífero, mamífero → não-réptil.", "Isso encadeia numa conclusão válida sobre gatos."],
    },
    {
        "territory_id": "logica", "difficulty_level": 3,
        "prompt": "Numa corrida com 4 amigos, Marina chegou antes de Pedro, e Pedro chegou antes de Júlia, mas depois de Renato. Quem chegou em último lugar?",
        "options": ["Marina", "Pedro", "Júlia", "Renato"],
        "correct_answer": "Júlia",
        "explanation": "Marina e Renato chegaram antes de Pedro, e Pedro chegou antes de Júlia — então Júlia é a única que não chegou antes de mais ninguém, ficando em último.",
        "age_reviewed": True,
        "hints": ["Três pessoas chegaram antes de alguém nessa história — só uma não chegou antes de ninguém.", "Monte a ordem: Renato e Marina antes de Pedro, Pedro antes dela."],
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
    {
        "territory_id": "conhecimento", "difficulty_level": 1,
        "prompt": "Qual é o maior país do mundo em área?",
        "options": ["Rússia", "China", "Canadá", "EUA"],
        "correct_answer": "Rússia",
        "explanation": "A Rússia é o maior país do mundo em área territorial.",
        "age_reviewed": True,
        "hints": ["Fica entre a Europa e a Ásia.", "Começa com 'R'."],
    },
    {
        "territory_id": "conhecimento", "difficulty_level": 1,
        "prompt": "Em que continente fica o Egito?",
        "options": ["África", "Ásia", "Europa", "América"],
        "correct_answer": "África",
        "explanation": "O Egito fica no continente africano.",
        "age_reviewed": True,
        "hints": ["É o mesmo continente do deserto do Saara.", "Começa com 'Á'."],
    },
    {
        "territory_id": "conhecimento", "difficulty_level": 2,
        "prompt": "Quem pintou a Mona Lisa?",
        "options": ["Leonardo da Vinci", "Picasso", "Van Gogh", "Michelangelo"],
        "correct_answer": "Leonardo da Vinci",
        "explanation": "A Mona Lisa foi pintada por Leonardo da Vinci, no século XVI.",
        "age_reviewed": True,
        "hints": ["Foi um artista e inventor renascentista italiano.", "Também pintou 'A Última Ceia'."],
    },
    {
        "territory_id": "conhecimento", "difficulty_level": 2,
        "prompt": "Qual é o metal que é líquido à temperatura ambiente?",
        "options": ["Mercúrio", "Ferro", "Ouro", "Chumbo"],
        "correct_answer": "Mercúrio",
        "explanation": "O mercúrio é o único metal líquido à temperatura ambiente.",
        "age_reviewed": True,
        "hints": ["Era usado em termômetros antigos.", "Tem o mesmo nome de um planeta."],
    },
    {
        "territory_id": "conhecimento", "difficulty_level": 2,
        "prompt": "Quantos ossos tem, aproximadamente, o corpo de um adulto?",
        "options": ["106", "206", "306", "406"],
        "correct_answer": "206",
        "explanation": "O esqueleto adulto humano tem cerca de 206 ossos.",
        "age_reviewed": True,
        "hints": ["É mais que 100 e menos que 300.", "Bebês nascem com mais ossos que isso."],
    },
    {
        "territory_id": "conhecimento", "difficulty_level": 2,
        "prompt": "Qual é o idioma mais falado no mundo como língua nativa?",
        "options": ["Mandarim", "Inglês", "Espanhol", "Hindi"],
        "correct_answer": "Mandarim",
        "explanation": "O mandarim é o idioma com mais falantes nativos no mundo, principalmente na China.",
        "age_reviewed": True,
        "hints": ["É falado principalmente na China.", "Não usa alfabeto latino."],
    },
    {
        "territory_id": "conhecimento", "difficulty_level": 3,
        "prompt": "Em que ano começou a Segunda Guerra Mundial?",
        "options": ["1935", "1939", "1941", "1945"],
        "correct_answer": "1939",
        "explanation": "A Segunda Guerra Mundial começou em 1939, com a invasão da Polônia.",
        "age_reviewed": True,
        "hints": ["Foi no final da década de 1930.", "Terminou em 1945."],
    },
    {
        "territory_id": "conhecimento", "difficulty_level": 3,
        "prompt": "Qual é o elemento químico de símbolo 'O'?",
        "options": ["Ouro", "Oxigênio", "Ósmio", "Óxido"],
        "correct_answer": "Oxigênio",
        "explanation": "O símbolo químico 'O' representa o Oxigênio — o ouro é 'Au'.",
        "age_reviewed": True,
        "hints": ["É essencial para respirarmos.", "Não é o mesmo que o símbolo do ouro."],
    },
    {
        "territory_id": "conhecimento", "difficulty_level": 3,
        "prompt": "Qual é a moeda oficial do Japão?",
        "options": ["Won", "Yuan", "Iene", "Rupia"],
        "correct_answer": "Iene",
        "explanation": "O Iene é a moeda oficial do Japão.",
        "age_reviewed": True,
        "hints": ["Não é a moeda da China nem da Coreia.", "Começa com 'I'."],
    },
    # V2 item 7 — "Conhecimento" tinha 13 (5/5/3) — 2 itens novos abaixo
    # levam a 15 (5/5/5). Território de maior risco de erro/desatualização
    # já registrado desde RISKS_AND_OPEN_DECISIONS.md original — os dois
    # fatos abaixo foram escolhidos de propósito por serem extremamente
    # estáveis (anatomia humana e geografia física não mudam com o tempo,
    # ao contrário de recordes/populações/rankings "atuais"), e o segundo
    # usa o mesmo modelo de 4 oceanos já implícito na pergunta "maior
    # oceano" acima — evita a ambiguidade real de contar ou não o Oceano
    # Antártico/Austral como um 5º oceano (classificação que varia por
    # fonte/currículo, não um fato fechado).
    {
        "territory_id": "conhecimento", "difficulty_level": 3,
        "prompt": "Qual é o menor osso do corpo humano?",
        "options": ["Estribo", "Fêmur", "Rádio", "Fíbula"],
        "correct_answer": "Estribo",
        "explanation": "O estribo fica no ouvido médio e é o menor osso do corpo humano, com cerca de 3 milímetros.",
        "age_reviewed": True,
        "hints": ["Fica dentro do ouvido.", "Tem esse nome porque lembra o objeto que apoia o pé de quem monta a cavalo."],
    },
    {
        "territory_id": "conhecimento", "difficulty_level": 3,
        "prompt": "Qual destes é o oceano mais frio?",
        "options": ["Ártico", "Atlântico", "Pacífico", "Índico"],
        "correct_answer": "Ártico",
        "explanation": "O Oceano Ártico fica coberto de gelo boa parte do ano e tem a temperatura média mais baixa entre os quatro.",
        "age_reviewed": True,
        "hints": ["Fica na região do Polo Norte.", "Está sempre coberto de gelo, pelo menos em parte."],
    },

    # Enigmas — charadas clássicas "o que é, o que é", curadoria manual
    # (formato múltipla escolha em todas, para evitar falso-negativo de
    # variação de resposta livre que um enigma de resposta aberta causaria
    # — ex.: "relógio" vs "o relógio"). 15 itens, 5 por nível 1-3, mesmo
    # padrão de volume dos outros territórios.
    {
        "territory_id": "enigmas", "difficulty_level": 1,
        "prompt": "O que é, o que é: tem cidade, tem campo, tem estrada, mas não tem casa?",
        "options": ["Mapa", "Globo", "Bússola", "Carro"],
        "correct_answer": "Mapa",
        "explanation": "Um mapa representa cidades, campos e estradas em papel ou tela, mas nenhuma casa de verdade.",
        "age_reviewed": True,
        "hints": ["Você usa para se localizar numa viagem.", "Pode ser de papel ou digital, no celular."],
    },
    {
        "territory_id": "enigmas", "difficulty_level": 1,
        "prompt": "O que é, o que é: quanto mais se tira, maior fica?",
        "options": ["Buraco", "Bolo", "Dívida", "Sombra"],
        "correct_answer": "Buraco",
        "explanation": "Cavar um buraco significa tirar terra — quanto mais terra você tira, maior o buraco fica.",
        "age_reviewed": True,
        "hints": ["Pense em alguém cavando a terra.", "É o oposto de um monte."],
    },
    {
        "territory_id": "enigmas", "difficulty_level": 1,
        "prompt": "O que é, o que é: tem boca mas não fala, tem leito mas não dorme?",
        "options": ["Rio", "Vulcão", "Vale", "Poço"],
        "correct_answer": "Rio",
        "explanation": "Um rio tem 'boca' (onde deságua) e 'leito' (o caminho por onde a água passa), mas não fala nem dorme.",
        "age_reviewed": True,
        "hints": ["A água corre dentro dele.", "Pode desaguar no mar."],
    },
    {
        "territory_id": "enigmas", "difficulty_level": 1,
        "prompt": "O que é, o que é: você o quebra só de falar o nome dele?",
        "options": ["Silêncio", "Vidro", "Segredo", "Recorde"],
        "correct_answer": "Silêncio",
        "explanation": "No instante em que você diz a palavra 'silêncio' em voz alta, o silêncio deixa de existir.",
        "age_reviewed": True,
        "hints": ["É a ausência de som.", "Uma biblioteca costuma pedir isso."],
    },
    {
        "territory_id": "enigmas", "difficulty_level": 1,
        "prompt": "O que é, o que é: tem dentes mas não morde?",
        "options": ["Pente", "Serrote", "Tubarão", "Zíper"],
        "correct_answer": "Pente",
        "explanation": "Um pente tem 'dentes' (as pontas finas), mas serve para arrumar o cabelo, não para morder.",
        "age_reviewed": True,
        "hints": ["Você usa para pentear o cabelo.", "Fica no banheiro ou na bolsa."],
    },
    {
        "territory_id": "enigmas", "difficulty_level": 2,
        "prompt": "O que é, o que é: quanto mais você seca, mais molhado fica?",
        "options": ["Toalha", "Guarda-chuva", "Esponja", "Sabonete"],
        "correct_answer": "Toalha",
        "explanation": "A toalha absorve a água de quem ela seca, e por isso ela mesma fica cada vez mais molhada.",
        "age_reviewed": True,
        "hints": ["Você usa depois do banho.", "Fica pendurada perto do chuveiro."],
    },
    {
        "territory_id": "enigmas", "difficulty_level": 2,
        "prompt": "O que é, o que é: todo mundo tem, ninguém pode perder de vez — se perder, morre?",
        "options": ["Vida", "Dinheiro", "Memória", "Paciência"],
        "correct_answer": "Vida",
        "explanation": "Todo ser vivo tem vida, e perdê-la significa morrer — não há como 'recuperar' depois.",
        "age_reviewed": True,
        "hints": ["É o oposto de morte.", "Médicos trabalham para preservar isso."],
    },
    {
        "territory_id": "enigmas", "difficulty_level": 2,
        "prompt": "O que é, o que é: sobe e desce o tempo todo, mas nunca sai do lugar?",
        "options": ["Escada", "Elevador", "Termômetro", "Balanço"],
        "correct_answer": "Escada",
        "explanation": "As pessoas sobem e descem por uma escada várias vezes, mas a escada em si fica sempre fixa no mesmo lugar.",
        "age_reviewed": True,
        "hints": ["Tem degraus.", "Pode ser rolante ou fixa."],
    },
    {
        "territory_id": "enigmas", "difficulty_level": 2,
        "prompt": "O que é, o que é: tem coroa mas não é rei, tem folhas mas não é livro?",
        "options": ["Árvore", "Coroa de flores", "Abacaxi", "Calendário"],
        "correct_answer": "Árvore",
        "explanation": "A parte de cima de uma árvore é chamada de 'copa' ou 'coroa', e ela tem folhas — mas não é realeza nem um livro.",
        "age_reviewed": True,
        "hints": ["Tem tronco, galhos e raízes.", "Dá sombra num dia de sol."],
    },
    {
        "territory_id": "enigmas", "difficulty_level": 2,
        "prompt": "O que é, o que é: quanto mais você me usa, mais fino eu fico, até desaparecer?",
        "options": ["Sabonete", "Lápis", "Vela", "Pilha"],
        "correct_answer": "Sabonete",
        "explanation": "A cada banho, o sabonete perde um pouco de massa e vai ficando cada vez mais fino.",
        "age_reviewed": True,
        "hints": ["Você usa no banho.", "Faz espuma com água."],
    },
    {
        "territory_id": "enigmas", "difficulty_level": 3,
        "prompt": "O que é, o que é: nasce com a luz do sol, mas o próprio sol o apaga ao meio-dia?",
        "options": ["Sombra", "Nuvem", "Reflexo", "Orvalho"],
        "correct_answer": "Sombra",
        "explanation": "A sombra é criada pela luz do sol bloqueada por um objeto — mas fica quase invisível quando o sol está bem a pino, ao meio-dia.",
        "age_reviewed": True,
        "hints": ["Aparece atrás de você quando há luz forte.", "É escura, mas não é um objeto de verdade."],
    },
    {
        "territory_id": "enigmas", "difficulty_level": 3,
        "prompt": "O que é, o que é: quanto mais eu recebo comida, mais eu cresço — mas se me derem água, eu morro?",
        "options": ["Fogo", "Planta", "Fungo", "Formigueiro"],
        "correct_answer": "Fogo",
        "explanation": "O fogo 'se alimenta' de material combustível e cresce, mas é apagado pela água.",
        "age_reviewed": True,
        "hints": ["Pode ser apagado com um extintor.", "É quente e dá luz."],
    },
    {
        "territory_id": "enigmas", "difficulty_level": 3,
        "prompt": "O que é, o que é: só sobe e nunca desce, mesmo contra a sua vontade?",
        "options": ["Idade", "Elevador", "Pipa", "Maré"],
        "correct_answer": "Idade",
        "explanation": "A idade de uma pessoa aumenta a cada ano que passa e nunca volta atrás.",
        "age_reviewed": True,
        "hints": ["Você ganha um número novo dela todo aniversário.", "Não existe cirurgia que a diminua de verdade."],
    },
    {
        "territory_id": "enigmas", "difficulty_level": 3,
        "prompt": "O que é, o que é: tem uma cabeça e uma cauda, mas não tem corpo nem vida?",
        "options": ["Moeda", "Cometa", "Cobra", "Pipa"],
        "correct_answer": "Moeda",
        "explanation": "Toda moeda tem um lado chamado 'cara' (cabeça) e outro chamado 'coroa', às vezes descrito como 'cauda' em outros idiomas — mas é só um objeto de metal.",
        "age_reviewed": True,
        "hints": ["Você joga para o alto para decidir algo no 'cara ou coroa'.", "É feita de metal e usada para pagar coisas."],
    },
    {
        "territory_id": "enigmas", "difficulty_level": 3,
        "prompt": "O que é, o que é: quanto mais escuro está ao redor, mais fácil é enxergá-lo no céu?",
        "options": ["Estrela", "Nuvem", "Avião", "Arco-íris"],
        "correct_answer": "Estrela",
        "explanation": "As estrelas ficam mais visíveis quanto mais escuro está o céu — por isso se veem melhor longe das luzes da cidade.",
        "age_reviewed": True,
        "hints": ["Você as vê à noite, longe das luzes da cidade.", "O Sol também é uma, mas não conta para esta charada."],
    },

    # Textos — interpretação/inferência, curadoria manual. 15 parágrafos
    # originais e distintos (nenhum reaproveitado ou "quase igual" a outro),
    # 5 por nível de dificuldade: nível 1 (compreensão literal, resposta
    # está explícita no texto), nível 2 (inferência leve — sentimento/
    # situação sugerida por pistas, nunca dita diretamente), nível 3
    # (propósito/tom/contradição — exige ler nas entrelinhas).
    {
        "territory_id": "textos", "difficulty_level": 1,
        "prompt": (
            "Marcos esqueceu o guarda-chuva em casa. Quando saiu do trabalho, "
            "a chuva já caía forte. Ele caminhou até o ponto de ônibus e "
            "chegou em casa completamente encharcado.\n\n"
            "Por que Marcos chegou em casa molhado?"
        ),
        "options": ["Porque esqueceu o guarda-chuva", "Porque caiu no rio", "Porque foi nadar", "Porque tomou banho na rua"],
        "correct_answer": "Porque esqueceu o guarda-chuva",
        "explanation": "O texto diz diretamente, na primeira frase, que Marcos esqueceu o guarda-chuva em casa.",
        "age_reviewed": True,
        "hints": ["A resposta está na primeira frase do texto.", "Pense no que ele esqueceu antes de sair."],
    },
    {
        "territory_id": "textos", "difficulty_level": 1,
        "prompt": (
            "A gata Mimosa dorme quase o dia inteiro, enrolada no sofá da "
            "sala. À noite, porém, ela fica bem ativa: corre pela casa e "
            "caça insetos perto da janela.\n\n"
            "Quando a gata Mimosa fica mais ativa?"
        ),
        "options": ["De manhã", "À tarde", "À noite", "Durante o almoço"],
        "correct_answer": "À noite",
        "explanation": "O texto contrasta o dia (dormindo) com a noite, quando ela 'fica bem ativa'.",
        "age_reviewed": True,
        "hints": ["O texto contrasta dois momentos do dia.", "Procure a palavra 'porém' no texto."],
    },
    {
        "territory_id": "textos", "difficulty_level": 1,
        "prompt": (
            "Dona Alice vende frutas na feira todo sábado de manhã. Ela "
            "chega bem cedo para escolher o melhor lugar e organizar as "
            "bananas, laranjas e mamões na barraca.\n\n"
            "O que Dona Alice vende na feira?"
        ),
        "options": ["Roupas", "Frutas", "Peixes", "Flores"],
        "correct_answer": "Frutas",
        "explanation": "O texto diz diretamente que Dona Alice vende frutas, citando bananas, laranjas e mamões.",
        "age_reviewed": True,
        "hints": ["A resposta está na primeira frase.", "Bananas, laranjas e mamões são exemplos dessa resposta."],
    },
    {
        "territory_id": "textos", "difficulty_level": 1,
        "prompt": (
            "Pedro tem uma prova de matemática amanhã. Depois do jantar, "
            "ele separou o caderno, os exercícios e uma caneta, e foi para "
            "o quarto estudar antes de dormir.\n\n"
            "O que Pedro fez depois do jantar?"
        ),
        "options": ["Foi estudar", "Foi dormir direto", "Assistiu televisão", "Saiu para brincar"],
        "correct_answer": "Foi estudar",
        "explanation": "O texto diz que ele separou o material e 'foi para o quarto estudar'.",
        "age_reviewed": True,
        "hints": ["Veja o que ele separou antes de ir para o quarto.", "A prova de amanhã é o motivo da ação dele."],
    },
    {
        "territory_id": "textos", "difficulty_level": 1,
        "prompt": (
            "A previsão do tempo anunciou chuva forte para a tarde. Antes "
            "de sair de casa, Joana pegou o casaco impermeável e colocou "
            "na mochila, por precaução.\n\n"
            "Por que Joana levou o casaco impermeável?"
        ),
        "options": ["Porque estava frio", "Porque a previsão era de chuva", "Porque ia nadar", "Porque tinha esquecido em casa"],
        "correct_answer": "Porque a previsão era de chuva",
        "explanation": "O texto liga diretamente a ação de Joana à previsão de chuva forte anunciada.",
        "age_reviewed": True,
        "hints": ["Pense no que a previsão do tempo anunciou.", "'Por precaução' se refere a essa previsão."],
    },
    {
        "territory_id": "textos", "difficulty_level": 2,
        "prompt": (
            "Antes da entrevista, Rafael não parava de olhar para o "
            "relógio. Suas mãos estavam suando e ele repetia baixinho as "
            "respostas que havia treinado em casa.\n\n"
            "Como Rafael provavelmente estava se sentindo?"
        ),
        "options": ["Nervoso", "Entediado", "Com sono", "Com raiva"],
        "correct_answer": "Nervoso",
        "explanation": "Nenhuma palavra do texto diz 'nervoso' diretamente — mãos suando, olhar o relógio o tempo todo e repetir respostas são pistas comuns de ansiedade antes de um evento importante.",
        "age_reviewed": True,
        "hints": ["Nenhuma palavra do texto diz diretamente o sentimento — observe as ações dele.", "Mãos suando e repetir respostas são sinais comuns de ansiedade."],
    },
    {
        "territory_id": "textos", "difficulty_level": 2,
        "prompt": (
            "Camila arrumou a mala na noite anterior, imprimiu as "
            "passagens e, na manhã seguinte, se despediu da família com "
            "um abraço apertado no portão de embarque.\n\n"
            "O que está acontecendo com Camila?"
        ),
        "options": ["Ela está indo viajar", "Ela está indo ao mercado", "Ela está mudando de quarto", "Ela está indo ao médico"],
        "correct_answer": "Ela está indo viajar",
        "explanation": "Mala, passagens e 'portão de embarque' são pistas que, juntas, indicam uma viagem — o texto nunca usa a palavra 'viagem'.",
        "age_reviewed": True,
        "hints": ["Mala, passagens e portão de embarque são pistas do mesmo tipo de evento.", "Pense em onde fica um 'portão de embarque'."],
    },
    {
        "territory_id": "textos", "difficulty_level": 2,
        "prompt": (
            "Apesar de ter estudado a semana inteira, Bruno saiu da prova "
            "preocupado, sem conseguir responder duas questões que "
            "considerava simples.\n\n"
            "O que o texto sugere sobre como Bruno se sente em relação à prova?"
        ),
        "options": ["Ele está inseguro sobre o próprio desempenho", "Ele tem certeza de que foi muito bem", "Ele nem fez a prova", "Ele já sabe a nota"],
        "correct_answer": "Ele está inseguro sobre o próprio desempenho",
        "explanation": "'Apesar de' marca um contraste com o esperado, e sair preocupado sem responder questões 'simples' aponta insegurança, não confiança.",
        "age_reviewed": True,
        "hints": ["'Apesar de' indica um contraste com o que se esperava.", "Preocupação depois da prova aponta insegurança, não confiança."],
    },
    {
        "territory_id": "textos", "difficulty_level": 2,
        "prompt": (
            "Suas mãos estavam sempre manchadas de graxa, e o macacão azul "
            "pendurado na oficina já não tinha mais a cor original. O "
            "barulho de parafusos e motores era constante ao redor dele.\n\n"
            "Qual é a profissão mais provável dessa pessoa?"
        ),
        "options": ["Mecânico", "Professor", "Cozinheiro", "Médico"],
        "correct_answer": "Mecânico",
        "explanation": "Graxa, macacão, oficina, parafusos e motores são pistas do ambiente de trabalho de um mecânico, mesmo sem o texto dizer a profissão diretamente.",
        "age_reviewed": True,
        "hints": ["Graxa, macacão e oficina são pistas do ambiente de trabalho.", "Pense em quem trabalha com motores e parafusos."],
    },
    {
        "territory_id": "textos", "difficulty_level": 2,
        "prompt": (
            "Quando os colegas elogiaram sua apresentação, Tiago abaixou a "
            "cabeça, ficou com o rosto vermelho e só conseguiu agradecer "
            "em um sussurro.\n\n"
            "O que as reações de Tiago sugerem?"
        ),
        "options": ["Timidez", "Raiva", "Indiferença", "Tédio"],
        "correct_answer": "Timidez",
        "explanation": "Rosto vermelho, cabeça baixa e responder em sussurro diante de um elogio são reações físicas típicas de timidez.",
        "age_reviewed": True,
        "hints": ["Rosto vermelho e cabeça baixa são reações físicas comuns diante de elogios inesperados.", "Pense em como alguém tímido reage a ser o centro das atenções."],
    },
    {
        "territory_id": "textos", "difficulty_level": 3,
        "prompt": (
            "Experimente o novo suco SaborMax: mais vitaminas, mais sabor, "
            "e agora com 20% de desconto só esta semana. Corra antes que "
            "acabe!\n\n"
            "Qual é o principal objetivo desse texto?"
        ),
        "options": ["Convencer o leitor a comprar o produto", "Explicar como fazer suco em casa", "Avisar sobre um problema no produto", "Contar uma história sobre frutas"],
        "correct_answer": "Convencer o leitor a comprar o produto",
        "explanation": "Desconto por tempo limitado e a urgência de 'corra antes que acabe' são marcas típicas de um texto publicitário, cujo objetivo é persuadir o leitor a comprar.",
        "age_reviewed": True,
        "hints": ["Preço, desconto e urgência ('corra antes que acabe') são típicos de um tipo específico de texto.", "Pense no objetivo comum de um anúncio publicitário."],
    },
    {
        "territory_id": "textos", "difficulty_level": 3,
        "prompt": (
            "Que ótimo, mais uma reunião marcada para as sete da manhã de "
            "segunda-feira — exatamente o jeito perfeito de começar a "
            "semana.\n\n"
            "O que a pessoa realmente quer dizer com esse comentário?"
        ),
        "options": ["Ela está insatisfeita com o horário da reunião", "Ela adora reuniões cedo", "Ela está muito animada com a semana", "Ela não sabia da reunião"],
        "correct_answer": "Ela está insatisfeita com o horário da reunião",
        "explanation": "O tom é irônico — 'que ótimo' e 'jeito perfeito' querem dizer o oposto do que as palavras dizem literalmente.",
        "age_reviewed": True,
        "hints": ["Preste atenção no tom — às vezes 'ótimo' quer dizer o oposto.", "Pense em como as pessoas costumam reagir a reuniões muito cedo."],
    },
    {
        "territory_id": "textos", "difficulty_level": 3,
        "prompt": (
            "Não fiz por querer, professora — o cachorro derrubou minha "
            "mochila na poça d'água bem na hora que eu ia sair de casa, "
            "juro.\n\n"
            "Qual é a intenção mais provável dessa fala?"
        ),
        "options": ["Justificar a lição de casa molhada ou perdida", "Pedir para trocar de escola", "Elogiar o cachorro", "Contar uma piada"],
        "correct_answer": "Justificar a lição de casa molhada ou perdida",
        "explanation": "A fala é dirigida a uma professora, logo antes de algo escolar — o tom de desculpa apressada ('juro') sugere uma justificativa para a lição.",
        "age_reviewed": True,
        "hints": ["A fala é dirigida a uma professora, logo antes de algo relacionado à escola.", "Pense no que normalmente motiva esse tipo de explicação apressada."],
    },
    {
        "territory_id": "textos", "difficulty_level": 3,
        "prompt": (
            "Marina afirmou que não corria havia anos, mas cruzou a linha "
            "de chegada da maratona sem parecer nem um pouco cansada, "
            "sorrindo e ajeitando o cabelo para as fotos.\n\n"
            "O que esse trecho sugere sobre a afirmação de Marina?"
        ),
        "options": ["A afirmação parece contradizer o que aconteceu na corrida", "A afirmação foi totalmente confirmada pelos fatos", "O texto não dá nenhuma pista sobre isso", "Marina desistiu da corrida"],
        "correct_answer": "A afirmação parece contradizer o que aconteceu na corrida",
        "explanation": "Quem realmente não treina há anos dificilmente terminaria uma maratona sorrindo e sem sinais de cansaço — o desempenho descrito contradiz a afirmação inicial.",
        "age_reviewed": True,
        "hints": ["Compare o que Marina disse com o que o texto descreve sobre a chegada dela.", "Alguém que realmente não treina dificilmente terminaria uma maratona sem sinais de cansaço."],
    },
    {
        "territory_id": "textos", "difficulty_level": 3,
        "prompt": (
            "A previsão indicava sol firme o dia todo, mas o céu foi "
            "escurecendo rapidamente enquanto as pessoas ainda estendiam "
            "roupa nos varais dos quintais.\n\n"
            "O que é mais provável que aconteça a seguir?"
        ),
        "options": ["Vai chover, e as roupas correm risco de molhar", "As roupas vão secar mais rápido", "O sol vai voltar imediatamente", "Nada vai mudar no tempo"],
        "correct_answer": "Vai chover, e as roupas correm risco de molhar",
        "explanation": "Céu escurecendo rapidamente, mesmo contra a previsão de sol, é um sinal comum de chuva se aproximando — o que colocaria a roupa no varal em risco.",
        "age_reviewed": True,
        "hints": ["Céu escurecendo rápido geralmente indica mudança de tempo.", "Pense no que normalmente acontece com roupa no varal quando começa a chover."],
    },

    # Visual — mecânica única "ache a figura diferente" (nenhuma imagem
    # real, só ícones vetoriais forma+preenchimento+cor — decisão de
    # armazenamento registrada em TERRITORIES acima). 15 itens, 5 por
    # nível: nível 1 varia a FORMA (diferença óbvia), nível 2 varia a COR
    # (mesma forma/preenchimento), nível 3 varia o PREENCHIMENTO (mesma
    # forma/cor, só preenchida vs. contorno — a diferença mais sutil).
    {
        "territory_id": "visual", "difficulty_level": 1,
        "prompt": "Qual figura é diferente das outras?",
        "options": [
            _visual_option("circle", "filled", "gold", 1),
            _visual_option("circle", "filled", "gold", 2),
            _visual_option("square", "filled", "gold", 3),
            _visual_option("circle", "filled", "gold", 4),
        ],
        "correct_answer": _visual_option("square", "filled", "gold", 3),
        "explanation": "As outras três são círculos dourados preenchidos — o quadrado dourado preenchido é a forma diferente.",
        "age_reviewed": True,
        "hints": ["Compare a forma de cada figura, não a cor.", "Três delas são redondas."],
    },
    {
        "territory_id": "visual", "difficulty_level": 1,
        "prompt": "Encontre a figura que não é igual às outras.",
        "options": [
            _visual_option("heart", "filled", "teal", 1),
            _visual_option("star", "filled", "teal", 2),
            _visual_option("star", "filled", "teal", 3),
            _visual_option("star", "filled", "teal", 4),
        ],
        "correct_answer": _visual_option("heart", "filled", "teal", 1),
        "explanation": "As outras três são estrelas verde-azuladas preenchidas — o coração é a forma diferente.",
        "age_reviewed": True,
        "hints": ["Todas têm a mesma cor — olhe só para o contorno da forma.", "Três delas têm pontas; uma não tem."],
    },
    {
        "territory_id": "visual", "difficulty_level": 1,
        "prompt": "Qual das quatro figuras não pertence ao grupo?",
        "options": [
            _visual_option("square", "filled", "error", 1),
            _visual_option("circle", "filled", "error", 2),
            _visual_option("square", "filled", "error", 3),
            _visual_option("square", "filled", "error", 4),
        ],
        "correct_answer": _visual_option("circle", "filled", "error", 2),
        "explanation": "As outras três são quadrados terracota preenchidos — o círculo é a forma diferente.",
        "age_reviewed": True,
        "hints": ["Três figuras têm cantos retos; uma não tem.", "Procure a única forma redonda."],
    },
    {
        "territory_id": "visual", "difficulty_level": 1,
        "prompt": "Qual figura é diferente das outras?",
        "options": [
            _visual_option("heart", "filled", "bone", 1),
            _visual_option("heart", "filled", "bone", 2),
            _visual_option("heart", "filled", "bone", 3),
            _visual_option("star", "filled", "bone", 4),
        ],
        "correct_answer": _visual_option("star", "filled", "bone", 4),
        "explanation": "As outras três são corações claros preenchidos — a estrela é a forma diferente.",
        "age_reviewed": True,
        "hints": ["Três figuras têm o mesmo formato de coração.", "Procure a única forma com pontas."],
    },
    {
        "territory_id": "visual", "difficulty_level": 1,
        "prompt": "Encontre a figura que não é igual às outras.",
        "options": [
            _visual_option("heart", "filled", "teal", 1),
            _visual_option("circle", "filled", "teal", 2),
            _visual_option("circle", "filled", "teal", 3),
            _visual_option("circle", "filled", "teal", 4),
        ],
        "correct_answer": _visual_option("heart", "filled", "teal", 1),
        "explanation": "As outras três são círculos verde-azulados preenchidos — o coração é a forma diferente.",
        "age_reviewed": True,
        "hints": ["Três figuras são perfeitamente redondas.", "Procure a única forma com uma reentrância no topo."],
    },
    {
        "territory_id": "visual", "difficulty_level": 2,
        "prompt": "Qual figura tem uma cor diferente das outras?",
        "options": [
            _visual_option("circle", "filled", "teal", 1),
            _visual_option("circle", "filled", "gold", 2),
            _visual_option("circle", "filled", "teal", 3),
            _visual_option("circle", "filled", "teal", 4),
        ],
        "correct_answer": _visual_option("circle", "filled", "gold", 2),
        "explanation": "Todos os círculos têm a mesma forma preenchida — só um deles é dourado, os outros três são verde-azulados.",
        "age_reviewed": True,
        "hints": ["A forma é a mesma em todas — a diferença está só na cor.", "Três círculos têm a mesma cor esverdeada."],
    },
    {
        "territory_id": "visual", "difficulty_level": 2,
        "prompt": "Qual das quatro figuras não pertence ao grupo?",
        "options": [
            _visual_option("square", "filled", "error", 1),
            _visual_option("square", "filled", "teal", 2),
            _visual_option("square", "filled", "teal", 3),
            _visual_option("square", "filled", "teal", 4),
        ],
        "correct_answer": _visual_option("square", "filled", "error", 1),
        "explanation": "Todos os quadrados são preenchidos e do mesmo tamanho — só um deles é terracota, os outros três são verde-azulados.",
        "age_reviewed": True,
        "hints": ["A forma é a mesma em todas — a diferença está só na cor.", "Três quadrados têm a mesma cor esverdeada."],
    },
    {
        "territory_id": "visual", "difficulty_level": 2,
        "prompt": "Encontre a figura que não é igual às outras.",
        "options": [
            _visual_option("star", "filled", "bone", 1),
            _visual_option("star", "filled", "bone", 2),
            _visual_option("star", "filled", "gold", 3),
            _visual_option("star", "filled", "bone", 4),
        ],
        "correct_answer": _visual_option("star", "filled", "gold", 3),
        "explanation": "Todas as estrelas são preenchidas com o mesmo formato — só uma delas é dourada, as outras três são claras.",
        "age_reviewed": True,
        "hints": ["A forma é a mesma em todas — a diferença está só na cor.", "Três estrelas têm a mesma cor clara."],
    },
    {
        "territory_id": "visual", "difficulty_level": 2,
        "prompt": "Qual figura tem uma cor diferente das outras?",
        "options": [
            _visual_option("heart", "filled", "error", 1),
            _visual_option("heart", "filled", "error", 2),
            _visual_option("heart", "filled", "error", 3),
            _visual_option("heart", "filled", "bone", 4),
        ],
        "correct_answer": _visual_option("heart", "filled", "bone", 4),
        "explanation": "Todos os corações são preenchidos com o mesmo formato — só um deles é claro, os outros três são terracota.",
        "age_reviewed": True,
        "hints": ["A forma é a mesma em todas — a diferença está só na cor.", "Três corações têm a mesma cor avermelhada."],
    },
    {
        "territory_id": "visual", "difficulty_level": 2,
        "prompt": "Qual das quatro figuras não pertence ao grupo?",
        "options": [
            _visual_option("circle", "filled", "error", 1),
            _visual_option("circle", "filled", "bone", 2),
            _visual_option("circle", "filled", "bone", 3),
            _visual_option("circle", "filled", "bone", 4),
        ],
        "correct_answer": _visual_option("circle", "filled", "error", 1),
        "explanation": "Todos os círculos são preenchidos do mesmo tamanho — só um deles é terracota, os outros três são claros.",
        "age_reviewed": True,
        "hints": ["A forma é a mesma em todas — a diferença está só na cor.", "Três círculos têm a mesma cor clara."],
    },
    {
        "territory_id": "visual", "difficulty_level": 3,
        "prompt": "Qual figura é diferente das outras — repare bem no detalhe.",
        "options": [
            _visual_option("circle", "filled", "gold", 1),
            _visual_option("circle", "outline", "gold", 2),
            _visual_option("circle", "filled", "gold", 3),
            _visual_option("circle", "filled", "gold", 4),
        ],
        "correct_answer": _visual_option("circle", "outline", "gold", 2),
        "explanation": "Todos os círculos são dourados e do mesmo tamanho — só um deles é apenas o contorno, sem preenchimento.",
        "age_reviewed": True,
        "hints": ["A forma e a cor são iguais em todas — olhe se a figura está totalmente pintada.", "Uma delas é só a borda, vazia por dentro."],
    },
    {
        "territory_id": "visual", "difficulty_level": 3,
        "prompt": "Encontre a figura que não é igual às outras — repare bem no detalhe.",
        "options": [
            _visual_option("square", "outline", "teal", 1),
            _visual_option("square", "outline", "teal", 2),
            _visual_option("square", "filled", "teal", 3),
            _visual_option("square", "outline", "teal", 4),
        ],
        "correct_answer": _visual_option("square", "filled", "teal", 3),
        "explanation": "Todos os quadrados são verde-azulados e do mesmo tamanho — só um deles está totalmente preenchido, os outros três são só contorno.",
        "age_reviewed": True,
        "hints": ["A forma e a cor são iguais em todas — olhe se a figura está totalmente pintada.", "Três delas são só a borda, vazias por dentro."],
    },
    {
        "territory_id": "visual", "difficulty_level": 3,
        "prompt": "Qual das quatro figuras não pertence ao grupo — repare bem no detalhe.",
        "options": [
            _visual_option("star", "filled", "error", 1),
            _visual_option("star", "filled", "error", 2),
            _visual_option("star", "outline", "error", 3),
            _visual_option("star", "filled", "error", 4),
        ],
        "correct_answer": _visual_option("star", "outline", "error", 3),
        "explanation": "Todas as estrelas são terracota e do mesmo tamanho — só uma delas é apenas o contorno, sem preenchimento.",
        "age_reviewed": True,
        "hints": ["A forma e a cor são iguais em todas — olhe se a figura está totalmente pintada.", "Uma delas é só a borda, vazia por dentro."],
    },
    {
        "territory_id": "visual", "difficulty_level": 3,
        "prompt": "Qual figura é diferente das outras — repare bem no detalhe.",
        "options": [
            _visual_option("heart", "outline", "bone", 1),
            _visual_option("heart", "filled", "bone", 2),
            _visual_option("heart", "outline", "bone", 3),
            _visual_option("heart", "outline", "bone", 4),
        ],
        "correct_answer": _visual_option("heart", "filled", "bone", 2),
        "explanation": "Todos os corações são claros e do mesmo tamanho — só um deles está totalmente preenchido, os outros três são só contorno.",
        "age_reviewed": True,
        "hints": ["A forma e a cor são iguais em todas — olhe se a figura está totalmente pintada.", "Três delas são só a borda, vazias por dentro."],
    },
    {
        "territory_id": "visual", "difficulty_level": 3,
        "prompt": "Encontre a figura que não é igual às outras — repare bem no detalhe.",
        "options": [
            _visual_option("circle", "outline", "teal", 1),
            _visual_option("circle", "outline", "teal", 2),
            _visual_option("circle", "outline", "teal", 3),
            _visual_option("circle", "filled", "teal", 4),
        ],
        "correct_answer": _visual_option("circle", "filled", "teal", 4),
        "explanation": "Todos os círculos são verde-azulados e do mesmo tamanho — só um deles está totalmente preenchido, os outros três são só contorno.",
        "age_reviewed": True,
        "hints": ["A forma e a cor são iguais em todas — olhe se a figura está totalmente pintada.", "Três delas são só a borda, vazias por dentro."],
    },
]


def seed_if_empty(db: Session) -> None:
    if db.query(models.Territory).count() > 0:
        return

    for w in WORLDS:
        db.add(models.World(**w))
    db.commit()

    for t in TERRITORIES:
        db.add(models.Territory(**t))
    db.commit()

    for c in CHALLENGES:
        # Nunca mutar os dicts de CHALLENGES (ex.: c.pop("hints")) — é uma
        # lista de dados declarativos, importada e inspecionada em outros
        # lugares (ex.: tests/test_content_volume.py, tests conferindo
        # correct_answer contra o seed). Um .pop() aqui reescreveria o
        # módulo compartilhado pra sempre no processo, quebrando qualquer
        # código que leia CHALLENGES depois do primeiro seed — achado real
        # implementando o item 7 (o teste de volume de conteúdo via
        # asserção em challenge["hints"] falhava com KeyError sempre que
        # rodava depois de algum teste que já tivesse acionado o seed).
        hints = c["hints"]
        challenge = models.Challenge(**{k: v for k, v in c.items() if k != "hints"})
        db.add(challenge)
        db.commit()
        db.refresh(challenge)
        for level, content in enumerate(hints, start=1):
            db.add(models.ChallengeHint(challenge_id=challenge.id, hint_level=level, content=content))
        db.commit()

    for b in BADGES:
        db.add(models.Badge(**b))
    db.commit()
