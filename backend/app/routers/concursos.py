"""
Mundo dos Concursos — catálogo (somente leitura). Decisão de Rhoney, 25/09/2026:
ordem Municipais -> Estaduais -> Federais. Só entra o que está `approved`
(revisão humana obrigatória); ficha real exige `fonte_url` oficial.
"""

from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import models, schemas
from ..auth import require_age_confirmed_user_id
from ..db import get_db

router = APIRouter()

Esfera = Literal["municipal", "estadual", "federal"]
Status = Literal["encerrado", "em_andamento", "em_analise"]


def _banca_out(db: Session, banca_id: str | None) -> schemas.ConcursoBancaOut | None:
    if banca_id is None:
        return None
    banca = db.get(models.ConcursoBanca, banca_id)
    if banca is None or banca.review_status != "approved":
        return None
    return schemas.ConcursoBancaOut(id=banca.id, nome=banca.nome, perfil=banca.perfil)


def _concurso_out(db: Session, c: models.Concurso) -> dict:
    return {
        "id": c.id, "esfera": c.esfera, "uf": c.uf, "municipio": c.municipio, "orgao": c.orgao,
        "status": c.status, "edital_url": c.edital_url, "fonte_url": c.fonte_url,
        "banca": _banca_out(db, c.banca_id),
    }


@router.get("/concursos", response_model=list[schemas.ConcursoOut])
def list_concursos(
    esfera: Esfera | None = Query(default=None),
    status: Status | None = Query(default=None),
    uf: str | None = Query(default=None, max_length=2),
    user_id: str = Depends(require_age_confirmed_user_id),
    db: Session = Depends(get_db),
):
    query = select(models.Concurso).where(models.Concurso.review_status == "approved")
    if esfera:
        query = query.where(models.Concurso.esfera == esfera)
    if status:
        query = query.where(models.Concurso.status == status)
    if uf:
        query = query.where(models.Concurso.uf == uf.upper())
    rows = db.execute(query.order_by(models.Concurso.orgao)).scalars().all()
    return [schemas.ConcursoOut(**_concurso_out(db, c)) for c in rows]


@router.get("/concursos/{concurso_id}", response_model=schemas.ConcursoDetalheOut)
def get_concurso(concurso_id: str, user_id: str = Depends(require_age_confirmed_user_id), db: Session = Depends(get_db)):
    c = db.get(models.Concurso, concurso_id)
    if c is None or c.review_status != "approved":
        raise HTTPException(status_code=404, detail="Concurso não encontrado")
    dicas = db.execute(
        select(models.ConcursoDica)
        .where(models.ConcursoDica.review_status == "approved")
        .where((models.ConcursoDica.concurso_id == c.id) | ((models.ConcursoDica.banca_id == c.banca_id) & (c.banca_id is not None)))
    ).scalars().all()
    revisoes = db.execute(
        select(models.ConcursoRevisao)
        .where(models.ConcursoRevisao.review_status == "approved")
        .where(models.ConcursoRevisao.concurso_id == c.id)
    ).scalars().all()
    return schemas.ConcursoDetalheOut(
        **_concurso_out(db, c),
        dicas=[schemas.ConcursoDicaOut(id=d.id, texto=d.texto) for d in dicas],
        revisoes=[schemas.ConcursoRevisaoOut(id=r.id, materia=r.materia, titulo=r.titulo, conteudo=r.conteudo) for r in revisoes],
    )
