# Cobertura de Testes e CI/CD — Lexend Scholar

## Visão Geral

A integração de cobertura de código está configurada no workflow `.github/workflows/coverage.yml` e cobre três camadas:

| Camada | Ferramenta | Runner | Meta mínima |
|--------|-----------|--------|-------------|
| E2E Web | Playwright | ubuntu-latest | Todos os specs verdes |
| Unitários Web (TS) | Vitest | ubuntu-latest | Lines ≥ 60%, Branches ≥ 50% |
| Unitários iOS (Swift) | XCTest + xcodebuild | macos-14 | Lines ≥ 50% |

---

## Jobs do Workflow

### 1. `e2e-tests` — Playwright E2E

Executa todos os specs em `tests/e2e/` contra o webapp em staging. Publica:
- Relatório HTML como artefato (`playwright-report-*`)
- JUnit XML como artefato (`junit-results-*`)
- Screenshots/videos de falha como artefato (`playwright-failures-*`)

### 2. `coverage-webapp` — Vitest + cobertura TS

Executa `npm run test:coverage` no diretório `webapp/` e verifica percentuais mínimos. Publica comentário automático no PR com o delta de cobertura (via `davelosert/vitest-coverage-report-action`).

### 3. `coverage-ios` — XCTest + xcodebuild

Executa os testes unitários iOS no simulador iPhone 15 (iOS 17.5) com `-enableCodeCoverage YES` e valida cobertura mínima de 50% de linhas no target principal.

### 4. `coverage-summary` — Consolidação

Depende dos 3 jobs anteriores. Exibe resumo e falha se qualquer job falhou.

---

## Secrets Necessários

Configure os secrets abaixo em **Settings → Secrets and variables → Actions** do repositório:

| Secret | Descrição |
|--------|-----------|
| `STAGING_SUPABASE_URL` | URL do projeto Supabase de staging |
| `STAGING_SUPABASE_ANON_KEY` | Chave pública (anon) do Supabase staging |
| `STAGING_SUPABASE_SERVICE_ROLE_KEY` | Chave de service role (para seed) |
| `TEST_DIRETOR_EMAIL` | E-mail do usuário de teste com papel Diretor |
| `TEST_DIRETOR_PASSWORD` | Senha do usuário Diretor |
| `TEST_PROFESSOR_EMAIL` | E-mail do usuário Professor |
| `TEST_PROFESSOR_PASSWORD` | Senha do usuário Professor |
| `TEST_SECRETARIO_EMAIL` | E-mail do usuário Secretário |
| `TEST_SECRETARIO_PASSWORD` | Senha do usuário Secretário |

---

## Configuração do Vitest (webapp)

Adicione ao `webapp/vitest.config.ts`:

```ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'json-summary', 'html'],
      reportsDirectory: './coverage',
      thresholds: {
        lines: 60,
        branches: 50,
        functions: 60,
        statements: 60,
      },
      exclude: [
        'node_modules/**',
        'src/test/**',
        '**/*.d.ts',
        '**/*.config.*',
        '**/migrations/**',
      ],
    },
  },
});
```

Adicione ao `webapp/package.json`:

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage"
  }
}
```

---

## Executando Localmente

```bash
# Testes unitários web com cobertura
cd webapp
npm run test:coverage
open coverage/index.html

# Testes E2E
cd tests/e2e
npx playwright test

# Testes iOS com cobertura
xcodebuild test \
  -project LexendScholar.xcodeproj \
  -scheme LexendScholar \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# Ver relatório de cobertura iOS
xcrun xccov view --report TestResults.xcresult
open TestResults.xcresult  # Abre no Xcode
```

---

## Gatilhos do Workflow

| Gatilho | Comportamento |
|---------|--------------|
| `push` em `main` ou `develop` | Todos os jobs |
| `pull_request` para `main` | Todos os jobs + comentário de cobertura no PR |
| `workflow_dispatch` | Manual, com opção de pular E2E |

---

## Artefatos Gerados

| Artefato | Retenção | Conteúdo |
|----------|----------|---------|
| `playwright-report-*` | 14 dias | Relatório HTML interativo |
| `junit-results-*` | 14 dias | XML compatível com JUnit |
| `playwright-failures-*` | 7 dias | Screenshots + vídeos de falha |
| `coverage-webapp-*` | 14 dias | Relatório HTML Vitest/v8 |
| `xctest-results-*` | 14 dias | Bundle `.xcresult` |
| `ios-coverage-*` | 14 dias | JSON de cobertura iOS |

---

## Badges de Status

Adicione ao `README.md`:

```markdown
![Tests & Coverage](https://github.com/<org>/lexend-scholar/actions/workflows/coverage.yml/badge.svg)
```
