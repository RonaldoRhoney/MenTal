"""
Consulta ao Wikcionário em inglês (en.wiktionary.org) — fonte ABERTA, gratuita,
sem chave nem cobrança (regra de custo zero), usada pelo MENTAL LINGO só como
SUGESTÃO NÃO REVISADA (aprovado por Rhoney, 25/09/2026). Nunca inventa: se a
página/seção não existir ou não tiver o dado, devolve None.

Escopo honesto: só Português -> Inglês (a seção "Portuguese" da página da
palavra define em inglês, sentido a sentido). A direção inversa foi testada e
descartada por veracidade: as traduções `{{t|pt|...}}` da página inglesa misturam
sentidos (ex.: "house" devolvia "armazenar", sentido de verbo). Espanhol/Francês
não têm par direto com Português aqui — ficam sem sugestão.
"""

import re

import httpx

API = "https://en.wiktionary.org/w/api.php"
HEADERS = {"User-Agent": "MENTAL-app/1.0 (vocabulary assistant; contato: rhoneyinc@gmail.com)"}
TIMEOUT = 4.0

_SECTION_END = re.compile(r"\n==[^=]")


def _fetch_wikitext(title: str) -> str | None:
    try:
        resp = httpx.get(
            API,
            params={"action": "query", "prop": "revisions", "rvprop": "content", "rvslots": "main",
                    "titles": title, "format": "json", "formatversion": 2},
            headers=HEADERS,
            timeout=TIMEOUT,
        )
        resp.raise_for_status()
        pages = resp.json()["query"]["pages"]
        page = pages[0]
        if page.get("missing"):
            return None
        return page["revisions"][0]["slots"]["main"]["content"]
    except Exception:
        return None


def _section(wikitext: str, language: str) -> str | None:
    start = wikitext.find(f"\n=={language}==")
    if start == -1:
        if wikitext.startswith(f"=={language}=="):
            start = 0
        else:
            return None
    rest = wikitext[start + 1:]
    m = _SECTION_END.search(rest, len(language) + 4)
    return rest[: m.start()] if m else rest


def _clean_gloss(line: str) -> str:
    text = re.sub(r"\{\{[^{}]*\}\}", "", line)
    text = re.sub(r"\[\[(?:[^\]|]*\|)?([^\]]*)\]\]", r"\1", text)
    text = text.replace("''", "").replace("'''", "").lstrip("# ").strip(" ;,.")
    return text


def glosses_pt_to_en(word: str) -> list[str]:
    wikitext = _fetch_wikitext(word)
    section = _section(wikitext, "Portuguese") if wikitext else None
    if not section:
        return []
    out: list[str] = []
    for line in section.split("\n"):
        if line.startswith("# ") and not line.startswith(("#:", "#*")):
            gloss = _clean_gloss(line)
            if gloss and len(gloss) <= 40 and gloss not in out:
                out.append(gloss)
    return out[:2]
