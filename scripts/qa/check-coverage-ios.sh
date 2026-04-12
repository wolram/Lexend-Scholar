#!/bin/bash
set -e

THRESHOLD=80

echo "================================================"
echo "Lexend Scholar — iOS Code Coverage Check"
echo "Threshold: ${THRESHOLD}%"
echo "================================================"

# Rodar testes com coverage
xcodebuild test \
  -project LexendScholar.xcodeproj \
  -scheme LexendScholar \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES \
  2>&1 | xcpretty

# Extrair percentual de coverage
COVERAGE=$(xcrun xccov view --report --json DerivedData/*/Logs/Test/*.xcresult \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(int(d['lineCoverage']*100))")

echo ""
echo "Coverage: ${COVERAGE}%"

if [ "$COVERAGE" -lt "$THRESHOLD" ]; then
  echo "FAIL: Coverage ${COVERAGE}% abaixo do mínimo ${THRESHOLD}%"
  echo ""
  echo "Para aumentar a cobertura:"
  echo "  1. Identifique arquivos com baixa cobertura:"
  echo "     xcrun xccov view --report DerivedData/*/Logs/Test/*.xcresult"
  echo "  2. Adicione testes XCTest para os casos não cobertos"
  echo "  3. Rode este script novamente antes de abrir o PR"
  exit 1
fi

echo "PASS: Coverage ${COVERAGE}% acima do mínimo ${THRESHOLD}%"
echo ""
echo "Relatório completo disponível em:"
echo "  DerivedData/*/Logs/Test/*.xcresult"
echo ""
echo "Para abrir no Xcode:"
echo "  open DerivedData/*/Logs/Test/*.xcresult"
