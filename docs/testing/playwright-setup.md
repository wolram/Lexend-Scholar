# Playwright E2E Setup — Lexend Scholar

## Visão Geral

O Playwright cobre testes E2E do website público (marketing) e do web app (painel escolar). Os testes são organizados por funcionalidade e executados em múltiplos perfis de usuário (diretor, professor, secretário).

---

## Pré-requisitos

- Node.js 20+
- Playwright 1.44+
- Instância do Supabase acessível (staging ou local via `supabase start`)
- Variáveis de ambiente configuradas (ver seção abaixo)

---

## Instalação

```bash
# Instalar dependências
cd tests/e2e
npm install

# Instalar browsers do Playwright
npx playwright install --with-deps chromium firefox webkit
```

### package.json mínimo para o diretório `tests/e2e`

```json
{
  "name": "lexend-scholar-e2e",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "test": "playwright test",
    "test:smoke": "playwright test login.spec.ts",
    "test:headed": "playwright test --headed",
    "test:debug": "playwright test --debug",
    "report": "playwright show-report ../../playwright-report"
  },
  "devDependencies": {
    "@playwright/test": "^1.44.0",
    "typescript": "^5.4.0"
  }
}
```

---

## Variáveis de Ambiente

Crie um arquivo `.env.test` na raiz do projeto (nunca comitar):

```env
# URLs
BASE_URL=http://localhost:3000
WEBSITE_URL=http://localhost:4000

# Credenciais de teste — usuários seed do ambiente staging
TEST_DIRETOR_EMAIL=diretor@lexend-test.com.br
TEST_DIRETOR_PASSWORD=LexendTest@2025!

TEST_PROFESSOR_EMAIL=professor@lexend-test.com.br
TEST_PROFESSOR_PASSWORD=LexendTest@2025!

TEST_SECRETARIO_EMAIL=secretario@lexend-test.com.br
TEST_SECRETARIO_PASSWORD=LexendTest@2025!

# Supabase staging
NEXT_PUBLIC_SUPABASE_URL=https://<staging-project>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<staging-anon-key>
```

---

## Estrutura de Arquivos

```
tests/
└── e2e/
    ├── playwright.config.ts      # Configuração central
    ├── global-setup.ts           # Autenticação prévia por perfil
    ├── .auth/                    # Sessões salvas (git-ignoradas)
    │   ├── diretor.json
    │   ├── professor.json
    │   └── secretario.json
    ├── login.spec.ts             # Smoke: login por todos os perfis
    ├── cadastro-aluno.spec.ts    # E2E: cadastro completo de aluno
    ├── frequencia.spec.ts        # E2E: registro de frequência
    ├── notas-boletim.spec.ts     # E2E: lançamento de notas
    └── declaracao-matricula.spec.ts  # E2E: emissão de declaração
```

### .gitignore recomendado

```
tests/e2e/.auth/
tests/e2e/node_modules/
playwright-report/
test-results/
```

---

## Projetos Playwright

| Nome | Dispositivo | Perfil | Uso |
|------|------------|--------|-----|
| `website-chrome` | Desktop Chrome | Anônimo | Testa páginas públicas |
| `website-mobile` | iPhone 14 | Anônimo | Responsividade |
| `app-diretor` | Desktop Chrome | Diretor | Funcionalidades de gestão |
| `app-professor` | Desktop Chrome | Professor | Turmas, frequência, notas |
| `app-secretario` | Desktop Chrome | Secretário | Cadastros, declarações |
| `smoke-firefox` | Desktop Firefox | Anônimo | Smoke cross-browser |

---

## Executando os Testes

```bash
# Todos os testes
npx playwright test

# Apenas smoke tests de login
npx playwright test login.spec.ts

# Testes de um projeto específico
npx playwright test --project=app-diretor

# Modo interativo (UI)
npx playwright test --ui

# Debug de um teste específico
npx playwright test cadastro-aluno.spec.ts --debug

# Gerar relatório HTML
npx playwright show-report
```

---

## Estratégia de Autenticação

O `global-setup.ts` autentica cada perfil **uma vez** antes dos testes e salva o estado da sessão em `.auth/*.json`. Isso evita múltiplos logins e acelera a execução.

O estado inclui:
- Cookie de sessão Supabase (`sb-<project>-auth-token`)
- `localStorage` com o JWT de acesso

Para regenerar as sessões (ex: após expiração):

```bash
npx playwright test --project=setup-auth
```

---

## Dados de Teste

Os testes E2E dependem de fixtures de dados seed no banco de staging. Veja:
- `tests/fixtures/escola.ts` — escola e usuários de teste
- `tests/fixtures/alunos.ts` — alunos, turmas e matrículas

Para fazer seed do banco de staging:

```bash
npx ts-node tests/fixtures/seed.ts --env staging
```

---

## Integração com CI

Os testes E2E rodam no workflow `.github/workflows/coverage.yml`. No CI:

- `retries: 2` para flakiness de rede
- Workers limitados a 2 (custo de concorrência)
- Relatório JUnit publicado como artefato
- Screenshots e videos de falha como artefatos

Ver documentação completa de CI em `docs/testing/coverage-ci.md`.
