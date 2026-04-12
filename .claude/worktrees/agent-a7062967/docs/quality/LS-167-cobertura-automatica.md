# LS-167 — Implementar Verificação Automática de Cobertura (meta: > 80%)

## Objetivo

Configurar coleta de code coverage no CI, bloquear merge se cobertura total < 80%,
e gerar relatório por módulo para acompanhamento contínuo.

---

## Plataforma iOS — XCTest + Xcode Coverage

### Configuração do Scheme para Coverage

No Xcode, editar o scheme de testes:
1. Product → Scheme → Edit Scheme
2. Test → Options
3. Marcar: **Code Coverage** → "Gather coverage for: all targets"

### Executar coverage localmente

```bash
# Rodar testes com coverage
xcodebuild test \
  -project LexendScholar.xcodeproj \
  -scheme LexendScholar \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# Exportar relatório de coverage em JSON
xcrun xccov view --report --json TestResults.xcresult > coverage.json

# Extrair percentual total
xcrun xccov view --report TestResults.xcresult | grep -E "^[[:space:]]*LexendScholar" | head -1
```

### Script de Verificação do Gate de Coverage

```bash
#!/bin/bash
# scripts/qa/check-coverage-ios.sh

set -e

COVERAGE_JSON="TestResults.xcresult"
MIN_COVERAGE=80

echo "Executando testes iOS com coverage..."
xcodebuild test \
  -project LexendScholar.xcodeproj \
  -scheme LexendScholar \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES \
  -resultBundlePath "$COVERAGE_JSON" \
  -quiet

echo "Extraindo cobertura..."
COVERAGE_LINE=$(xcrun xccov view --report "$COVERAGE_JSON" | grep "LexendScholar.app" | head -1)
COVERAGE_PCT=$(echo "$COVERAGE_LINE" | grep -oE '[0-9]+\.[0-9]+%' | head -1 | tr -d '%')

echo "Cobertura atual: ${COVERAGE_PCT}%"
echo "Meta mínima: ${MIN_COVERAGE}%"

# Comparação com bc
PASSES=$(echo "$COVERAGE_PCT >= $MIN_COVERAGE" | bc -l)

if [ "$PASSES" -eq 1 ]; then
  echo "✓ Coverage OK: ${COVERAGE_PCT}% >= ${MIN_COVERAGE}%"
  exit 0
else
  echo "✗ Coverage INSUFICIENTE: ${COVERAGE_PCT}% < ${MIN_COVERAGE}%"
  echo "O merge está bloqueado. Adicione testes para cobrir o código faltante."
  exit 1
fi
```

---

## Configuração GitHub Actions — iOS

```yaml
# .github/workflows/ios-coverage.yml
name: iOS Coverage Check

on:
  pull_request:
    branches: [main, develop]

jobs:
  coverage:
    runs-on: macos-15
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.app/Contents/Developer
      
      - name: Run Tests with Coverage
        run: |
          xcodebuild test \
            -project LexendScholar.xcodeproj \
            -scheme LexendScholar \
            -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
            -enableCodeCoverage YES \
            -resultBundlePath TestResults.xcresult \
            -quiet
      
      - name: Check Coverage Gate
        run: bash scripts/qa/check-coverage-ios.sh
      
      - name: Generate Coverage Report
        if: always()
        run: |
          xcrun xccov view --report --json TestResults.xcresult > coverage-report.json
          xcrun xccov view --report TestResults.xcresult > coverage-report.txt
      
      - name: Upload Coverage Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: ios-coverage-report
          path: |
            coverage-report.json
            coverage-report.txt
      
      - name: Comment PR with Coverage
        uses: actions/github-script@v7
        if: always()
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('coverage-report.txt', 'utf8');
            const lines = report.split('\n').slice(0, 30).join('\n');
            
            await github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Relatório de Coverage iOS\n\`\`\`\n${lines}\n\`\`\``
            });
```

---

## Relatório por Módulo

### Estrutura de Módulos do Lexend Scholar

```
LexendScholar/
├── Features/
│   ├── Auth/          → Meta: > 85% (crítico de segurança)
│   ├── Alunos/        → Meta: > 80%
│   ├── Frequencia/    → Meta: > 85% (core feature)
│   ├── Notas/         → Meta: > 85% (core feature)
│   ├── Boletim/       → Meta: > 80%
│   ├── Financeiro/    → Meta: > 85% (dados sensíveis)
│   └── Comunicacao/   → Meta: > 75%
├── Core/
│   ├── Network/       → Meta: > 80%
│   ├── Storage/       → Meta: > 80%
│   └── Utils/         → Meta: > 70%
└── UI/
    └── Components/    → Meta: > 60% (UI é difícil de testar unitariamente)
```

### Dashboard de Coverage (modelo)

| Módulo | Cobertura Atual | Meta | Status |
|--------|----------------|------|--------|
| Auth | — | 85% | Pendente |
| Alunos | — | 80% | Pendente |
| Frequencia | — | 85% | Pendente |
| Notas | — | 85% | Pendente |
| Boletim | — | 80% | Pendente |
| Financeiro | — | 85% | Pendente |
| Comunicacao | — | 75% | Pendente |
| Core/Network | — | 80% | Pendente |
| Core/Storage | — | 80% | Pendente |
| **Total** | **—** | **80%** | **Pendente** |

---

## Integração com Codecov (Opcional — Visualização)

```yaml
# Adicionar ao workflow após geração do relatório
- name: Upload to Codecov
  uses: codecov/codecov-action@v4
  with:
    token: ${{ secrets.CODECOV_TOKEN }}
    files: coverage-report.json
    flags: ios
    fail_ci_if_error: true
```

O Codecov exibirá no PR:
- Cobertura total e por arquivo
- Linhas cobertas (verde) vs não cobertas (vermelho)
- Comparação com a branch principal (delta de coverage)

---

## Regras de Branch Protection (GitHub)

No GitHub → Settings → Branches → main → Branch protection rules:

```
✓ Require status checks to pass before merging
  Status checks requeridos:
  - iOS Coverage Check / coverage
  
✓ Require branches to be up to date before merging
✓ Do not allow bypassing the above settings
```

---

## Exemplos de Testes para Atingir a Meta

### Teste de Unidade — Módulo Frequencia

```swift
// Tests/FrequenciaTests/FrequenciaViewModelTests.swift
import XCTest
@testable import LexendScholar

final class FrequenciaViewModelTests: XCTestCase {
    
    var sut: FrequenciaViewModel!
    var mockRepository: MockFrequenciaRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockFrequenciaRepository()
        sut = FrequenciaViewModel(repository: mockRepository)
    }
    
    func test_marcarPresenca_atualizaListaCorretamente() async {
        // Arrange
        let aluno = Aluno.fixture(id: "001", nome: "Ana Silva")
        sut.alunos = [aluno]
        
        // Act
        await sut.marcarPresenca(alunoId: "001")
        
        // Assert
        XCTAssertEqual(sut.alunos.first?.presente, true)
        XCTAssertEqual(sut.totalPresentes, 1)
    }
    
    func test_encerrarChamada_salvaNoRepositorio() async throws {
        // Arrange
        sut.alunos = Aluno.fixtures(quantidade: 5, todosPresentes: true)
        
        // Act
        try await sut.encerrarChamada()
        
        // Assert
        XCTAssertTrue(mockRepository.salvarChamadaCalled)
        XCTAssertEqual(mockRepository.chamadaSalva?.totalPresentes, 5)
    }
}
```

---

## Referências

- [XCTest Code Coverage — Apple Docs](https://developer.apple.com/documentation/xcode/gathering-code-coverage-data)
- [GitHub Actions for iOS](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-swift)
- [Codecov iOS Integration](https://docs.codecov.com/docs/swift)
- [Release Criteria — LS-166](./LS-166-release-criteria.md)
