"""
MENTAL LINGO (MUNDO/Mundo_dos_Idiomas/Mental_Lingo/MENTAL_LINGO_ASSISTENTE_
VOZ_V1.1.md, aprovado por Rhoney, 23/09/2026 — escopo V1 100% custo zero).
O endpoint só recebe TEXTO já transcrito e responde por consulta direta
ao vocabulário curado — nunca gera texto novo.
"""

import uuid

from app import mental_lingo, models
from app.db import SessionLocal

from .conftest import auth_header


def _seed(prompt: str, correct_answer: str, explanation: str, territory_id: str = "ingles_basico") -> None:
    with SessionLocal() as db:
        db.add(
            models.Challenge(
                territory_id=territory_id,
                difficulty_level=1,
                prompt=prompt,
                options=[correct_answer, "x", "y", "z"],
                correct_answer=correct_answer,
                explanation=explanation,
                age_reviewed=True,
            )
        )
        db.commit()


def _ask(client, question: str):
    headers = auth_header(str(uuid.uuid4()))
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    return client.post("/mental-lingo/ask", json={"question": question}, headers=headers)


def test_pergunta_como_se_escreve_encontra_no_vocabulario_curado(client):
    _seed("Como se escreve 'casa' em inglês?", "House", "'casa' se traduz como 'House' em inglês.")
    resp = _ask(client, "Como se escreve casa em inglês?")
    assert resp.status_code == 200
    data = resp.json()
    assert data["found"] is True
    assert data["target_language"] == "ingles"
    # o jogador já disse "em inglês": a resposta não repete o idioma no final
    assert data["answer_text"] == "'casa' se traduz como 'House'."


def test_pergunta_o_que_significa_busca_nos_3_idiomas_sem_precisar_dizer_qual(client):
    _seed("Como se escreve 'casa' em espanhol?", "Casa", "'casa' se traduz como 'Casa' em espanhol.", territory_id="espanhol_basico")
    resp = _ask(client, "O que significa Casa?")
    assert resp.status_code == 200
    data = resp.json()
    assert data["found"] is True
    # sem idioma na pergunta, reúne todos os idiomas em que a palavra existe no vocabulário
    assert "'Casa' em espanhol" in data["answer_text"]
    assert "espanhol" in [s["lang"] for s in data["speech_segments"]]


def test_palavra_fora_do_vocabulario_responde_honestamente_sem_inventar(client):
    resp = _ask(client, "Como se escreve xilofone em francês?")
    assert resp.status_code == 200
    data = resp.json()
    assert data["found"] is False
    assert "xilofone" in data["answer_text"]


def test_pergunta_sem_padrao_reconhecido_pede_reformulacao(client):
    resp = _ask(client, "oi tudo bem")
    assert resp.status_code == 200
    data = resp.json()
    assert data["found"] is False
    assert data["matched_word"] is None


def test_pergunta_sobre_libras_explica_o_motivo_em_vez_de_erro(client):
    resp = _ask(client, "como se diz obrigado em libras")
    assert resp.status_code == 200
    data = resp.json()
    assert data["found"] is False
    assert "Libras" in data["answer_text"]


def test_pergunta_so_com_espacos_nao_quebra(client):
    resp = _ask(client, "   ")
    assert resp.status_code == 200
    assert resp.json()["found"] is False


def test_palavra_desconhecida_vira_lacuna_agregada_sem_usuario(client):
    _ask(client, "Como se escreve sanfona em francês?")
    _ask(client, "como se escreve sanfona em francês")
    with SessionLocal() as db:
        row = db.get(models.MentalLingoGap, ("sanfona", "frances"))
        assert row is not None and row.times_asked == 2
    # a tabela não tem coluna de usuário (privacidade)
    assert "user_id" not in models.MentalLingoGap.__table__.columns


def test_palavra_conhecida_nao_vira_lacuna(client):
    _seed("Como se escreve 'lápis' em inglês?", "Pencil", "'lápis' se traduz como 'Pencil' em inglês.")
    _ask(client, "como se escreve lápis em inglês")
    with SessionLocal() as db:
        assert db.get(models.MentalLingoGap, ("lápis", "ingles")) is None


def test_palavra_fora_do_vocabulario_usa_fonte_aberta_com_aviso_e_cache(client, monkeypatch):
    calls = []

    def fake(word):
        calls.append(word)
        return ["eraser", "rubber"]

    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", fake)
    data = _ask(client, "como se escreve borracha em inglês").json()
    assert data["found"] is True
    assert "eraser, rubber" in data["answer_text"]
    assert "ainda não revisado" in data["answer_text"]
    assert data["reviewed"] is False and data["suggestion_key"]["word"] == "borracha"
    _ask(client, "como se escreve borracha em inglês")
    assert calls == ["borracha"]  # 2ª vez vem do cache, sem nova consulta externa


def test_sugestao_aprovada_perde_o_aviso_e_rejeitada_nunca_e_servida(client, monkeypatch):
    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", lambda w: ["pencil"])
    _ask(client, "como se escreve grafite em inglês")
    with SessionLocal() as db:
        db.get(models.MentalLingoSuggestion, ("grafite", "ingles")).status = "approved"
        db.commit()
    data = _ask(client, "como se escreve grafite em inglês").json()
    assert data["reviewed"] is True and "ainda não revisado" not in data["answer_text"]
    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", lambda w: ["x"])
    _ask(client, "como se escreve giz em inglês")
    with SessionLocal() as db:
        db.get(models.MentalLingoSuggestion, ("giz", "ingles")).status = "rejected"
        db.commit()
    assert _ask(client, "como se escreve giz em inglês").json()["found"] is False


def test_sem_dado_na_fonte_ou_idioma_sem_par_diz_que_nao_sabe(client, monkeypatch):
    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", lambda w: [])
    assert _ask(client, "como se escreve zzqx em inglês").json()["found"] is False
    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", lambda w: (_ for _ in ()).throw(AssertionError("não devia consultar")))
    assert _ask(client, "como se escreve zzqx em francês").json()["found"] is False


def test_voto_de_utilidade_e_so_contador(client, monkeypatch):
    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", lambda w: ["ruler"])
    _ask(client, "como se escreve régua em inglês")
    headers = auth_header(str(uuid.uuid4()))
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)
    r = client.post("/mental-lingo/feedback", json={"word": "régua", "target_language": "ingles", "useful": False}, headers=headers)
    assert r.json() == {"ok": True}
    with SessionLocal() as db:
        assert db.get(models.MentalLingoSuggestion, ("régua", "ingles")).wrong_votes == 1


def test_resposta_de_vocabulario_vem_com_trechos_por_idioma_pra_voz_nativa(client):
    _seed("Como se escreve 'carro' em inglês?", "Car", "'carro' se traduz como 'Car' em inglês.")
    data = _ask(client, "como se escreve carro em inglês").json()
    assert data["speech_segments"] == [
        {"lang": "pt", "text": "carro se traduz como"},
        {"lang": "ingles", "text": "Car"},
    ]


def test_sugestao_da_fonte_aberta_fala_cada_glosa_em_ingles_e_o_aviso_em_portugues(client, monkeypatch):
    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", lambda w: ["rubber", "eraser"])
    data = _ask(client, "como se escreve borrachinha em inglês").json()
    langs = [(s["lang"], s["text"]) for s in data["speech_segments"]]
    assert langs[0] == ("pt", "borrachinha em inglês pode ser")
    assert ("ingles", "rubber") in langs and ("ingles", "eraser") in langs
    assert langs[-1][0] == "pt" and "não revisado" in langs[-1][1]


def test_build_speech_segments_so_marca_estrangeiro_o_que_e_termo_conhecido():
    from app.mental_lingo import build_speech_segments

    segs = build_speech_segments("'The house is big' usa 'the' antes de 'house'.", "ingles", ["The house is big"])
    assert segs[0] == {"lang": "ingles", "text": "The house is big"}
    assert all(s["lang"] == "pt" for s in segs[1:])  # 'the'/'house' não são termos conhecidos: ficam em pt
    assert build_speech_segments("Sem aspas.", "ingles", ["x"]) == [{"lang": "pt", "text": "Sem aspas."}]


def test_indice_em_memoria_enxerga_conteudo_novo_sem_reiniciar(client, monkeypatch):
    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", lambda w: [])
    # O índice do vocabulário é reconstruído quando o conteúdo muda (carga nova de palavras).
    assert _ask(client, "como se escreve girafa em inglês").json()["found"] is False
    _seed("Como se escreve 'girafa' em inglês?", "Giraffe", "'girafa' se traduz como 'Giraffe' em inglês.")
    data = _ask(client, "como se escreve girafa em inglês").json()
    assert data["found"] is True and data["answer_text"] == "'girafa' se traduz como 'Giraffe'."


def test_varias_opcoes_no_mesmo_idioma_aparecem_juntas(client, monkeypatch):
    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", lambda w: [])
    _seed("Como se escreve 'banco' em inglês?", "Bank", "'banco' se traduz como 'Bank' em inglês.")
    _seed("Como se escreve 'banco' em inglês?", "Bench", "'banco' se traduz como 'Bench' em inglês.", territory_id="ingles_intermediario")
    data = _ask(client, "como se escreve banco em inglês").json()
    assert data["answer_text"] == "'banco' se traduz como 'Bank' ou 'Bench'."
    langs = [(s["lang"], s["text"]) for s in data["speech_segments"]]
    assert ("ingles", "Bank") in langs and ("ingles", "Bench") in langs and ("pt", "ou") in langs


def test_sem_idioma_na_pergunta_mostra_os_tres_idiomas(client, monkeypatch):
    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", lambda w: [])
    _seed("Como se escreve 'leite' em inglês?", "Milk", "'leite' se traduz como 'Milk' em inglês.")
    _seed("Como se escreve 'leite' em espanhol?", "Leche", "'leite' se traduz como 'Leche' em espanhol.", territory_id="espanhol_basico")
    _seed("Como se escreve 'leite' em francês?", "Lait", "'leite' se traduz como 'Lait' em francês.", territory_id="frances_basico")
    data = _ask(client, "o que significa leite").json()
    assert data["answer_text"] == "'leite' se traduz como 'Milk' em inglês, 'Leche' em espanhol e 'Lait' em francês."
    assert [s["lang"] for s in data["speech_segments"] if s["lang"] != "pt"] == ["ingles", "espanhol", "frances"]


def test_termo_estrangeiro_com_varios_significados(client, monkeypatch):
    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", lambda w: [])
    _seed("Como se escreve 'leve' em inglês?", "Light", "'leve' se traduz como 'Light' em inglês.")
    _seed("Como se escreve 'luz' em inglês?", "Light", "'luz' se traduz como 'Light' em inglês.", territory_id="ingles_intermediario")
    data = _ask(client, "o que significa Light").json()
    assert data["answer_text"] == "'Light' em inglês significa 'leve' ou 'luz'."


def test_frase_fora_do_vocabulario_devolve_intencao_de_traduzir_no_aparelho(client):
    data = _ask(client, "como eu digo eu quero um café em inglês").json()
    assert data["found"] is False and data["intent"] == "translate"
    assert data["phrase"] == "eu quero um café" and data["target_language"] == "ingles"
    auto = _ask(client, "o que significa I want a coffee").json()
    assert auto["intent"] == "translate_auto" and auto["phrase"] == "I want a coffee"


def test_como_eu_diria_e_reconhecido_como_moldura_de_instrucao_nao_vaza_pro_tradutor(client):
    # MENTAL_LINGO_RELATORIO_TESTES_CAMPO_V1.md §2.2 item 4 (achado em teste real, 27-28/09/2026):
    # "como eu diria X" não batia em nenhum padrão (só formas no infinitivo/imperativo eram
    # reconhecidas), então a frase INTEIRA — incluindo "como eu diria" — vazava pro tradutor do
    # aparelho ("As I would say it's raining..."). "diria"/"falaria" (condicional) agora são
    # reconhecidos como moldura de instrução, com e sem idioma explícito.
    data = _ask(client, "como eu diria está chovendo muito e eu estou no ônibus lotado").json()
    assert data["intent"] == "translate_auto"
    assert data["phrase"] == "está chovendo muito e eu estou no ônibus lotado"
    assert "como eu diria" not in data["phrase"].lower()

    com_idioma = _ask(client, "como eu falaria bom dia em inglês").json()
    assert com_idioma["intent"] == "translate" and com_idioma["target_language"] == "ingles"
    assert com_idioma["phrase"] == "bom dia"


def test_sem_idioma_na_pergunta_o_idioma_continua_na_resposta(client, monkeypatch):
    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", lambda w: [])
    _seed("Como se escreve 'agulha' em inglês?", "Needle", "'agulha' se traduz como 'Needle' em inglês.", territory_id="ingles_avancado")
    data = _ask(client, "o que significa agulha").json()
    assert data["answer_text"].endswith("'Needle' em inglês.")


def _seed_example(word, sentence, translation, nivel="basico", word_pt=None, status="approved"):
    with SessionLocal() as db:
        db.add(models.MentalLingoExample(idioma="ingles", nivel=nivel, palavra=word, palavra_pt=word_pt,
                                         frase=sentence, traducao=translation, review_status=status))
        db.commit()


def test_frase_exemplo_basico_fala_a_traducao_em_portugues(client):
    _seed_example("Cheese", "She puts cheese on the bread.", "Ela põe queijo no pão.", nivel="basico", word_pt="queijo")
    for question in ("use queijo em uma frase", "me dê um exemplo com Cheese", "como uso cheese", "uma frase com queijo"):
        data = _ask(client, question).json()
        assert data["found"] is True, question
        assert "She puts cheese on the bread." in data["answer_text"] and "Ela põe queijo no pão." in data["answer_text"]
        assert data["highlights"] == ["Cheese"]
        assert data["speech_segments"] == [
            {"lang": "pt", "text": "Um exemplo:"},
            {"lang": "ingles", "text": "She puts cheese on the bread."},
            {"lang": "pt", "text": "Ela põe queijo no pão."},
        ], question


def test_frase_exemplo_intermediario_e_avancado_nao_falam_a_traducao(client):
    _seed_example("Deadline", "The deadline is on Friday.", "O prazo final é na sexta-feira.", nivel="intermediario")
    data = _ask(client, "dê um exemplo com deadline").json()
    assert data["found"] is True
    assert [s["lang"] for s in data["speech_segments"]] == ["pt", "ingles"]  # sem a tradução falada
    assert "O prazo final é na sexta-feira." in data["answer_text"]  # mas a tradução aparece na tela


def test_frase_exemplo_so_aprovada_e_sem_cadastro_e_sem_verbete_no_wikcionario_diz_que_nao_tem(client, monkeypatch):
    """Sem frase curada aprovada E sem significado encontrado no Wikcionário
    (fallback de 28/09/2026): mensagem honesta de "ainda não tenho", nenhuma
    frase inventada."""
    monkeypatch.setattr(mental_lingo.wiktionary, "glosses_pt_to_en", lambda word: None)
    _seed_example("Lantern", "The lantern is old.", "O lampião é velho.", status="pending")
    for question in ("use lantern em uma frase", "use xilofonelapistortuosoinexistente em uma frase"):
        data = _ask(client, question).json()
        assert data["found"] is False and "Ainda não tenho uma frase de exemplo" in data["answer_text"]


def test_frase_exemplo_sem_cadastro_mas_com_wikcionario_mostra_significado_nao_inventa_frase(client, monkeypatch):
    """MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md (ajuste 28/09/2026, aprovado por Rhoney):
    palavra fora do banco de exemplos, mas com significado no Wikcionário (fonte
    aberta/gratuita) — responde com o significado em vez de deixar sem resposta,
    mas deixa claro que não é frase-exemplo curada nem revisada."""
    monkeypatch.setattr(
        mental_lingo.wiktionary, "glosses_pt_to_en",
        lambda word: ["hot"] if word == "quente" else None,
    )
    data = _ask(client, "use quente em uma frase").json()
    assert data["found"] is True
    assert "ainda não" in data["answer_text"].lower()
    assert "wikcionário" in data["answer_text"].lower()
    assert "quente" in data["answer_text"].lower()


def test_frase_exemplo_aceita_varias_formas_de_pedir_incluindo_a_palavra_e_o_idioma(client):
    _seed_example("Milk", "I drink milk every morning.", "Eu bebo leite toda manhã.", word_pt="leite")
    for question in (
        "me dê uma frase com a palavra leite em inglês",
        "dê um exemplo com a palavra milk",
        "quero uma frase com leite",
        "faça uma frase com leite em inglês",
        "preciso de um exemplo de milk",
        "use a palavra leite em uma frase",
        "como usar a palavra milk",
        "frase com milk",
    ):
        data = _ask(client, question).json()
        assert data["found"] is True, question
        assert "I drink milk every morning." in data["answer_text"], question


def test_entende_a_pergunta_com_ponto_interrogacao_sem_pontuacao_e_com_preambulos(client, monkeypatch):
    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", lambda w: [])
    _seed("Como se escreve 'queijo' em inglês?", "Cheese", "'queijo' se traduz como 'Cheese' em inglês.")
    perguntas = [
        "como se diz queijo em inglês?",
        "como se diz queijo em inglês.",
        "como se diz queijo em inglês",
        "Como se diz queijo em inglês!",
        "Oi, então você pode me dizer como se escreve queijo em inglês, por favor?",
        "Mental Lingo, como se fala queijo em inglês?",
        "eu gostaria de saber como se diz queijo em inglês.",
        "qual é a palavra para queijo em inglês?",
        "o que é queijo em inglês?",
        "queijo em inglês",
        "traduza queijo para inglês.",
        "o que significa Cheese em inglês?",
        "me diga o que significa cheese",
        "como se diz queijo",
    ]
    for q in perguntas:
        data = _ask(client, q).json()
        assert data["found"] is True, q
        assert "Cheese" in data["answer_text"] or "queijo" in data["answer_text"], q


def test_frase_exemplo_com_preambulo_e_pontuacao(client):
    _seed_example("Milk", "I drink milk every morning.", "Eu bebo leite toda manhã.", word_pt="leite")
    for q in ("Então, me dê uma frase com a palavra leite em inglês, por favor.", "oi lingo você pode usar leite em uma frase?", "Quero um exemplo com milk."):
        data = _ask(client, q).json()
        assert data["found"] is True, q
        assert "I drink milk every morning." in data["answer_text"], q


def test_frase_exemplo_qualquer_forma_de_pedir(client):
    _seed_example("Milk", "I drink milk every morning.", "Eu bebo leite toda manhã.", word_pt="leite")
    _seed_example("Coffee", "My father likes coffee.", "Meu pai gosta de café.", word_pt="café da manhã")
    for q in (
        "crie uma frase em inglês com a palavra leite",
        "Crie uma frase em inglês com a palavra leite.",
        "crie uma frase com leite?",
        "faz um exemplo curto com milk",
        "monte uma frase simples usando a palavra leite em inglês",
        "gostaria de um exemplo em inglês com a palavra milk, por favor",
        "escreva uma sentença com leite",
        "leite em uma frase",
        "use milk numa frase",
        "exemplo com leite",
        "me dá uma frase que tenha a palavra leite",
    ):
        data = _ask(client, q).json()
        assert data["found"] is True, q
        assert "I drink milk every morning." in data["answer_text"], q
    data = _ask(client, "me dê uma frase com café da manhã").json()  # termo com 'da' no meio é preservado
    assert data["found"] is True and "My father likes coffee." in data["answer_text"]


def test_pergunta_de_traducao_com_a_palavra_frase_nao_vira_pedido_de_exemplo(client, monkeypatch):
    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", lambda w: [])
    data = _ask(client, "o que significa frase em inglês").json()
    assert "Ainda não tenho uma frase de exemplo" not in data["answer_text"]


def _add_pattern(intent, regex, status="approved"):
    with SessionLocal() as db:
        db.add(models.MentalLingoPattern(intencao=intent, regex=regex, status=status))
        db.commit()


def test_padrao_aprovado_no_banco_passa_a_valer_sem_deploy(client, monkeypatch):
    monkeypatch.setattr("app.wiktionary.glosses_pt_to_en", lambda w: [])
    _seed("Como se escreve 'chuva' em inglês?", "Rain", "'chuva' se traduz como 'Rain' em inglês.")
    pergunta = "chuva na língua de Shakespeare"
    assert _ask(client, pergunta).json()["found"] is False  # ainda não sabe
    _add_pattern("traducao", r"^(.+?)\s+na língua de shakespeare$")
    data = _ask(client, pergunta).json()
    assert data["found"] is True and "Rain" in data["answer_text"]


def test_padrao_de_exemplo_aprendido_e_padrao_pendente_ou_invalido_e_ignorado(client):
    _seed_example("Milk", "I drink milk every morning.", "Eu bebo leite toda manhã.", word_pt="leite")
    _add_pattern("exemplo", r"^situação real com (.+)$")
    _add_pattern("exemplo", r"^me surpreenda com (.+)$", status="pending")  # não aprovado: ignorado
    _add_pattern("exemplo", r"([")  # regex inválida: ignorada, nunca derruba
    ok = _ask(client, "situação real com leite").json()
    assert ok["found"] is True and "I drink milk every morning." in ok["answer_text"]
    assert _ask(client, "me surpreenda com leite").json()["found"] is False


def test_pergunta_nao_entendida_e_registrada_so_agregada_e_sem_dado_pessoal(client):
    for _ in range(2):
        _ask(client, "Bla bla quero um tutorial completo?")
    _ask(client, "meu email é fulano@exemplo.com me ajuda")  # parece dado pessoal: não guarda
    _ask(client, "ligue para 11987654321 agora")  # número longo: não guarda
    with SessionLocal() as db:
        row = db.get(models.MentalLingoUnknownQuestion, "bla bla quero um tutorial completo")
        assert row is not None and row.vezes == 2
        textos = [r.texto for r in db.query(models.MentalLingoUnknownQuestion).all()]
        assert not any("@" in t or "987654321" in t for t in textos)
    assert "user_id" not in models.MentalLingoUnknownQuestion.__table__.columns
