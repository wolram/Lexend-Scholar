#!/bin/bash
# LS-168 — Auditoria de Acessibilidade WCAG 2.1 AA
# Uso: bash scripts/qa/run-accessibility-audit.sh [URL_BASE]
# Padrão: http://localhost:8080
# Requisito: npm install -g @axe-core/cli

set -e

SITE_URL="${1:-http://localhost:8080}"
PAGES=("/" "/about.html" "/pricing.html" "/blog.html" "/contact.html" "/404.html")
OUTPUT_DIR="docs/quality/accessibility-reports"
FAILED=0

echo "======================================================"
echo "Auditoria de Acessibilidade WCAG 2.1 AA — Lexend Scholar"
echo "URL base: $SITE_URL"
echo "======================================================"
echo ""

# Verificar axe-cli instalado
if ! command -v axe &> /dev/null; then
  echo "ERRO: axe-cli não encontrado."
  echo "Instale com: npm install -g @axe-core/cli"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

for PAGE in "${PAGES[@]}"; do
  PAGE_NAME=$(echo "$PAGE" | tr '/' '-' | tr '.' '-' | sed 's/^-//')
  [ -z "$PAGE_NAME" ] && PAGE_NAME="home"

  FULL_URL="${SITE_URL}${PAGE}"
  OUTPUT_FILE="$OUTPUT_DIR/axe-${PAGE_NAME}.json"

  echo "Auditando: $FULL_URL"

  # Executar axe com tags WCAG 2.1 A e AA
  axe "$FULL_URL" \
    --tags wcag2a,wcag2aa,wcag21a,wcag21aa \
    --save "$OUTPUT_FILE" \
    --reporter json \
    2>/dev/null || true

  if [ -f "$OUTPUT_FILE" ]; then
    # Contar violations por severidade
    VIOLATIONS=$(python3 -c "
import json, sys
try:
    with open('$OUTPUT_FILE') as f:
        data = json.load(f)
    violations = data[0]['violations'] if isinstance(data, list) else data.get('violations', [])
    critical = sum(1 for v in violations if v.get('impact') == 'critical')
    serious = sum(1 for v in violations if v.get('impact') == 'serious')
    moderate = sum(1 for v in violations if v.get('impact') == 'moderate')
    print(f'Críticas: {critical} | Sérias: {serious} | Moderadas: {moderate}')
    if critical + serious > 0:
        sys.exit(1)
except Exception as e:
    print(f'Erro ao processar relatório: {e}')
    sys.exit(0)
" 2>&1)

    EXIT_CODE=$?
    echo "  $VIOLATIONS"

    if [ $EXIT_CODE -ne 0 ]; then
      echo "  ✗ FALHA: Violations críticas ou sérias encontradas!"
      FAILED=1
    else
      echo "  ✓ OK: Nenhuma violation crítica/séria"
    fi
  else
    echo "  AVISO: Relatório não gerado para $FULL_URL"
  fi

  echo ""
done

echo "======================================================"
echo "Relatórios salvos em: $OUTPUT_DIR/"

if [ $FAILED -eq 1 ]; then
  echo ""
  echo "✗ FALHA: Violations WCAG 2.1 AA detectadas!"
  echo "Consulte: docs/quality/LS-168-acessibilidade-wcag.md"
  echo "Corrija todas as violations críticas e sérias antes do release."
  exit 1
else
  echo ""
  echo "✓ PASSOU: Nenhuma violation crítica/séria detectada."
  exit 0
fi
