# iOS Performance Baseline — Lexend Scholar

> Issue: LS-158 | Definir baseline de performance iOS (tempo de abertura, memória)

---

## Baselines de Performance

| Métrica | Baseline Atual | Meta | Device de Teste | Como Medir |
|---------|---------------|------|----------------|-----------|
| Cold start | < 2.0s | < 1.5s | iPhone SE (3ª geração) | Instruments → App Launch |
| Warm start | < 0.8s | < 0.5s | iPhone SE (3ª geração) | Instruments → App Launch |
| Memória idle | < 120MB | < 80MB | iPhone SE (3ª geração) | Instruments → Allocations |
| Memória pico (500 alunos) | < 280MB | < 200MB | iPhone 15 Pro | Instruments → Allocations |
| Tamanho do app | < 80MB | < 50MB | — | Xcode Organizer / TestFlight |
| Scroll FPS (lista de alunos) | > 55fps | 60fps constante | iPhone SE (3ª geração) | Instruments → Core Animation |
| Tempo de geração de boletim PDF | < 5s | < 3s | iPhone SE (3ª geração) | XCTest measure |
| Carregamento de lista 200 alunos | < 1.5s | < 1.0s | iPhone SE (3ª geração) | XCTest measure |

### Por que iPhone SE?
O iPhone SE é o device mais lento suportado. Performance aceitável no SE garante boa experiência em todos os devices mais modernos.

---

## Testes de Performance com XCTest

### App Launch Performance

```swift
import XCTest

class PerformanceTests: XCTestCase {

    // MARK: - App Launch

    func testAppLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    func testAppLaunchPerformanceColdStart() {
        let app = XCUIApplication()
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
            app.launch()
        }
    }

    // MARK: - Carregamento de Lista de Alunos

    func testStudentListLoadingPerformance() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--use-mock-data-500-students"]
        app.launch()

        // Navegar para lista de alunos
        app.tabBars.buttons["Alunos"].tap()

        measure(metrics: [XCTClockMetric()]) {
            // Aguardar a lista carregar completamente
            let firstCell = app.cells.firstMatch
            XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        }
    }

    // MARK: - Geração de Boletim

    func testBoletimGenerationPerformance() {
        // Teste unitário (sem UI) para medir tempo de geração de PDF
        let service = BoletimService()
        let mockAluno = Aluno.mockWith500Grades()

        measure(metrics: [XCTClockMetric()]) {
            let _ = service.generatePDF(for: mockAluno)
        }
    }

    // MARK: - Scroll Performance

    func testStudentListScrollPerformance() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--use-mock-data-200-students"]
        app.launch()
        app.tabBars.buttons["Alunos"].tap()

        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        measure(metrics: [XCTOSSignpostMetric.scrollingAndDeceleration]) {
            table.swipeUp(velocity: .fast)
            table.swipeDown(velocity: .fast)
        }
    }
}
```

### Teste de Memória

```swift
func testMemoryUsageWithLargeDataset() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--use-mock-data-500-students"]
    app.launch()

    measure(metrics: [XCTMemoryMetric()]) {
        app.tabBars.buttons["Alunos"].tap()
        let _ = app.cells.firstMatch.waitForExistence(timeout: 10)
        app.tabBars.buttons["Frequência"].tap()
        app.tabBars.buttons["Boletim"].tap()
        app.tabBars.buttons["Financeiro"].tap()
    }
}
```

---

## Como Usar o Instruments

### Medir Cold Start

1. No Xcode: **Product → Profile** (⌘I)
2. Selecionar template **"App Launch"**
3. Pressionar Record
4. O app é encerrado e relançado automaticamente
5. Ver a linha **"App Launch"** no timeline — tempo até primeiro frame renderizado

### Medir Memória (Allocations)

1. **Product → Profile** → template **"Allocations"**
2. Navegar pelo app normalmente (dashboard → alunos → frequência → boletim)
3. Verificar **"All Allocations"** no painel inferior
4. Pico de memória visível no gráfico

### Medir Scroll FPS (Core Animation)

1. **Product → Profile** → template **"Core Animation"**
2. Navegar para a lista de alunos
3. Fazer scroll rápido para cima e para baixo
4. Verificar **"FPS"** no painel — meta: linha verde acima de 55fps constante

---

## GitHub Actions — Workflow Semanal de Performance

Arquivo: `.github/workflows/ios-performance.yml`

```yaml
name: iOS Performance Baseline

on:
  schedule:
    - cron: '0 6 * * 1'  # Segunda-feira às 6h (horário UTC)
  workflow_dispatch:       # Permite rodar manualmente

jobs:
  performance:
    name: iOS Performance Tests
    runs-on: macos-14

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Run performance tests
        run: |
          xcodebuild test \
            -project LexendScholar.xcodeproj \
            -scheme LexendScholarPerformanceTests \
            -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' \
            -testPlan PerformanceTestPlan \
            2>&1 | xcpretty

      - name: Compare with baseline
        run: |
          python3 scripts/qa/check-performance-regression.py \
            docs/quality/ios-performance-baseline.json \
            2>&1

      - name: Alert on regression
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: '⚠️ Regressão de Performance iOS Detectada',
              body: 'O workflow de performance semanal detectou uma regressão > 20%. Verificar o resultado do workflow: ' + context.runId,
              labels: ['performance', 'automated']
            });
```

### Critério de Alerta de Regressão

| Regressão | Ação |
|-----------|------|
| > 10% em qualquer métrica | Criar comentário de alerta no PR |
| > 20% em qualquer métrica | Criar issue automática no Linear/GitHub |
| > 25% em cold start ou memória | Bloquear merge e criar issue P1 |
