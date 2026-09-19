"""
MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md (19/09/2026, pedido de Rhoney)
— sobe imagem(ns) de vocabulário (geradas via Canva, cor da identidade
do MENTAL) pro bucket público `vocab-media` do Supabase Storage e grava
a URL final em `Challenge.vocab_media_url/type/source_name/source_url`
(tudo-ou-nada, content_validation.py) pro Desafio casado por
(territory_id, prompt).

Uso — 1 imagem por vez:
    export MENTAL_DATABASE_URL="postgresql+psycopg://..."
    export SUPABASE_URL="https://<projeto>.supabase.co"
    export SUPABASE_SERVICE_ROLE_KEY="..."
    cd backend && python3 scripts/upload_vocab_media.py <territory_id> <trecho_do_prompt> <caminho_local_imagem> <fonte_url_canva>

Uso — lote (produção em massa por território):
    python3 scripts/upload_vocab_media.py --manifest scripts/vocab_uploads/<territory_id>.json

O manifesto de lote é uma lista JSON de objetos:
    [{"territory_id": "ingles_basico", "prompt": "Como se escreve 'casa' em inglês?",
      "image_path": "scripts/vocab_images/ingles_basico/casa.webp",
      "source_url": "https://www.canva.com/d/..."}, ...]

`trecho_do_prompt`/`prompt` é uma busca parcial (ILIKE) — não precisa
ser o prompt inteiro, mas precisa achar EXATAMENTE 1 Desafio (senão
lista os candidatos e pula esse item, sem travar o resto do lote).

Idempotente: rodar de novo pro MESMO Desafio só sobrescreve a mesma
URL (x-upsert=true no Storage).
"""

import json
import sys

sys.path.insert(0, ".")

from app import models, supabase_admin  # noqa: E402
from app.db import SessionLocal  # noqa: E402

BUCKET = "vocab-media"


def _content_type_for(path: str) -> str:
    ext = path.rsplit(".", 1)[-1].lower()
    return {"webp": "image/webp", "png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg"}.get(ext, "application/octet-stream")


def _upload_one(db, territory_id: str, prompt_snippet: str, image_path: str, source_url: str) -> bool:
    candidates = (
        db.query(models.Challenge)
        .filter(models.Challenge.territory_id == territory_id, models.Challenge.prompt.ilike(f"%{prompt_snippet}%"))
        .all()
    )
    if len(candidates) != 1:
        print(f"❌ {len(candidates)} desafio(s) pra {prompt_snippet!r} em {territory_id!r} (precisa ser exatamente 1) — pulando:")
        for c in candidates:
            print(f"   - {c.prompt!r} (correct_answer={c.correct_answer!r})")
        return False
    challenge = candidates[0]

    with open(image_path, "rb") as f:
        content = f.read()
    ext = image_path.rsplit(".", 1)[-1].lower()

    supabase_admin.ensure_public_bucket(BUCKET)
    storage_path = f"{territory_id}/{challenge.id}.{ext}"
    url = supabase_admin.upload_public_object(BUCKET, storage_path, content, _content_type_for(image_path))
    if url is None:
        print(f"❌ Upload falhou pra {prompt_snippet!r} — confira SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY.")
        return False

    challenge.vocab_media_url = url
    challenge.vocab_media_type = "image"
    challenge.vocab_media_source_name = "Ilustração gerada via Canva AI (MENTAL)"
    challenge.vocab_media_source_url = source_url
    db.commit()
    print(f"✅ {territory_id} / {challenge.prompt!r} → {url}")
    return True


def main() -> None:
    if len(sys.argv) == 3 and sys.argv[1] == "--manifest":
        with open(sys.argv[2], encoding="utf-8") as f:
            rows = json.load(f)
        ok = 0
        with SessionLocal() as db:
            for row in rows:
                if _upload_one(db, row["territory_id"], row["prompt"], row["image_path"], row["source_url"]):
                    ok += 1
        print(f"\n{ok}/{len(rows)} imagens do lote gravadas com sucesso.")
        return

    if len(sys.argv) != 5:
        print("Uso: python3 scripts/upload_vocab_media.py <territory_id> <trecho_do_prompt> <caminho_imagem> <fonte_url_canva>")
        print("  ou: python3 scripts/upload_vocab_media.py --manifest scripts/vocab_uploads/<territory_id>.json")
        sys.exit(1)

    territory_id, prompt_snippet, image_path, source_url = sys.argv[1:5]
    with SessionLocal() as db:
        if not _upload_one(db, territory_id, prompt_snippet, image_path, source_url):
            sys.exit(1)


if __name__ == "__main__":
    main()
