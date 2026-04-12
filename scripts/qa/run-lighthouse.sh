#!/bin/bash
set -e

PAGES=("website/index.html" "website/pricing.html" "website/blog.html")
OUTPUT_DIR="docs/quality"

echo "================================================"
echo "Lexend Scholar — Lighthouse Audit"
echo "================================================"
echo ""

# Verificar dependências
if ! command -v npx &> /dev/null; then
  echo "ERRO: npx não encontrado. Instale Node.js: https://nodejs.org"
  exit 1
fi

if ! command -v google-chrome &> /dev/null && ! command -v chromium &> /dev/null && ! command -v "Google Chrome" &> /dev/null 2>&1; then
  echo "AVISO: Chrome não encontrado no PATH. Lighthouse tentará encontrar automaticamente."
fi

mkdir -p "$OUTPUT_DIR"

for PAGE in "${PAGES[@]}"; do
  if [ ! -f "$PAGE" ]; then
    echo "AVISO: Arquivo não encontrado: $PAGE — pulando"
    continue
  fi

  PAGENAME=$(basename "$PAGE" .html)
  echo "Auditando: $PAGE"

  npx lighthouse "file://$(pwd)/$PAGE" \
    --output=json \
    --output-path="$OUTPUT_DIR/lighthouse-${PAGENAME}.json" \
    --chrome-flags="--headless --no-sandbox" \
    --only-categories=performance,accessibility,best-practices,seo \
    --quiet

  # Exibir scores
  python3 -c "
import json
with open('$OUTPUT_DIR/lighthouse-${PAGENAME}.json') as f:
    data = json.load(f)
cats = data['categories']
print(f'  Performance:     {int(cats[\"performance\"][\"score\"]*100)}')
print(f'  Accessibility:   {int(cats[\"accessibility\"][\"score\"]*100)}')
print(f'  Best Practices:  {int(cats[\"best-practices\"][\"score\"]*100)}')
print(f'  SEO:             {int(cats[\"seo\"][\"score\"]*100)}')
" 2>/dev/null || echo "  (não foi possível extrair scores do JSON)"

  echo ""
done

echo "================================================"
echo "Auditoria concluída."
echo "Relatórios em: $OUTPUT_DIR/lighthouse-*.json"
echo ""
echo "Para verificar regressões:"
echo "  python3 scripts/qa/check-performance-regression.py $OUTPUT_DIR/lighthouse-index.json"
echo "================================================"
