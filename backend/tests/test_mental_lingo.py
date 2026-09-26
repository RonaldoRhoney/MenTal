"""
MENTAL LINGO (MUNDO/Mundo_dos_Idiomas/Mental_Lingo/MENTAL_LINGO_ASSISTENTE_
VOZ_V1.1.md, aprovado por Rhoney, 23/09/2026 — escopo V1 100% custo zero).
O endpoint só recebe TEXTO já transcrito e responde por consulta direta
ao vocabulário curado — nunca gera texto novo.
"""

import uuid

from app import models
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
    assert data["answer_text"] == "'casa' se traduz como 'House' em inglês."


def test_pergunta_o_que_significa_busca_nos_3_idiomas_sem_precisar_dizer_qual(client):
    _seed("Como se escreve 'casa' em espanhol?", "Casa", "'casa' se traduz como 'Casa' em espanhol.", territory_id="espanhol_basico")
    resp = _ask(client, "O que significa Casa?")
    assert resp.status_code == 200
    data = resp.json()
    assert data["found"] is True
    assert data["target_language"] == "espanhol"


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
        {"lang": "pt", "text": "em inglês"},
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
    assert data["found"] is True and data["answer_text"].endswith("'Giraffe' em inglês.")
