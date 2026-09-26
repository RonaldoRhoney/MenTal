#!/usr/bin/env bash
# Carga de conteúdo em PRODUÇÃO. Lê a URL do banco do arquivo ~/mental_url.txt (uma linha),
# confere, carrega os lotes e apaga o arquivo no final. Nunca imprime a URL.
set -u
ARQ="$HOME/mental_url.txt"
[ -f "$ARQ" ] || { echo "❌ Não achei $ARQ. Faça o Passo 2 primeiro."; exit 1; }
URL="$(tr -d '[:space:]' < "$ARQ")"
[ -n "$URL" ] || { echo "❌ O arquivo está vazio. Cole a URL nele e salve (Ctrl+S)."; exit 1; }
case "$URL" in
  postgresql+psycopg://*) ;;
  postgresql://*) echo "❌ URL no formato do Supabase, não do Render. Copie o valor de MENTAL_DATABASE_URL do Render."; exit 1 ;;
  *) echo "❌ Isso não parece uma URL de banco (deveria começar com postgresql+psycopg://)."; exit 1 ;;
esac
export MENTAL_DATABASE_URL="$URL"
echo "✅ URL lida (${#URL} caracteres, banco postgresql+psycopg)."
cd "$(dirname "$0")/.." || exit 1
LOTES="concursos_municipal_portugues concursos_municipal_raciocinio concursos_municipal_informatica concursos_municipal_constituicao"
for n in 1 2 3 4 5 6 7 8 9 10; do LOTES="$LOTES vocab_ingles_basico_lote$n"; done
falhas=0
for f in $LOTES; do
  echo "== $f"
  saida="$(.venv/bin/python scripts/append_production_content.py "content/$f.json" 2>&1)"
  echo "$saida" | grep -E "✅|🛡|   -" 
  if echo "$saida" | grep -qiE "Traceback|Error|erro"; then falhas=$((falhas+1)); echo "⚠️  problema neste lote:"; echo "$saida" | tail -3 | sed 's#postgresql[^ ]*#[URL]#g'; fi
done
shred -u "$ARQ" 2>/dev/null || rm -f "$ARQ"
echo
[ "$falhas" -eq 0 ] && echo "🎉 Tudo carregado sem erros. Arquivo da URL apagado." || echo "⚠️ $falhas lote(s) com problema (veja acima). Arquivo da URL apagado."
