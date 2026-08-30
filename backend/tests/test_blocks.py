"""
BLOCOS_MENUS.md (aprovado 2026-08-23): Bloco é organização de menu pura —
nunca progressão/conquista (isso continua em World). Números e Lógica
entram no Bloco "Matemática"; os demais territórios existentes
(Palavras, Textos, Enigmas, Visual, Conhecimento) ficam sem bloco.
"""

import uuid

from .conftest import auth_header


def test_progress_includes_matematica_block_with_numeros_e_logica(client):
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get("/progress", headers=headers).json()
    blocks = {b["block_id"]: b for b in body["blocks"]}

    assert "matematica" in blocks
    assert sorted(blocks["matematica"]["territory_ids"]) == ["logica", "numeros"]
    assert blocks["matematica"]["name"] == "Matemática"


def test_blocks_without_any_territory_are_not_returned(client):
    """"Mundo" existe como linha (BLOCOS_MENUS.md §3, conteúdo por curar)
    mas não tem território ainda — não deve aparecer na resposta pra não
    virar um menu vazio sem nada pra abrir. "regioes" passou a ter
    território a partir da V3.0 (V3.0_ESPORTES_REGIOES_CULTURA_POP.md);
    "enem"/"concursos"/"mitologia" passaram a ter território a partir da
    V3.1 (V3.1_MITOLOGIA_ENEM_CONCURSOS.md); "tecnologia" a partir da
    V3.2 (V3.2_TECNOLOGIA.md) — todos aparecem normalmente agora."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get("/progress", headers=headers).json()
    block_ids = {b["block_id"] for b in body["blocks"]}

    assert block_ids == {
        "matematica", "regioes", "enem", "concursos", "mitologia", "tecnologia",
        "financas_pessoais", "filosofia", "artes", "saude_bemestar",
    }


def test_territories_without_block_are_not_grouped_into_any_block(client):
    """Palavras, Textos, Enigmas, Visual, Conhecimento não entraram em
    nenhum Bloco (BLOCOS_MENUS.md §3) — não podem aparecer no
    territory_ids de nenhum bloco existente."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get("/progress", headers=headers).json()
    all_blocked_territory_ids = {tid for b in body["blocks"] for tid in b["territory_ids"]}

    for unblocked in ("palavras", "textos", "enigmas", "visual", "conhecimento"):
        assert unblocked not in all_blocked_territory_ids


def test_block_grouping_does_not_change_territory_progress_or_worlds(client):
    """BLOCOS_MENUS.md §5: nenhuma mudança na arquitetura de Mundos, XP
    ou badges — blocks é um campo adicional, não substitui nem altera o
    que já existia em territories/worlds."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get("/progress", headers=headers).json()

    assert "territories" in body
    assert "worlds" in body
    territory_ids_in_progress = {t["territory_id"] for t in body["territories"]}
    assert {"numeros", "logica", "palavras"}.issubset(territory_ids_in_progress)
