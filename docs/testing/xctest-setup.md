# XCTest Setup — LexendScholar iOS

## Visão Geral

Este documento descreve a configuração dos targets de teste XCTest no projeto `LexendScholar.xcodeproj`, cobrindo testes unitários e de UI para o aplicativo iOS do Lexend Scholar.

---

## Estrutura de Targets

```
LexendScholar.xcodeproj
├── LexendScholar              (App target principal)
├── LexendScholarTests         (Unit Tests — XCTest)
└── LexendScholarUITests       (UI Tests — XCUITest)
```

---

## Configuração do Target de Testes Unitários

### Nome do Target
`LexendScholarTests`

### Product Type
`com.apple.product-type.bundle.unit-test`

### Host Application
`LexendScholar`

### Arquivos do Target

| Arquivo | Descrição |
|---------|-----------|
| `LexendScholarTests/ModelsTests.swift` | Testes das models de domínio (Aluno, Turma, Nota) |
| `LexendScholarTests/AttendanceLogicTests.swift` | Lógica de cálculo de frequência |
| `LexendScholarTests/GradeCalculatorTests.swift` | Cálculo de médias e aprovação |
| `LexendScholarTests/SupabaseClientTests.swift` | Mocks do cliente Supabase |

### Exemplo de Teste Unitário

```swift
import XCTest
@testable import LexendScholar

final class GradeCalculatorTests: XCTestCase {

    func testMediaAritmeticaSimples() {
        let notas = [7.0, 8.5, 6.0, 9.0]
        let media = GradeCalculator.average(notas)
        XCTAssertEqual(media, 7.625, accuracy: 0.001)
    }

    func testAlunoAprovadoComMedia7() {
        let resultado = GradeCalculator.isApproved(average: 7.0, threshold: 7.0)
        XCTAssertTrue(resultado)
    }

    func testAlunoReprovadoAbaixoDaMedia() {
        let resultado = GradeCalculator.isApproved(average: 6.9, threshold: 7.0)
        XCTAssertFalse(resultado)
    }

    func testFrequenciaMinima75Porcento() {
        let totalAulas = 100
        let presencas = 74
        let aprovado = AttendanceCalculator.meetsMinimum(presencas, total: totalAulas)
        XCTAssertFalse(aprovado)
    }
}
```

---

## Configuração do Target de UI Tests

### Nome do Target
`LexendScholarUITests`

### Product Type
`com.apple.product-type.bundle.ui-testing`

### Arquivos do Target

| Arquivo | Descrição |
|---------|-----------|
| `LexendScholarUITests/LoginUITests.swift` | Fluxo de login por perfil |
| `LexendScholarUITests/StudentListUITests.swift` | Navegação na lista de alunos |
| `LexendScholarUITests/AttendanceUITests.swift` | Registro de frequência via UI |

### Exemplo de Teste de UI

```swift
import XCTest

final class LoginUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launch()
    }

    func testLoginDiretor() throws {
        let emailField = app.textFields["email_field"]
        let senhaField = app.secureTextFields["password_field"]
        let loginButton = app.buttons["login_button"]

        XCTAssertTrue(emailField.exists)
        emailField.tap()
        emailField.typeText("diretor@escola.com.br")

        senhaField.tap()
        senhaField.typeText("Senha@2025!")

        loginButton.tap()

        let dashboard = app.navigationBars["Painel do Diretor"]
        XCTAssertTrue(dashboard.waitForExistence(timeout: 5))
    }

    func testLoginProfessor() throws {
        let emailField = app.textFields["email_field"]
        let senhaField = app.secureTextFields["password_field"]
        let loginButton = app.buttons["login_button"]

        emailField.tap()
        emailField.typeText("professor@escola.com.br")

        senhaField.tap()
        senhaField.typeText("Senha@2025!")

        loginButton.tap()

        let dashboard = app.navigationBars["Minhas Turmas"]
        XCTAssertTrue(dashboard.waitForExistence(timeout: 5))
    }

    func testLoginSecretario() throws {
        let emailField = app.textFields["email_field"]
        let senhaField = app.secureTextFields["password_field"]
        let loginButton = app.buttons["login_button"]

        emailField.tap()
        emailField.typeText("secretario@escola.com.br")

        senhaField.tap()
        senhaField.typeText("Senha@2025!")

        loginButton.tap()

        let dashboard = app.navigationBars["Secretaria"]
        XCTAssertTrue(dashboard.waitForExistence(timeout: 5))
    }
}
```

---

## Adicionando Targets ao projeto.pbxproj

Para adicionar os targets manualmente via `project.yml` (XcodeGen), adicione as seguintes seções:

```yaml
targets:
  LexendScholar:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources: [app]
    dependencies:
      - framework: Charts.framework

  LexendScholarTests:
    type: bundle.unit-test
    platform: iOS
    deploymentTarget: "17.0"
    sources: [LexendScholarTests]
    dependencies:
      - target: LexendScholar
    settings:
      TEST_HOST: $(BUILT_PRODUCTS_DIR)/LexendScholar.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/LexendScholar

  LexendScholarUITests:
    type: bundle.ui-testing
    platform: iOS
    deploymentTarget: "17.0"
    sources: [LexendScholarUITests]
    dependencies:
      - target: LexendScholar
    settings:
      TEST_TARGET_NAME: LexendScholar
```

---

## Executando os Testes

### Via Xcode

1. Abra `LexendScholar.xcodeproj` no Xcode 15+
2. Selecione o simulador desejado (iPhone 15, iOS 17+)
3. `Cmd+U` para executar todos os testes
4. `Cmd+6` para abrir o Test Navigator

### Via linha de comando (xcodebuild)

```bash
# Testes unitários
xcodebuild test \
  -project LexendScholar.xcodeproj \
  -scheme LexendScholar \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' \
  -only-testing:LexendScholarTests

# Testes de UI
xcodebuild test \
  -project LexendScholar.xcodeproj \
  -scheme LexendScholar \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' \
  -only-testing:LexendScholarUITests

# Todos os testes com relatório de cobertura
xcodebuild test \
  -project LexendScholar.xcodeproj \
  -scheme LexendScholar \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult
```

---

## Cobertura de Código

Para gerar relatório de cobertura em formato legível:

```bash
xcrun xccov view --report --json TestResults.xcresult > coverage.json
xcrun xccov view --report TestResults.xcresult
```

Meta de cobertura mínima: **70%** para lógica de negócio (calculadoras, validadores, transformações de dados).

---

## Dependências de Teste

Adicione ao `Package.swift` ou via SPM no Xcode:

```swift
dependencies: [
    // Mock de rede para testes Supabase
    .package(url: "https://github.com/nicklockwood/SwiftyMocky", from: "4.2.0"),
]
```

---

## Convenções

- Cada teste deve ser independente (`setUp` e `tearDown` corretos)
- Dados de teste devem usar fixtures locais, nunca o banco de produção
- Usar `XCTAssertEqual`, `XCTAssertTrue`, `XCTAssertNil` com mensagens descritivas
- Nomenclatura: `test<Acao><CondicaoEsperada>` (ex: `testLoginComSenhaInvalidaExibeErro`)
- UI tests devem usar `accessibility identifier` — não rótulos de texto — para localizar elementos
