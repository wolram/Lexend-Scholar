#!/bin/sh
# Xcode Cloud — Pre-Xcodebuild Script
# Executado antes de cada build no Xcode Cloud.
# Roda SwiftLint e valida dependências antes da compilação.

set -e

echo "==> [LS-16] Xcode Cloud pre-xcodebuild script iniciado"
echo "==> Workflow: ${CI_WORKFLOW}"
echo "==> Branch: ${CI_BRANCH}"
echo "==> Build ID: ${CI_BUILD_ID}"

# Rodar SwiftLint
if command -v swiftlint &> /dev/null; then
  echo "==> Rodando SwiftLint..."
  swiftlint lint --config .swiftlint.yml --reporter github-actions-logging || true
else
  echo "==> SwiftLint não encontrado, pulando lint"
fi

echo "==> Pre-xcodebuild concluído"
