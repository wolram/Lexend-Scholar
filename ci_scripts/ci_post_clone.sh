#!/bin/sh
# Xcode Cloud — Post-Clone Script
# Executado após o clone do repositório no ambiente de CI do Xcode Cloud.
# Instala dependências necessárias para o build.
# Determina o ambiente (prod/beta) com base na branch.

set -e

echo "==> [LS-16/LS-18] Xcode Cloud post-clone script iniciado"
echo "==> Branch: ${CI_BRANCH}"
echo "==> Build number: ${CI_BUILD_NUMBER}"
echo "==> Xcode version: $(xcodebuild -version)"

# Determinar ambiente baseado na branch
if [ "${CI_BRANCH}" = "main" ]; then
  export BUILD_ENV="production"
  export TESTFLIGHT_GROUP="Produção"
  echo "==> Ambiente: PRODUÇÃO (branch main)"
elif echo "${CI_BRANCH}" | grep -q "^feature/"; then
  export BUILD_ENV="beta"
  export TESTFLIGHT_GROUP="Beta Testers"
  echo "==> Ambiente: BETA (branch feature/*)"
else
  export BUILD_ENV="development"
  export TESTFLIGHT_GROUP="Internal"
  echo "==> Ambiente: DEVELOPMENT (branch ${CI_BRANCH})"
fi

# Instalar Homebrew se não estiver disponível
if ! command -v brew &> /dev/null; then
  echo "==> Instalando Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Instalar XcodeGen para gerar o .xcodeproj a partir do project.yml
if ! command -v xcodegen &> /dev/null; then
  echo "==> Instalando XcodeGen..."
  brew install xcodegen
fi

# Instalar SwiftLint para lint no CI
if ! command -v swiftlint &> /dev/null; then
  echo "==> Instalando SwiftLint..."
  brew install swiftlint
fi

# Gerar o projeto Xcode a partir do project.yml
echo "==> Gerando LexendScholar.xcodeproj com XcodeGen (env: ${BUILD_ENV})..."
xcodegen generate --spec project.yml

echo "==> Post-clone concluído com sucesso (env: ${BUILD_ENV})"
