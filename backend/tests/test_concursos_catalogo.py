"""
Mundo dos Concursos — catálogo somente leitura (decisão de Rhoney, 25/09/2026).
Só `approved` chega ao app; ficha real exige fonte oficial; nada existente muda.
"""

import uuid

from app import models
from app.db import SessionLocal

from .conftest import auth_header


def _headers(client):
    h = auth_header(str(uuid.uuid4()))
    client.post("/age-gate", json={"age_confirmed": True}, headers=h)
    return h


def _seed():
    tag = uuid.uuid4().hex[:6]
    with SessionLocal() as db:
        db.add(models.ConcursoBanca(id=f"b-{tag}", nome="Banca Teste", perfil="Perfil verificável", review_status="approved"))
        db.add(models.ConcursoBanca(id=f"bp-{tag}", nome="Banca Pendente", review_status="pending"))
        db.add(models.Concurso(id=f"c1-{tag}", esfera="municipal", uf="PE", municipio="Recife", orgao=f"Prefeitura A {tag}",
                               banca_id=f"b-{tag}", status="encerrado", fonte_url="https://exemplo.gov.br/edital", review_status="approved"))
        db.add(models.Concurso(id=f"c2-{tag}", esfera="estadual", uf="SP", orgao=f"Governo B {tag}",
                               status="em_andamento", fonte_url="https://exemplo.gov.br/b", review_status="approved"))
        db.add(models.Concurso(id=f"c3-{tag}", esfera="municipal", uf="PE", municipio="Olinda", orgao=f"Prefeitura C {tag}",
                               status="em_analise", fonte_url="https://exemplo.gov.br/c", review_status="pending"))
        db.add(models.ConcursoDica(id=f"d1-{tag}", concurso_id=f"c1-{tag}", texto="Dica aprovada", review_status="approved"))
        db.add(models.ConcursoDica(id=f"d2-{tag}", concurso_id=f"c1-{tag}", texto="Dica pendente", review_status="pending"))
        db.add(models.ConcursoRevisao(id=f"r1-{tag}", concurso_id=f"c1-{tag}", materia="Português", titulo="Crase", conteudo="Texto", review_status="approved"))
        db.commit()
    return tag


def test_so_o_aprovado_aparece_e_filtros_funcionam(client):
    tag = _seed()
    h = _headers(client)
    todos = {c["id"] for c in client.get("/concursos", headers=h).json()}
    assert f"c1-{tag}" in todos and f"c2-{tag}" in todos and f"c3-{tag}" not in todos  # pendente nunca

    municipais = client.get("/concursos?esfera=municipal", headers=h).json()
    assert f"c1-{tag}" in {c["id"] for c in municipais}
    assert all(c["esfera"] == "municipal" for c in municipais)
    assert client.get("/concursos?esfera=federal&status=em_analise", headers=h).json() == []
    assert client.get("/concursos?uf=sp", headers=h).json()[0]["uf"] == "SP"


def test_detalhe_traz_so_dicas_e_revisoes_aprovadas_e_a_banca_aprovada(client):
    tag = _seed()
    h = _headers(client)
    body = client.get(f"/concursos/c1-{tag}", headers=h).json()
    assert body["banca"]["nome"] == "Banca Teste"
    assert [d["texto"] for d in body["dicas"]] == ["Dica aprovada"]
    assert [r["titulo"] for r in body["revisoes"]] == ["Crase"]
    assert body["fonte_url"].startswith("https://")


def test_concurso_pendente_ou_inexistente_da_404(client):
    tag = _seed()
    h = _headers(client)
    assert client.get(f"/concursos/c3-{tag}", headers=h).status_code == 404
    assert client.get("/concursos/nao-existe", headers=h).status_code == 404


def test_exige_login_e_esfera_invalida_e_rejeitada(client):
    assert client.get("/concursos").status_code == 401
    assert client.get("/concursos?esfera=municipio", headers=_headers(client)).status_code == 422
