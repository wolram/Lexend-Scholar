#!/bin/sh
# Xcode Cloud — Post-Clone Script
# Executado após o clone do repositório no ambiente de CI do Xcode Cloud.
# Instala dependências necessárias para o build.

set -e

echo "==> [LS-16] Xcode Cloud post-clone script iniciado"
echo "==> Branch: ${CI_BRANCH}"
echo "==> Build number: ${CI_BUILD_NUMBER}"
echo "==> Xcode version: $(xcodebuild -version)"

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
echo "==> Gerando LexendScholar.xcodeproj com XcodeGen..."
xcodegen generate --spec project.yml

echo "==> Post-clone concluído com sucesso"
