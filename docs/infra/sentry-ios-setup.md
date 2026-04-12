# LS-13 — Configurar Sentry para iOS App

## Visão Geral

O Sentry monitora crashes, erros e performance do app iOS do Lexend Scholar. Esta documentação cobre a instalação via Swift Package Manager, configuração do DSN, upload de símbolos de debug e integração com Xcode Cloud.

## Criar Projeto no Sentry

1. Acessar [sentry.io](https://sentry.io) → **Organization: Lexend Scholar**
2. **Projects → Create Project → iOS**
3. Nome: `lexend-scholar-ios`
4. Anotar o DSN gerado: `https://<key>@<org>.ingest.sentry.io/<project-id>`

## Instalação via Swift Package Manager

No Xcode: **File → Add Package Dependencies...**

```
URL: https://github.com/getsentry/sentry-cocoa
Version: >= 8.30.0
```

Ou via `Package.swift` (se usar XcodeGen/SPM):

```swift
// Package.swift
dependencies: [
    .package(
        url: "https://github.com/getsentry/sentry-cocoa",
        from: "8.30.0"
    )
],
targets: [
    .target(
        name: "LexendScholar",
        dependencies: [
            .product(name: "Sentry", package: "sentry-cocoa")
        ]
    )
]
```

## Inicialização no App

```swift
// LexendScholarApp.swift
import SwiftUI
import Sentry

@main
struct LexendScholarApp: App {
    init() {
        configureSentry()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func configureSentry() {
        SentrySDK.start { options in
            // DSN carregado de Info.plist (configurado por ambiente)
            options.dsn = Bundle.main.infoDictionary?["SENTRY_DSN"] as? String

            // Ambiente baseado no build configuration
            #if DEBUG
            options.environment = "development"
            options.debug = true
            options.tracesSampleRate = 1.0  // 100% em dev
            #elseif STAGING
            options.environment = "staging"
            options.tracesSampleRate = 0.5
            #else
            options.environment = "production"
            options.tracesSampleRate = 0.1  // 10% em prod
            #endif

            // Profiling (iOS 16+)
            options.profilesSampleRate = 0.1

            // Capturar informações adicionais
            options.attachScreenshot = true
            options.attachViewHierarchy = true

            // Antes de enviar — redactar dados sensíveis
            options.beforeSend = { event in
                // Não enviar dados PII
                event.user?.email = nil
                event.user?.ipAddress = nil
                return event
            }

            // Configurar release para matching com source maps
            options.releaseName = Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String
        }
    }
}
```

## Configurar DSN por Ambiente no Info.plist

Adicionar ao `Info.plist`:

```xml
<key>SENTRY_DSN</key>
<string>$(SENTRY_DSN)</string>
```

Configurar o valor em cada Build Configuration no Xcode:
- **Debug**: DSN do projeto `lexend-scholar-ios-dev`
- **Release (Staging)**: DSN do projeto `lexend-scholar-ios-staging`
- **Release**: DSN do projeto `lexend-scholar-ios-prod`

## Identificação de Usuário (sem PII)

```swift
// Após login bem-sucedido — usar apenas IDs, nunca emails
func configureUserContext(userId: UUID, schoolId: UUID, role: String) {
    SentrySDK.setUser(User(userId: userId.uuidString))

    SentrySDK.configureScope { scope in
        scope.setContext(value: [
            "school_id": schoolId.uuidString,
            "role": role,
        ], key: "app")
    }
}

// Ao fazer logout
func clearUserContext() {
    SentrySDK.setUser(nil)
    SentrySDK.configureScope { scope in
        scope.removeContext(key: "app")
    }
}
```

## Captura Manual de Erros

```swift
// Capturar erro de rede
func handleAPIError(_ error: Error, context: [String: Any] = [:]) {
    SentrySDK.capture(error: error) { scope in
        scope.setContext(value: context, key: "request")
    }
}

// Capturar mensagem informativa
func logEvent(_ message: String, level: SentryLevel = .info) {
    SentrySDK.capture(message: message) { scope in
        scope.setLevel(level)
    }
}

// Breadcrumbs para rastreamento de ação do usuário
func trackNavigation(to screen: String) {
    let crumb = Breadcrumb(level: .info, category: "navigation")
    crumb.message = "Navigated to \(screen)"
    SentrySDK.addBreadcrumb(crumb)
}
```

## Performance Monitoring

```swift
// Rastrear operação assíncrona
func fetchStudents(schoolId: UUID) async throws -> [Student] {
    let transaction = SentrySDK.startTransaction(
        name: "fetch-students",
        operation: "db.query"
    )

    defer { transaction.finish() }

    do {
        let students = try await supabase
            .from("students")
            .select()
            .eq("school_id", value: schoolId.uuidString)
            .execute()
            .value as [Student]

        return students
    } catch {
        transaction.finish(status: .internalError)
        throw error
    }
}
```

## Upload de dSYMs (Símbolos de Debug)

Para que o Sentry consiga desimbolizar crash reports:

### Via Fastlane / Script Xcode Cloud

Adicionar ao `ci_post_xcodebuild.sh` do Xcode Cloud:

```bash
#!/bin/bash
# ci_post_xcodebuild.sh — Upload dSYMs para Sentry

if [ "$CI_XCODEBUILD_ACTION" = "archive" ]; then
    echo "Uploading dSYMs to Sentry..."

    # Instalar sentry-cli
    curl -sL https://sentry.io/get-cli/ | bash

    # Upload dos dSYMs do archive
    sentry-cli --auth-token "$SENTRY_AUTH_TOKEN" \
        debug-files upload \
        --org lexend-scholar \
        --project lexend-scholar-ios \
        "$CI_ARCHIVE_PATH"

    echo "dSYMs uploaded successfully"
fi
```

### Variáveis necessárias no Xcode Cloud

| Variável          | Valor                    |
|-------------------|--------------------------|
| `SENTRY_DSN`      | DSN do projeto Sentry    |
| `SENTRY_AUTH_TOKEN` | Token de auth Sentry   |
| `SENTRY_ORG`      | `lexend-scholar`         |

## Alertas Configurados

Configurar em Sentry → **Alerts → Create Alert**:

| Alert                        | Condição                       | Destino       |
|------------------------------|-------------------------------|---------------|
| Crash rate spike             | > 1% de sessões com crash     | Slack #alerts |
| New issue (alta prioridade)  | Novo erro com > 10 ocorrências | Slack #alerts |
| Performance degradada        | P95 > 5s em qualquer tela     | Slack #alerts |
| Aumento de erros             | +50% em 1 hora                | Slack + email |

## Integração com Linear

Configurar em Sentry → **Settings → Integrations → Linear**:

- Organização: `Lexend Scholar`
- Projeto padrão: `LS` (Lexend Scholar)
- Permite criar issues Linear diretamente de erros Sentry

## Checklist

- [ ] Projeto Sentry `lexend-scholar-ios` criado
- [ ] SDK adicionado via SPM
- [ ] Inicialização configurada com ambientes (dev/staging/prod)
- [ ] DSN configurado por Build Configuration
- [ ] Upload de dSYMs via `ci_post_xcodebuild.sh`
- [ ] `SENTRY_AUTH_TOKEN` configurado no Xcode Cloud
- [ ] Alertas de crash rate e performance configurados
- [ ] Integração Linear habilitada
- [ ] Dados PII (email, IP) removidos no `beforeSend`

## Referências

- `docs/infra/xcode-cloud.md` — CI/CD Xcode Cloud
- `docs/infra/api-monitoring.md` — monitoramento de API
- [Sentry iOS Docs](https://docs.sentry.io/platforms/apple/)
- [sentry-cli](https://docs.sentry.io/product/cli/)
