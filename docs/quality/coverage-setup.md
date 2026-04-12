# Configuração de Cobertura de Código — iOS

> Issue: LS-167 | Implementar verificação automática de cobertura (meta: >80%)

---

## Script de Verificação

O script `scripts/qa/check-coverage-ios.sh` executa os testes do projeto Xcode com cobertura habilitada e bloqueia o CI se a cobertura estiver abaixo de 80%.

### Uso Local

```bash
# Na raiz do projeto
chmod +x scripts/qa/check-coverage-ios.sh
./scripts/qa/check-coverage-ios.sh
```

### Pré-requisitos
- Xcode 15+
- `xcpretty` instalado: `gem install xcpretty`
- Python 3 disponível no PATH
- Simulador iPhone 15 instalado

---

## GitHub Actions — Workflow

Arquivo: `.github/workflows/ios-coverage.yml`

```yaml
name: iOS Code Coverage

on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main

jobs:
  coverage:
    name: Check iOS Code Coverage
    runs-on: macos-14

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Install xcpretty
        run: gem install xcpretty

      - name: Run tests with coverage
        run: ./scripts/qa/check-coverage-ios.sh

      - name: Upload coverage report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: DerivedData/*/Logs/Test/*.xcresult
          retention-days: 7

      - name: Comment coverage on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const coverage = process.env.COVERAGE_PERCENT || 'N/A';
            const threshold = 80;
            const passed = parseInt(coverage) >= threshold;
            const icon = passed ? '✅' : '❌';
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## ${icon} iOS Code Coverage\n\n**Coverage:** ${coverage}%\n**Threshold:** ${threshold}%\n\n${passed ? 'Cobertura aprovada!' : '⚠️ Cobertura abaixo do mínimo. Adicione testes antes de fazer merge.'}`
            });
```

### Bloqueio de Merge

Para bloquear o merge quando a cobertura falha:

1. Acesse **GitHub → Settings → Branches → Branch protection rules**
2. Selecione a branch `main`
3. Habilite **"Require status checks to pass before merging"**
4. Adicione o check: `coverage / Check iOS Code Coverage`
5. Habilite **"Require branches to be up to date before merging"**

---

## Interpretação dos Resultados

### Verificar cobertura por arquivo

```bash
# Listar todos os arquivos com sua cobertura
xcrun xccov view --report DerivedData/*/Logs/Test/*.xcresult

# Filtrar arquivos com menos de 50% de cobertura
xcrun xccov view --report --json DerivedData/*/Logs/Test/*.xcresult \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
for target in data.get('targets', []):
    for file in target.get('files', []):
        cov = file.get('lineCoverage', 1) * 100
        if cov < 50:
            print(f\"{cov:.0f}%  {file['name']}\")
" | sort -n
```

### Abrir relatório no Xcode

```bash
open DerivedData/*/Logs/Test/*.xcresult
```
No Xcode: **Report Navigator → Coverage** para ver linha a linha.

---

## Estratégia para Atingir 80%

### Prioridade 1 — Arquivos de Lógica de Negócio
- `AttendanceService.swift` — registro de frequência
- `GradeService.swift` — cálculo de médias
- `BillingService.swift` — geração de cobranças
- `ReportGenerator.swift` — geração de boletim PDF

### Prioridade 2 — ViewModels
- Todos os `*ViewModel.swift` do padrão MVVM

### Prioridade 3 — Utilitários e Extensions
- `DateExtensions.swift`
- `ValidationHelpers.swift`

### O que NÃO precisa de cobertura
- Arquivos gerados automaticamente
- `AppDelegate.swift` / `SceneDelegate.swift`
- `Preview Content/`
- Arquivos de configuração (`.plist`, `.xcconfig`)

### Exclusão de arquivos do relatório de cobertura

No Xcode, marque os arquivos que não precisam de cobertura:
**Build Settings → Exclude from Coverage** ou use `.xccoverageIgnore` patterns.
