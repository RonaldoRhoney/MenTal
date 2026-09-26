"""
AGENTE SENTINELA DE CONTEÚDO (AGENTE_SENTINELA_CONTEUDO_V1.md, aprovado por Rhoney,
26/09/2026). Segunda camada de verificação — complementar à checagem humana, nunca
substituta dela.

Fluxo de DOIS NÍVEIS (§4 do documento):
- MECÂNICO (§4.1): só o que não tem ambiguidade — espaços sobrando nas pontas ou duplos
  em texto. Corrigido automaticamente (apply=True) e reportado depois.
- CONTEÚDO (§4.2): qualquer coisa que envolva julgamento (dica que entrega a resposta,
  pergunta repetida no território, resposta dentro do enunciado...). NUNCA é alterado
  aqui: entra na fila de aprovação de Rhoney. Em caso de dúvida na classificação, é
  "conteúdo" — nunca se presume baixo risco.

Limite honesto da V1: este módulo DETECTA e ENFILEIRA. Pesquisar fonte oficial e redigir
a correção proposta (§4.2, passos 2-3) é feito numa sessão do Claude Code a partir do
relatório — o backend não navega na web (custo zero, sem serviço externo).
"""

import re
from dataclasses import dataclass, field

from sqlalchemy import select
from sqlalchemy.orm import Session

from . import models

MECANICO = "mecanico"
CONTEUDO = "conteudo"

# Territórios em que a resposta ser citada no enunciado é o desenho do desafio (cor/figura).
_TERRITORIOS_VISUAIS = {"cores", "visual", "textos"}  # "textos": interpretação, a resposta está na passagem

_MULTI_SPACE = re.compile(r"[ \t]{2,}")


@dataclass
class Finding:
    challenge_id: str
    territory_id: str
    prompt: str
    kind: str
    code: str
    detail: str
    applied: bool = False
    fix: dict = field(default_factory=dict)


def _clean(text: str) -> str:
    return _MULTI_SPACE.sub(" ", text.strip())


def _mechanical(challenge: models.Challenge) -> Finding | None:
    """Espaço sobrando (pontas/duplo) em prompt, alternativas, resposta ou explicação.
    Só gera correção se o resultado continuar consistente (4 alternativas distintas e
    a resposta ainda dentro delas) — senão vira item de conteúdo, não correção."""
    fix: dict = {}
    for attr in ("prompt", "correct_answer", "explanation"):
        value = getattr(challenge, attr) or ""
        cleaned = _clean(value)
        if cleaned != value:
            fix[attr] = cleaned
    options = challenge.options
    if isinstance(options, list):
        cleaned_options = [_clean(o) if isinstance(o, str) else o for o in options]
        if cleaned_options != options:
            fix["options"] = cleaned_options
    if not fix:
        return None
    new_answer = fix.get("correct_answer", challenge.correct_answer)
    new_options = fix.get("options", challenge.options)
    if isinstance(new_options, list) and (len(set(new_options)) != len(new_options) or new_answer not in new_options):
        return Finding(
            str(challenge.id), challenge.territory_id, challenge.prompt, CONTEUDO, "espaco_quebra_consistencia",
            "espaços sobrando, mas limpar deixaria alternativas repetidas ou resposta fora das alternativas",
        )
    return Finding(
        str(challenge.id), challenge.territory_id, challenge.prompt, MECANICO, "espaco_sobrando",
        f"campos com espaço sobrando: {sorted(fix)}", fix=fix,
    )


def _content_findings(challenge: models.Challenge, hints: list[str]) -> list[Finding]:
    out: list[Finding] = []
    cid, tid, prompt = str(challenge.id), challenge.territory_id, challenge.prompt

    def add(code: str, detail: str) -> None:
        out.append(Finding(cid, tid, prompt, CONTEUDO, code, detail))

    answer = (challenge.correct_answer or "").strip()
    options = challenge.options
    if not prompt.strip():
        add("prompt_vazio", "enunciado vazio")
    if not (challenge.explanation or "").strip():
        add("explicacao_vazia", "sem explicação para mostrar após a resposta")
    if isinstance(options, list):
        if len(options) != 4 or len(set(options)) != len(options):
            add("alternativas_invalidas", f"alternativas devem ser 4 distintas (veio {options})")
        elif challenge.correct_answer not in options:
            add("resposta_fora_das_alternativas", f"resposta {answer!r} não está nas alternativas")
        listed = sum(1 for o in options if isinstance(o, str) and o.lower() in prompt.lower())
        # Só é suspeito quando o enunciado cita a resposta e NÃO é um dos padrões legítimos:
        # território de figuras/cores, enunciado que lista as próprias alternativas ("qual
        # item não pertence...") ou texto longo de leitura (a resposta está na passagem).
        if (
            len(answer) >= 6
            and answer.lower() in prompt.lower()
            and challenge.territory_id not in _TERRITORIOS_VISUAIS
            and listed < 2
            and len(prompt) <= 200
        ):
            add("resposta_no_enunciado", f"a resposta {answer!r} aparece no enunciado")
    if len(answer) >= 6:
        for hint in hints:
            if answer.lower() in hint.lower():
                add("dica_entrega_resposta", f"dica cita a resposta {answer!r}")
                break
    return out


def scan(db: Session, territory_ids: list[str] | None = None, apply: bool = False) -> list[Finding]:
    """Varre os desafios (todos ou só dos territórios dados). Com apply=True corrige o
    que é MECÂNICO e marca `applied`; o que é CONTEÚDO nunca é alterado."""
    query = select(models.Challenge)
    if territory_ids is not None:
        query = query.where(models.Challenge.territory_id.in_(territory_ids))
    challenges = db.execute(query).scalars().all()

    hints_by_challenge: dict[str, list[str]] = {}
    ids = [c.id for c in challenges]
    if ids:
        for h in db.execute(select(models.ChallengeHint).where(models.ChallengeHint.challenge_id.in_(ids))).scalars():
            hints_by_challenge.setdefault(str(h.challenge_id), []).append(h.content)

    findings: list[Finding] = []
    seen: dict[tuple[str, str], str] = {}
    for c in challenges:
        mech = _mechanical(c)
        if mech is not None:
            if apply and mech.kind == MECANICO:
                for attr, value in mech.fix.items():
                    setattr(c, attr, value)
                mech.applied = True
            findings.append(mech)
        findings.extend(_content_findings(c, hints_by_challenge.get(str(c.id), [])))
        # Repetida = mesmo enunciado E mesmas alternativas (enunciado igual com alternativas
        # ou figuras diferentes é o desenho normal de territórios como visual/cores).
        opts = tuple(sorted(str(o) for o in c.options)) if isinstance(c.options, list) else ()
        key = (c.territory_id, " ".join((c.prompt or "").lower().split()), opts, c.prompt_image or "")
        if key in seen and key[1]:
            findings.append(Finding(str(c.id), c.territory_id, c.prompt, CONTEUDO, "pergunta_repetida", f"mesmo enunciado do desafio {seen[key]} neste território"))
        else:
            seen[key] = str(c.id)
    if apply and any(f.applied for f in findings):
        db.commit()
    return findings


def render_report(findings: list[Finding], scope: str) -> str:
    """Relatório rastreável (§6): o que foi encontrado, onde, o que foi feito/proposto."""
    mech = [f for f in findings if f.kind == MECANICO]
    fila = [f for f in findings if f.kind == CONTEUDO]
    lines = [
        "# Relatório do Agente Sentinela de Conteúdo",
        "",
        f"Escopo: {scope}",
        f"Correções mecânicas: {len(mech)} ({sum(1 for f in mech if f.applied)} aplicadas) | Fila de aprovação (conteúdo): {len(fila)}",
        "",
        "## Correções mecânicas (baixíssimo risco)",
    ]
    lines += [f"- [{'aplicada' if f.applied else 'pendente'}] {f.territory_id} · {f.prompt[:80]!r} — {f.detail}" for f in mech] or ["- nenhuma"]
    lines += ["", "## Fila de aprovação de Rhoney (nada é alterado sem aprovação)"]
    lines += [f"- {f.territory_id} · {f.prompt[:80]!r} — {f.code}: {f.detail}" for f in fila] or ["- nenhum item"]
    return "\n".join(lines) + "\n"
