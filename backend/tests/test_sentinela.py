"""Agente Sentinela de Conteúdo (AGENTE_SENTINELA_CONTEUDO_V1.md): mecânico corrige, conteúdo só enfileira."""

from app import models
from app.db import SessionLocal
from app.sentinela import CONTEUDO, MECANICO, scan


def _add(prompt="Qual a capital do Brasil?", options=None, answer="Brasília", explanation="Brasília é a capital.", hints=None, territory="curiosidades"):
    with SessionLocal() as db:
        c = models.Challenge(
            territory_id=territory, difficulty_level=1, prompt=prompt,
            options=options if options is not None else ["Brasília", "Rio", "São Paulo", "Salvador"],
            correct_answer=answer, explanation=explanation, age_reviewed=True,
        )
        db.add(c)
        db.flush()
        for i, h in enumerate(hints or [], start=1):
            db.add(models.ChallengeHint(challenge_id=c.id, hint_level=i, content=h))
        db.commit()
        return str(c.id)


def _my(findings, cid):
    return [f for f in findings if f.challenge_id == cid]


def test_espaco_sobrando_e_mecanico_e_so_corrige_com_apply(client):
    cid = _add(prompt="  Qual  a capital do Brasil? ")
    with SessionLocal() as db:
        f = _my(scan(db, ["curiosidades"]), cid)
        assert [x.kind for x in f] == [MECANICO] and not f[0].applied
        assert db.get(models.Challenge, cid).prompt == "  Qual  a capital do Brasil? "  # só reportou
        _my(scan(db, ["curiosidades"], apply=True), cid)
        assert db.get(models.Challenge, cid).prompt == "Qual a capital do Brasil?"


def test_limpar_espaco_que_deixaria_alternativas_repetidas_vira_conteudo_nao_correcao(client):
    cid = _add(options=["Rio", "Rio ", "São Paulo", "Brasília"], answer="Brasília")
    with SessionLocal() as db:
        f = _my(scan(db, ["curiosidades"], apply=True), cid)
        assert all(x.kind == CONTEUDO and not x.applied for x in f)
        assert db.get(models.Challenge, cid).options[1] == "Rio "


def test_dica_que_entrega_resposta_e_pergunta_repetida_vao_pra_fila_sem_alterar(client):
    a = _add(hints=["A resposta é Brasília, no Distrito Federal.", "Fica no Planalto Central."])
    b = _add()
    with SessionLocal() as db:
        findings = scan(db, ["curiosidades"], apply=True)
        assert "dica_entrega_resposta" in [x.code for x in _my(findings, a)]
        assert "resposta_no_enunciado" not in [x.code for x in _my(findings, a)]
        assert "pergunta_repetida" in [x.code for x in _my(findings, b)]
        assert all(not x.applied for x in findings if x.kind == CONTEUDO)


def test_resposta_dentro_do_enunciado_e_resposta_fora_das_alternativas(client):
    cid = _add(prompt="Brasília é a capital de qual país?", answer="Brasília")
    cid2 = _add(prompt="Outra pergunta qualquer aqui?", options=["A", "B", "C", "D"], answer="Z")
    with SessionLocal() as db:
        findings = scan(db, ["curiosidades"])
        assert "resposta_no_enunciado" in [x.code for x in _my(findings, cid)]
        assert "resposta_fora_das_alternativas" in [x.code for x in _my(findings, cid2)]


def test_conteudo_limpo_nao_gera_achado(client):
    cid = _add(prompt="Qual cidade foi planejada por Lúcio Costa?", hints=["Fica no Planalto Central.", "É sede do governo federal."])
    with SessionLocal() as db:
        assert _my(scan(db, ["curiosidades"]), cid) == []
