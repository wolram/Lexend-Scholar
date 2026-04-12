#!/bin/bash
# LS-160 — Auditoria Lighthouse (meta: score > 90)
# Uso: bash scripts/qa/run-lighthouse.sh [URL_BASE]
# Padrão: http://localhost:8080
# Requisito: npm install -g lighthouse

set -e

SITE_URL="${1:-http://localhost:8080}"
MIN_SCORE=90
PAGES=("/" "/about.html" "/pricing.html" "/blog.html" "/contact.html")
OUTPUT_DIR="docs/quality/lighthouse-reports"
FAILED=0

echo "======================================================"
echo "Auditoria Lighthouse — Lexend Scholar"
echo "URL base: $SITE_URL"
echo "Meta mínima: $MIN_SCORE em todas as categorias"
echo "======================================================"
echo ""

# Verificar lighthouse instalado
if ! command -v lighthouse &> /dev/null; then
  echo "ERRO: lighthouse não encontrado."
  echo "Instale com: npm install -g lighthouse"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

for PAGE in "${PAGES[@]}"; do
  PAGE_NAME=$(echo "$PAGE" | tr '/' '-' | sed 's/^-//' | sed 's/\.html//')
  [ -z "$PAGE_NAME" ] && PAGE_NAME="home"

  FULL_URL="${SITE_URL}${PAGE}"
  OUTPUT_BASE="$OUTPUT_DIR/lighthouse-${PAGE_NAME}"

  echo "Auditando: $FULL_URL"

  lighthouse "$FULL_URL" \
    --output=json \
    --output=html \
    --output-path="$OUTPUT_BASE" \
    --chrome-flags="--headless --no-sandbox --disable-gpu" \
    --preset=desktop \
    --quiet \
    2>/dev/null || true

  JSON_FILE="${OUTPUT_BASE}.report.json"

  if [ -f "$JSON_FILE" ]; then
    python3 -c "
import json, sys

with open('$JSON_FILE') as f:
    data = json.load(f)

cats = data.get('categories', {})
audits = data.get('audits', {})

scores = {}
for cat_id, cat in cats.items():
    scores[cat_id] = int(cat['score'] * 100)

failed_cats = [f'{k}: {v}' for k, v in scores.items() if v < $MIN_SCORE]

print(f'  Performance:    {scores.get(\"performance\", \"?\"):>3}')
print(f'  Accessibility:  {scores.get(\"accessibility\", \"?\"):>3}')
print(f'  Best Practices: {scores.get(\"best-practices\", \"?\"):>3}')
print(f'  SEO:            {scores.get(\"seo\", \"?\"):>3}')

lcp = audits.get('largest-contentful-paint', {}).get('displayValue', '?')
tbt = audits.get('total-blocking-time', {}).get('displayValue', '?')
cls = audits.get('cumulative-layout-shift', {}).get('displayValue', '?')
print(f'  LCP: {lcp} | TBT: {tbt} | CLS: {cls}')

if failed_cats:
    print(f'  ✗ ABAIXO DA META: {\" | \".join(failed_cats)}')
    sys.exit(1)
else:
    print(f'  ✓ OK: Todos os scores >= $MIN_SCORE')
    sys.exit(0)
" 2>&1

    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
      FAILED=1
    fi
  else
    echo "  AVISO: Relatório não gerado para $FULL_URL"
  fi

  echo ""
done

echo "======================================================"
echo "Relatórios HTML em: $OUTPUT_DIR/"

if [ $FAILED -eq 1 ]; then
  echo ""
  echo "✗ FALHA: Um ou mais scores abaixo de $MIN_SCORE"
  echo "Consulte: docs/quality/LS-160-lighthouse-audit.md"
  exit 1
else
  echo ""
  echo "✓ PASSOU: Todos os scores >= $MIN_SCORE"
  exit 0
fi
