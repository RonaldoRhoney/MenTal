"""
Gera as ilustrações de vocabulário a partir do Twemoji (custo ZERO):
- Fonte: https://github.com/jdecked/twemoji — gráficos sob CC-BY 4.0
  (exige atribuição: gravada em Challenge.vocab_media_source_name/url).
- Só palavras que um emoji representa com fidelidade (twemoji_map.json,
  curado à mão por significado em português); o resto fica sem imagem
  (ou vai pro Canva) — nunca um emoji "quase".
- Não sobrescreve palavra que já tem ilustração do Canva (manifesto
  vocab_uploads/<territorio>.json).

Requer cairosvg + pillow (ferramenta de desenvolvimento, fora do backend):
    python3 -m venv /tmp/svgvenv && /tmp/svgvenv/bin/pip install cairosvg pillow
    cd backend && /tmp/svgvenv/bin/python scripts/build_twemoji_vocab.py
Saída: scripts/vocab_images/<territorio>/<slug>_twemoji.webp e
scripts/vocab_uploads/<territorio>_twemoji.json (pro upload_vocab_media.py).
"""

import io
import json
import os
import re
import unicodedata
import urllib.request

import cairosvg
from PIL import Image

RAW = "https://raw.githubusercontent.com/jdecked/twemoji/main/assets/svg/{}.svg"
PAGE = "https://github.com/jdecked/twemoji/blob/main/assets/svg/{}.svg"
CREDIT = "Twemoji (jdecked) — CC-BY 4.0"
BG = (0x17, 0x16, 0x1A)  # AppColors.bg2 (tema escuro)
CANVAS = (480, 340)
EMOJI_PX = 250
CACHE = "/tmp/twemoji_svg"


def slug(text: str) -> str:
    ascii_text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "_", ascii_text.lower()).strip("_") or "item"


def svg_bytes(code: str) -> bytes:
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, f"{code}.svg")
    if not os.path.exists(path):
        with urllib.request.urlopen(RAW.format(code), timeout=30) as r:
            open(path, "wb").write(r.read())
    return open(path, "rb").read()


def render(code: str) -> Image.Image:
    png = cairosvg.svg2png(bytestring=svg_bytes(code), output_width=EMOJI_PX, output_height=EMOJI_PX)
    emoji = Image.open(io.BytesIO(png)).convert("RGBA")
    canvas = Image.new("RGB", CANVAS, BG)
    canvas.paste(emoji, ((CANVAS[0] - EMOJI_PX) // 2, (CANVAS[1] - EMOJI_PX) // 2), emoji)
    return canvas


def main() -> None:
    manifest = json.load(open("scripts/vocab_manifest.json", encoding="utf-8"))
    mapping = json.load(open("scripts/twemoji_map.json", encoding="utf-8"))
    total = 0
    for territory, rows in manifest.items():
        canva_path = f"scripts/vocab_uploads/{territory}.json"
        canva_prompts = {r["prompt"] for r in json.load(open(canva_path, encoding="utf-8"))} if os.path.exists(canva_path) else set()
        out_dir = f"scripts/vocab_images/{territory}"
        os.makedirs(out_dir, exist_ok=True)
        entries = []
        for row in rows:
            code = mapping.get((row["pt_meaning"] or "").strip())
            if not code or row["prompt"] in canva_prompts:
                continue
            image_path = f"{out_dir}/{slug(row['correct_answer'])}_twemoji.webp"
            render(code).save(image_path, "WEBP", quality=85, method=6)
            entries.append({
                "territory_id": territory,
                "prompt": row["prompt"],
                "image_path": image_path,
                "source_url": PAGE.format(code),
                "source_name": CREDIT,
            })
        if entries:
            json.dump(entries, open(f"scripts/vocab_uploads/{territory}_twemoji.json", "w", encoding="utf-8"), ensure_ascii=False, indent=2)
        print(f"{territory}: {len(entries)} imagens")
        total += len(entries)
    print(f"Total: {total}")


if __name__ == "__main__":
    main()
