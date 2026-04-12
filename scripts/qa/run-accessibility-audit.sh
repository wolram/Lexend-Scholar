#!/bin/bash
set -e

PAGES=("website/index.html" "website/pricing.html" "website/blog.html" "website/about.html" "website/contact.html" "website/404.html")
RESULTS_DIR="docs/quality/accessibility-results"

echo "================================================"
echo "Lexend Scholar — Accessibility Audit (WCAG 2.1 AA)"
echo "================================================"
echo ""

# Verificar se axe-cli está disponível
if ! command -v npx &> /dev/null; then
  echo "ERRO: npx não encontrado. Instale Node.js: https://nodejs.org"
  exit 1
fi

mkdir -p "$RESULTS_DIR"

TOTAL_VIOLATIONS=0
FAILED_PAGES=()

for PAGE in "${PAGES[@]}"; do
  if [ ! -f "$PAGE" ]; then
    echo "AVISO: Arquivo não encontrado: $PAGE — pulando"
    continue
  fi

  PAGENAME=$(basename "$PAGE" .html)
  echo "Auditando: $PAGE"

  npx axe-cli "file://$(pwd)/$PAGE" \
    --save "$RESULTS_DIR/$PAGENAME.json" \
    --tags wcag2a,wcag2aa \
    --reporter json \
    2>/dev/null \
    || {
      echo "  ⚠ Violations encontradas em $PAGE — ver $RESULTS_DIR/$PAGENAME.json"
      FAILED_PAGES+=("$PAGE")
    }

  # Contar violations se o arquivo foi criado
  if [ -f "$RESULTS_DIR/$PAGENAME.json" ]; then
    VIOLATIONS=$(python3 -c "
import json, sys
try:
    with open('$RESULTS_DIR/$PAGENAME.json') as f:
        data = json.load(f)
    violations = sum(len(r.get('violations', [])) for r in data) if isinstance(data, list) else len(data.get('violations', []))
    print(violations)
except:
    print(0)
" 2>/dev/null || echo 0)
    TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + VIOLATIONS))
    echo "  → $VIOLATIONS violations encontradas"
  fi
done

echo ""
echo "================================================"
echo "Auditoria concluída."
echo "Total de violations: $TOTAL_VIOLATIONS"
echo "Resultados em: $RESULTS_DIR/"
echo "================================================"

if [ ${#FAILED_PAGES[@]} -gt 0 ]; then
  echo ""
  echo "Páginas com violations:"
  for PAGE in "${FAILED_PAGES[@]}"; do
    echo "  - $PAGE"
  done
  echo ""
  echo "Ver docs/quality/accessibility-report.md para guia de correções."
  exit 1
fi

echo ""
echo "PASS: Nenhuma violation encontrada!"
