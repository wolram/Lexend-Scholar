# CI/CD — LexendScholar

Documentação completa do pipeline de integração e entrega contínua do Lexend Scholar.

---

## Visão Geral

| Plataforma | Ferramenta | Uso |
|---|---|---|
| iOS | Xcode Cloud | Build, test, distribuição TestFlight |
| Web | Vercel | Deploy automático do website e Next.js |
| Lint/Validação | GitHub Actions | SwiftLint + HTMLHint em PRs |

---

## Xcode Cloud (iOS)

### Configuração do Workflow

O Xcode Cloud é configurado diretamente pelo Xcode IDE em **Product → Xcode Cloud → Create Workflow**, vinculado ao repositório GitHub do projeto.

**Workflows configurados:**

| Workflow | Trigger | Ação |
|---|---|---|
| `Main Build` | Push para `main` | Build + Test + TestFlight (produção) |
| `Feature Build` | Push para `feature/*` | Build + Test + TestFlight (beta) |
| `PR Validation` | Pull Request aberto | Build + Test (sem distribuição) |

### Variáveis de Ambiente no Xcode Cloud

Configure em **Xcode Cloud → Settings → Environment Variables**:

```
APP_STORE_CONNECT_API_KEY_ID     → ID da chave da App Store Connect
APP_STORE_CONNECT_ISSUER_ID      → Issuer ID da conta Apple Developer
SUPABASE_URL                      → URL do projeto Supabase (staging/prod por branch)
SUPABASE_ANON_KEY                 → Chave anon do Supabase
SENTRY_DSN                        → DSN do Sentry para iOS
```

### Scripts de CI (ci_scripts/)

Os scripts são executados automaticamente pelo Xcode Cloud:

| Script | Quando executa |
|---|---|
| `ci_scripts/ci_post_clone.sh` | Após clone do repo — instala XcodeGen, SwiftLint, gera .xcodeproj |
| `ci_scripts/ci_pre_xcodebuild.sh` | Antes do build — roda SwiftLint |
| `ci_scripts/ci_post_xcodebuild.sh` | Após o build — verifica status e coleta artefatos |

### Signing & Capabilities

O Xcode Cloud gerencia certificates e provisioning profiles automaticamente via **Managed Signing** da Apple. Não é necessário configurar manualmente.

---

## GitHub Actions (iOS CD Complementar)

Para distribuição via `xcodebuild` diretamente (fallback ou uso sem Xcode Cloud):

**Arquivo:** `.github/workflows/ios-cd.yml`

Trigger: push para `main` ou `feature/*`

Passos:
1. Checkout do código
2. Setup do Ruby + Fastlane (opcional)
3. `xcodegen generate`
4. `xcodebuild archive`
5. Export IPA e upload para TestFlight via `altool` ou `notarytool`

---

## Vercel (Web)

**Arquivo:** `vercel.json` na raiz do projeto.

- **Branch `main`** → deploy de produção em `lexendscholar.vercel.app`
- **Pull Requests** → preview deployments automáticos com URL única

---

## Notificações

- **Xcode Cloud:** Configurar em Xcode Cloud → Settings → Notifications (email nativo da Apple)
- **GitHub Actions:** Usar action `slackapi/slack-github-action` para notificações de build

---

## Fluxo Completo por Branch

```
feature/xyz → push → GitHub Actions (lint) + Xcode Cloud (build+test+beta TestFlight)
main        → push → GitHub Actions (lint) + Xcode Cloud (build+test+prod TestFlight)
PR aberto   → GitHub Actions (lint) + Xcode Cloud (build+test) + Vercel (preview)
```
