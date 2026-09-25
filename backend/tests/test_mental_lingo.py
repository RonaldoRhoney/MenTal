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
