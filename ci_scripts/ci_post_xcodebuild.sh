#!/bin/sh
# Xcode Cloud — Post-Xcodebuild Script
# Executado após o build no Xcode Cloud.
# Coleta relatórios de teste e logs relevantes.

set -e

echo "==> [LS-16] Xcode Cloud post-xcodebuild script iniciado"
echo "==> Status do build: ${CI_XCODEBUILD_EXIT_CODE}"
echo "==> Artefatos em: ${CI_DERIVED_DATA_PATH}"

# Exibir resumo dos testes se disponível
if [ -d "${CI_RESULT_BUNDLE_PATH}" ]; then
  echo "==> Bundle de resultados disponível em: ${CI_RESULT_BUNDLE_PATH}"
fi

# Verificar se o build foi bem-sucedido
if [ "${CI_XCODEBUILD_EXIT_CODE}" -ne 0 ]; then
  echo "==> ERRO: Build falhou com código ${CI_XCODEBUILD_EXIT_CODE}"
  exit 1
fi

echo "==> Post-xcodebuild concluído com sucesso"
