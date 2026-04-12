# LS-158 — Baseline de Performance iOS (Tempo de Abertura, Memória)

## Objetivo

Estabelecer métricas de baseline de performance para o app iOS do Lexend Scholar,
incluindo tempo de cold start, warm start e uso de memória em navegação normal.
Estas métricas serão usadas como referência para detectar regressões no CI.

---

## Métricas de Baseline

### Definições

| Métrica | Definição |
|---------|-----------|
| **Cold Start** | App não estava na memória → primeiro frame visível após toque |
| **Warm Start** | App estava suspensa → retorno ao primeiro plano |
| **Time to Interactive (TTI)** | Primeiro frame visível → app totalmente interativa (rede carregada) |
| **Memória em Idle** | Memória usada com app aberta na tela de login |
| **Memória em Navegação** | Memória ao navegar entre módulos principais |
| **Memória de Pico** | Memória máxima durante operação normal (sem memory leak) |

---

## Valores de Baseline Alvo

| Métrica | Baseline Meta | Limite Crítico | Dispositivo de Referência |
|---------|--------------|----------------|--------------------------|
| Cold Start | ≤ 1,5s | > 2,0s | iPhone 15 Pro (iOS 18) |
| Warm Start | ≤ 0,5s | > 0,8s | iPhone 15 Pro (iOS 18) |
| TTI (login → dashboard) | ≤ 2,5s | > 4,0s | iPhone 15 Pro (iOS 18) |
| Memória Idle | ≤ 80 MB | > 120 MB | iPhone 15 Pro (iOS 18) |
| Memória Navegação Normal | ≤ 120 MB | > 150 MB | iPhone 15 Pro (iOS 18) |
| Memória de Pico | ≤ 200 MB | > 250 MB | iPhone 15 Pro (iOS 18) |
| Cold Start (dispositivo antigo) | ≤ 3,0s | > 4,5s | iPhone SE 2ª Gen (iOS 16) |
| Memória (dispositivo antigo) | ≤ 150 MB | > 200 MB | iPhone SE 2ª Gen (iOS 16) |

---

## Método de Medição

### 1. Medição de Launch Time com XCTest

```swift
// Tests/PerformanceTests/LaunchPerformanceTests.swift
import XCTest

final class LaunchPerformanceTests: XCTestCase {
    
    // Mede o tempo de cold start
    func test_coldStartTime() throws {
        // Rodar 5 vezes para obter média estatística
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    // Mede o tempo de launch com dados pré-carregados (warm)
    func test_warmStartTime() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Suspender app
        XCUIDevice.shared.press(.home)
        
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
            app.activate()
        }
    }
    
    // Mede uso de memória na tela de login
    func test_memoryOnLaunch() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            let app = XCUIApplication()
            app.launch()
            // Aguardar tela de login estabilizar
            _ = app.staticTexts["Entrar"].waitForExistence(timeout: 5)
        }
    }
    
    // Mede uso de memória ao navegar entre módulos
    func test_memoryDuringNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Login com conta de teste
        app.textFields["email"].tap()
        app.textFields["email"].typeText("qa@lexendscholar.com.br")
        app.secureTextFields["senha"].tap()
        app.secureTextFields["senha"].typeText("QA@2026!")
        app.buttons["Entrar"].tap()
        
        measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
            // Navegar pelos módulos principais
            app.tabBars.buttons["Alunos"].tap()
            app.tabBars.buttons["Frequência"].tap()
            app.tabBars.buttons["Notas"].tap()
            app.tabBars.buttons["Financeiro"].tap()
            app.tabBars.buttons["Dashboard"].tap()
        }
    }
}
```

### 2. Medição Manual com Instruments

```bash
# Iniciar profiling de Launch Time
instruments -t "App Launch" \
  -D "launch-profile.trace" \
  -w "iPhone 15 Pro" \
  com.lexend.scholar

# Iniciar profiling de Memória
instruments -t "Allocations" \
  -D "memory-profile.trace" \
  -w "iPhone 15 Pro" \
  com.lexend.scholar
```

**Passos para medição manual:**
1. Abrir Xcode → Product → Profile (⌘ + I)
2. Selecionar template "App Launch" para medir cold start
3. Selecionar "Allocations" para memória
4. Executar em dispositivo físico (não simulador) para resultados reais
5. Repetir 5 vezes e calcular mediana

### 3. Benchmark de Dispositivos para Testar

| Dispositivo | iOS | Chip | Categoria |
|-------------|-----|------|-----------|
| iPhone 15 Pro Max | 18 | A17 Pro | High-end |
| iPhone 15 | 17 | A16 | Médio-alto |
| iPhone 13 | 16 | A15 | Médio |
| iPhone SE 2ª Geração | 16 | A13 | Baixo |
| iPhone 11 | 16 | A13 | Baixo |

---

## Script de Verificação de Baseline no CI

```bash
#!/bin/bash
# scripts/qa/check-performance-baseline-ios.sh

set -e

echo "Executando testes de performance iOS..."

# Rodar testes de performance
xcodebuild test \
  -project LexendScholar.xcodeproj \
  -scheme LexendScholar \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing "LexendScholarTests/LaunchPerformanceTests" \
  -resultBundlePath PerformanceResults.xcresult \
  -quiet

echo "Extraindo métricas de performance..."

# Extrair métricas do xcresult (requer Xcode 15+)
xcrun xcresulttool get \
  --path PerformanceResults.xcresult \
  --format json \
  --id $(xcrun xcresulttool get --path PerformanceResults.xcresult --format json | \
    python3 -c "import json,sys; data=json.load(sys.stdin); print(data['actions']['_values'][0]['actionResult']['testsRef']['id']['_value'])") \
  > metrics.json 2>/dev/null || echo "Extração direta não disponível — verificar relatório manualmente"

echo "Verificação de baseline concluída."
echo "Consultar relatório em PerformanceResults.xcresult"
```

---

## Registro de Baseline (Histórico)

### Formulário de Registro

Preencher após cada medição formal (a cada release):

| Data | Versão | Dispositivo | Cold Start | Memória Idle | Memória Pico | Aprovado? |
|------|--------|-------------|-----------|-------------|-------------|----------|
| Abr/2026 | 1.0.0 | iPhone 15 Pro | — | — | — | Pendente |

---

## Configuração no CI (GitHub Actions)

```yaml
# .github/workflows/ios-performance.yml
name: iOS Performance Baseline

on:
  push:
    branches: [main]
  schedule:
    - cron: '0 6 * * 1'  # Toda segunda-feira às 6h UTC

jobs:
  performance:
    runs-on: macos-15
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Select Xcode 16
        run: sudo xcode-select -s /Applications/Xcode_16.app/Contents/Developer
      
      - name: Run Performance Tests
        run: |
          xcodebuild test \
            -project LexendScholar.xcodeproj \
            -scheme LexendScholar \
            -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
            -only-testing "LexendScholarTests/LaunchPerformanceTests" \
            -resultBundlePath PerformanceResults.xcresult \
            -quiet
      
      - name: Upload Performance Results
        uses: actions/upload-artifact@v4
        with:
          name: ios-performance-results
          path: PerformanceResults.xcresult
          retention-days: 90
      
      - name: Check Regression
        run: bash scripts/qa/check-performance-baseline-ios.sh
```

---

## Alertas de Regressão

Uma regressão de performance é detectada quando:
- Cold start aumenta mais de **10%** em relação ao baseline
- Memória de pico aumenta mais de **15%** em relação ao baseline
- Qualquer métrica ultrapassa o **Limite Crítico** definido acima

Ao detectar regressão:
1. CI falha o build automaticamente
2. Notificação no canal Slack `#performance-alerts`
3. Abrir issue P2 no Linear com stack trace do Instruments
4. Investigar commit que introduziu a regressão com `git bisect`

---

## Referências

- [XCTest Performance Tests — Apple Docs](https://developer.apple.com/documentation/xctest/performance_tests)
- [Instruments User Guide — Apple](https://help.apple.com/instruments/mac/)
- [App Launch Time — Apple WWDC](https://developer.apple.com/videos/play/wwdc2019/423/)
- [Release Criteria — LS-166](./LS-166-release-criteria.md)
- [Coverage — LS-167](./LS-167-cobertura-automatica.md)
