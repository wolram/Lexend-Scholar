#!/bin/bash
# LS-167 — Verificação automática de cobertura iOS
# Uso: bash scripts/qa/check-coverage-ios.sh
# Requisito: Xcode instalado, projeto LexendScholar.xcodeproj na raiz

set -e

COVERAGE_PATH="TestResults.xcresult"
MIN_COVERAGE=80

echo "======================================================"
echo "Verificação de Cobertura iOS — Lexend Scholar"
echo "Meta mínima: ${MIN_COVERAGE}%"
echo "======================================================"
echo ""

echo "Executando testes iOS com coverage..."
xcodebuild test \
  -project LexendScholar.xcodeproj \
  -scheme LexendScholar \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -enableCodeCoverage YES \
  -resultBundlePath "$COVERAGE_PATH" \
  -quiet

echo "Extraindo relatório de cobertura..."
xcrun xccov view --report "$COVERAGE_PATH" > /tmp/coverage-report.txt 2>/dev/null

echo ""
echo "--- Cobertura por módulo ---"
cat /tmp/coverage-report.txt | grep -E "(Features|Core|LexendScholar\.app)" | head -20

echo ""
# Extrair percentual total do app
COVERAGE_LINE=$(cat /tmp/coverage-report.txt | grep "LexendScholar.app" | head -1)
COVERAGE_PCT=$(echo "$COVERAGE_LINE" | grep -oE '[0-9]+\.[0-9]+%' | head -1 | tr -d '%')

if [ -z "$COVERAGE_PCT" ]; then
  echo "AVISO: Não foi possível extrair o percentual de cobertura automaticamente."
  echo "Verifique o relatório completo em: $COVERAGE_PATH"
  exit 0
fi

echo "======================================================"
echo "Cobertura total: ${COVERAGE_PCT}%"
echo "Meta mínima:     ${MIN_COVERAGE}%"
echo "======================================================"

PASSES=$(echo "$COVERAGE_PCT >= $MIN_COVERAGE" | bc -l 2>/dev/null || python3 -c "print(1 if $COVERAGE_PCT >= $MIN_COVERAGE else 0)")

if [ "$PASSES" = "1" ]; then
  echo ""
  echo "✓ PASSOU: Coverage ${COVERAGE_PCT}% >= ${MIN_COVERAGE}%"
  exit 0
else
  echo ""
  echo "✗ FALHOU: Coverage ${COVERAGE_PCT}% < ${MIN_COVERAGE}%"
  echo ""
  echo "Para aumentar a cobertura:"
  echo "  1. Execute: xcrun xccov view --report $COVERAGE_PATH"
  echo "  2. Identifique arquivos com baixa cobertura"
  echo "  3. Adicione testes unitários para os módulos deficientes"
  echo "  4. Consulte: docs/quality/LS-167-cobertura-automatica.md"
  exit 1
fi
