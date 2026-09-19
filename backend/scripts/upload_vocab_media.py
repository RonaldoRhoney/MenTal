"""
MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md (19/09/2026, pedido de Rhoney)
— sobe 1 imagem de vocabulário (gerada via Canva, cor da identidade do
MENTAL) pro bucket público `vocab-media` do Supabase Storage e grava a
URL final em `Challenge.vocab_media_url/type/source_name/source_url`
(tudo-ou-nada, content_validation.py) pro Desafio casado por
(territory_id, prompt).

Uso:
    export MENTAL_DATABASE_URL="postgresql+psycopg://..."
    export SUPABASE_URL="https://<projeto>.supabase.co"
    export SUPABASE_SERVICE_ROLE_KEY="..."
    cd backend && python3 scripts/upload_vocab_media.py <territory_id> <trecho_do_prompt> <caminho_local_imagem> <fonte_url_canva>

`trecho_do_prompt` é uma busca parcial (ILIKE) — não precisa ser o
prompt inteiro. Se achar mais de 1 Desafio, lista os candidatos e não
faz upload nenhum (rode de novo com um trecho mais específico).

Idempotente: rodar de novo pro MESMO Desafio só sobrescreve a mesma
URL (x-upsert=true no Storage).
"""

import sys

sys.path.insert(0, ".")

from app import models, supabase_admin  # noqa: E402
from app.db import SessionLocal  # noqa: E402

BUCKET = "vocab-media"


def main() -> None:
    if len(sys.argv) != 5:
        print("Uso: python3 scripts/upload_vocab_media.py <territory_id> <trecho_do_prompt> <caminho_imagem> <fonte_url_canva>")
        sys.exit(1)

    territory_id, prompt_snippet, image_path, source_url = sys.argv[1:5]

    with open(image_path, "rb") as f:
        content = f.read()
    ext = image_path.rsplit(".", 1)[-1].lower()
    content_type = {"webp": "image/webp", "png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg"}.get(ext, "application/octet-stream")

    with SessionLocal() as db:
        candidates = (
            db.query(models.Challenge)
            .filter(models.Challenge.territory_id == territory_id, models.Challenge.prompt.ilike(f"%{prompt_snippet}%"))
            .all()
        )
        if len(candidates) != 1:
            print(f"❌ {len(candidates)} desafio(s) encontrado(s) pra {prompt_snippet!r} em {territory_id!r} (precisa ser exatamente 1):")
            for c in candidates:
                print(f"   - {c.prompt!r} (correct_answer={c.correct_answer!r})")
            sys.exit(1)
        challenge = candidates[0]

        supabase_admin.ensure_public_bucket(BUCKET)
        storage_path = f"{territory_id}/{challenge.id}.{ext}"
        url = supabase_admin.upload_public_object(BUCKET, storage_path, content, content_type)
        if url is None:
            print("❌ Upload falhou — confira SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY.")
            sys.exit(1)

        challenge.vocab_media_url = url
        challenge.vocab_media_type = "image"
        challenge.vocab_media_source_name = "Ilustração gerada via Canva AI (MENTAL)"
        challenge.vocab_media_source_url = source_url
        db.commit()

        print(f"✅ {territory_id} / {challenge.prompt!r} → {url}")


if __name__ == "__main__":
    main()
