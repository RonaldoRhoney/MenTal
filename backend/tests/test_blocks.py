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


def test_internet_block_groups_its_5_territories_under_tecnologia_world(client):
    """ARQUITETURA_SUBMUNDOS_V1.md (13/09/2026, aprovado): "Internet" é
    SubMundo de "Tecnologia" — implementado reaproveitando o mecanismo
    de Bloco já existente, em vez de uma entidade "SubMundo" nova.
    world_id continua "tecnologia" pros territórios; block_id "internet"
    (diferente do block_id "tecnologia" dos 4 territórios clássicos) é
    o que cria o subcabeçalho separado na tela do Mundo. 5 territórios,
    1 por bloco curado — curadoria completa em 13/09/2026."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get("/progress", headers=headers).json()
    blocks = {b["block_id"]: b for b in body["blocks"]}

    assert "internet" in blocks
    assert sorted(blocks["internet"]["territory_ids"]) == [
        "internet_cultura", "internet_futuro", "internet_gigantes", "internet_origens", "internet_sistemas_operacionais",
    ]
    assert blocks["internet"]["name"] == "Internet"

    worlds = {w["world_id"]: w for w in body["worlds"]}
    assert {
        "internet_origens", "internet_sistemas_operacionais", "internet_gigantes", "internet_cultura", "internet_futuro",
    }.issubset(set(worlds["tecnologia"]["territory_ids"]))


def test_copa_do_mundo_block_groups_its_4_curated_territories_under_esportes_world(client):
    """MUNDO_ESPORTES_ARQUITETURA_V1.md — mesmo padrão do SubMundo
    Internet: os 4 blocos do SubMundo Copa do Mundo, curadoria completa
    em 14/09/2026."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get("/progress", headers=headers).json()
    blocks = {b["block_id"]: b for b in body["blocks"]}

    assert "copa_do_mundo" in blocks
    assert sorted(blocks["copa_do_mundo"]["territory_ids"]) == [
        "copa_mundo_curiosidades", "copa_mundo_era_moderna", "copa_mundo_expansao", "copa_mundo_primeiras_copas",
    ]
    assert blocks["copa_do_mundo"]["name"] == "Copa do Mundo"

    worlds = {w["world_id"]: w for w in body["worlds"]}
    assert {
        "copa_mundo_primeiras_copas", "copa_mundo_expansao", "copa_mundo_era_moderna", "copa_mundo_curiosidades",
    }.issubset(set(worlds["esportes"]["territory_ids"]))


def test_futebol_block_groups_its_4_curated_territories_under_esportes_world(client):
    """MUNDO_ESPORTES_ARQUITETURA_V1.md — SubMundo Futebol, curadoria
    completa em 14/09/2026 (mesmo padrão de Copa do Mundo acima)."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get("/progress", headers=headers).json()
    blocks = {b["block_id"]: b for b in body["blocks"]}

    assert "futebol" in blocks
    assert sorted(blocks["futebol"]["territory_ids"]) == [
        "futebol_atualidade", "futebol_grandes_nomes", "futebol_origens", "futebol_regras_curiosidades",
    ]
    assert blocks["futebol"]["name"] == "Futebol"

    worlds = {w["world_id"]: w for w in body["worlds"]}
    assert {
        "futebol_origens", "futebol_grandes_nomes", "futebol_regras_curiosidades", "futebol_atualidade",
    }.issubset(set(worlds["esportes"]["territory_ids"]))


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
        "financas_pessoais", "filosofia", "artes", "saude_bemestar", "curiosidade_relampago", "libras",
        "jogos_de_palavras", "internet", "copa_do_mundo", "futebol", "ingles", "espanhol", "frances",
    }


def test_idiomas_ingles_espanhol_frances_blocks_group_their_3_territories_each(client):
    """ORGANIZACAO_VISUAL_POR_SECAO_TODOS_MUNDOS_V1.md (19/09/2026,
    aprovado) — levantamento mostrou que Inglês/Espanhol/Francês eram os
    únicos territórios do Mundo dos Idiomas sem block_id, misturados
    numa grade sem separação (diferente de Libras, já bloco próprio
    desde sempre). migrations/080_blocos_idiomas.sql."""
    user = str(uuid.uuid4())
    headers = auth_header(user)
    client.post("/age-gate", json={"age_confirmed": True}, headers=headers)

    body = client.get("/progress", headers=headers).json()
    blocks = {b["block_id"]: b for b in body["blocks"]}

    assert sorted(blocks["ingles"]["territory_ids"]) == ["ingles_avancado", "ingles_basico", "ingles_intermediario"]
    assert sorted(blocks["espanhol"]["territory_ids"]) == ["espanhol_avancado", "espanhol_basico", "espanhol_intermediario"]
    assert sorted(blocks["frances"]["territory_ids"]) == ["frances_avancado", "frances_basico", "frances_intermediario"]
    assert blocks["ingles"]["name"] == "Inglês"
    assert blocks["espanhol"]["name"] == "Espanhol"
    assert blocks["frances"]["name"] == "Francês"

    worlds = {w["world_id"]: w for w in body["worlds"]}
    assert {
        "ingles_basico", "ingles_intermediario", "ingles_avancado",
        "espanhol_basico", "espanhol_intermediario", "espanhol_avancado",
        "frances_basico", "frances_intermediario", "frances_avancado",
    }.issubset(set(worlds["idiomas"]["territory_ids"]))


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
