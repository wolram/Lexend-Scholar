# Setup Local — LexendScholar

Guia completo para configurar o ambiente de desenvolvimento local do Lexend Scholar do zero. Siga os passos na ordem indicada.

---

## Pré-requisitos de Sistema

| Ferramenta | Versão mínima | Como instalar |
|---|---|---|
| macOS | Sequoia 15.0+ | Atualização de sistema |
| Xcode | 16.0+ | App Store ou [developer.apple.com](https://developer.apple.com/xcode/) |
| Command Line Tools | Xcode 16+ | `xcode-select --install` |
| Homebrew | 4.0+ | [brew.sh](https://brew.sh) |
| Node.js | 22 LTS | `brew install node` |
| Git | 2.40+ | `brew install git` |

> **Nota:** O projeto usa Swift 6 e iOS 18+ APIs. Xcode 16+ é obrigatório.

---

## 1. Clone do Repositório

```bash
# Clone via HTTPS (recomendado para contribuidores externos)
git clone https://github.com/lexendscholar/lexend-scholar.git
cd lexend-scholar

# Clone via SSH (recomendado para membros do time — configure SSH key antes)
git clone git@github.com:lexendscholar/lexend-scholar.git
cd lexend-scholar
```

---

## 2. Setup Automatizado (recomendado)

O `Makefile` automatiza toda a instalação de dependências:

```bash
make setup
```

Este comando instala:
- XcodeGen (gera o `.xcodeproj` a partir do `project.yml`)
- SwiftLint (lint de Swift)
- `serve` (servidor local para o website)
- HTMLHint (lint de HTML)
- Vercel CLI (deploy do website)
- Configura os git hooks (pre-commit SwiftLint)

---

## 3. Setup Manual (alternativo)

Se preferir instalar manualmente:

### 3.1 Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3.2 XcodeGen

```bash
brew install xcodegen
```

### 3.3 SwiftLint

```bash
brew install swiftlint
swiftlint version  # deve exibir 0.57.0 ou superior
```

### 3.4 Node.js e ferramentas web

```bash
brew install node
npm install -g serve htmlhint vercel
```

---

## 4. Configuração do Projeto iOS

### 4.1 Gerar o projeto Xcode

O repositório **não versiona** o `.xcodeproj` diretamente — ele é gerado a partir do `project.yml` usando XcodeGen.

```bash
# Gerar e abrir no Xcode em um único comando:
make ios

# Ou apenas gerar (sem abrir):
make generate
```

### 4.2 Abrir o projeto

```bash
open LexendScholar.xcodeproj
```

### 4.3 Selecionar simulador

No Xcode, selecione o target **LexendScholar** e um simulador **iPhone 16 Pro (iOS 18+)** na barra de ferramentas.

### 4.4 Primeira compilação

Pressione `⌘R` no Xcode ou execute:

```bash
make build-ios
```

A primeira build pode levar 3-5 minutos enquanto compila todas as dependências.

---

## 5. Variáveis de Ambiente (iOS)

O app iOS lê suas configurações via um arquivo `.env.xcconfig` que **não é commitado** no repositório por segurança.

### 5.1 Criar o arquivo de configuração

```bash
cp iosapp/Config/Local.xcconfig.example iosapp/Config/Local.xcconfig
```

### 5.2 Preencher as variáveis

Edite `iosapp/Config/Local.xcconfig` com os valores do projeto Supabase de desenvolvimento:

```
// Local.xcconfig — não commitar este arquivo
SUPABASE_URL = https://xyzabcdef.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SENTRY_DSN = https://abc123@o0.ingest.sentry.io/0
APP_ENV = development
```

Os valores de desenvolvimento estão no **1Password** do time, cofre "Engineering", item "LexendScholar - Dev Secrets".

### 5.3 Verificar a configuração

No Xcode, vá em **Product → Scheme → Edit Scheme** e confirme que o scheme usa a configuração `Debug`.

---

## 6. Setup do Banco de Dados Local (Supabase)

Para desenvolvimento sem dependência da API de produção, você pode rodar o Supabase localmente:

### 6.1 Instalar Supabase CLI

```bash
brew install supabase/tap/supabase
```

### 6.2 Iniciar instância local

```bash
cd lexend-scholar
supabase start
```

O comando sobe um PostgreSQL + GoTrue + Storage localmente via Docker. Na primeira vez, faz download de ~2GB de imagens.

```
# Output esperado após supabase start:
Started supabase local development setup.

         API URL: http://127.0.0.1:54321
     GraphQL URL: http://127.0.0.1:54321/graphql/v1
  S3 Storage URL: http://127.0.0.1:54321/storage/v1/s3
          DB URL: postgresql://postgres:postgres@127.0.0.1:54322/postgres
      Studio URL: http://127.0.0.1:54323
    Inbucket URL: http://127.0.0.1:54324
```

### 6.3 Aplicar migrations

```bash
supabase db push
```

### 6.4 Seed de dados de desenvolvimento

```bash
supabase db reset  # aplica migrations + seed
```

### 6.5 Atualizar Local.xcconfig para usar Supabase local

```
SUPABASE_URL = http://127.0.0.1:54321
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRFA0NiK7NRL0tIfK78fKkC8G44oMKdU8HFi_V6k_mE
```

> A chave anon acima é o valor padrão do Supabase local (não é secreta).

---

## 7. Setup do Website (Web)

### 7.1 Estrutura do website

O website atual é composto de páginas HTML estáticas com Tailwind CSS via CDN, localizadas em `website/`.

```
website/
├── index.html      ← página principal (landing)
├── home.html
├── about.html
├── pricing.html
├── contact.html
├── blog.html
├── careers.html
└── 404.html
```

### 7.2 Rodar localmente

```bash
make web
# ou diretamente:
npx serve website --listen 3000
```

Acesse em: http://localhost:3000

### 7.3 Editar páginas

Edite os arquivos HTML em `website/` diretamente. O `serve` serve os arquivos estáticos — recarregue o browser para ver as mudanças.

### 7.4 Lint do HTML

```bash
make lint-html
```

---

## 8. Git Hooks

O projeto usa git hooks para garantir qualidade antes de cada commit.

### 8.1 Instalar hooks

```bash
make install-hooks
# ou:
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
```

### 8.2 O que o pre-commit faz

O hook `.githooks/pre-commit` roda SwiftLint nos arquivos Swift staged. Se houver erros, o commit é bloqueado.

### 8.3 Pular o hook em emergências (não recomendado)

```bash
git commit --no-verify -m "mensagem"
```

---

## 9. Rodar os Testes

```bash
# Todos os testes iOS
make test-ios

# Com output detalhado (modo CI)
make test-ios-ci
```

---

## 10. Lint Completo

```bash
# Swift + HTML
make lint

# Apenas Swift
make lint-swift

# Autocorrigir Swift
make lint-swift-fix

# Apenas HTML
make lint-html
```

---

## 11. Workflow de Desenvolvimento

Fluxo recomendado para uma nova feature:

```bash
# 1. Criar branch a partir da main atualizada
git checkout main && git pull origin main
git checkout -b feature/minha-feature

# 2. Gerar projeto Xcode (sempre que o project.yml mudar)
make generate

# 3. Desenvolver, commitar (hooks rodam automaticamente)
git add <arquivos>
git commit -m "feat: descrição da mudança"

# 4. Rodar lint e testes antes do PR
make lint
make test-ios

# 5. Push e abrir PR
git push origin feature/minha-feature
# → Vercel cria preview deployment automático
# → GitHub Actions roda lint
# → Xcode Cloud roda build + testes
```

---

## 12. Comandos Úteis (referência rápida)

```bash
make help          # lista todos os comandos disponíveis
make setup         # instala todas as dependências
make ios           # gera .xcodeproj e abre no Xcode
make web           # serve o website em localhost:3000
make test-ios      # roda testes iOS no simulador
make lint          # roda SwiftLint + HTMLHint
make lint-swift-fix # autocorrige SwiftLint
make build-ios     # compila o app (sem rodar)
make deploy-web    # deploy do website para Vercel
make ci            # pipeline completa (lint + build + test)
make clean         # limpa arquivos de build
make version       # exibe versões das ferramentas
make simulators    # lista simuladores disponíveis
```

---

## Troubleshooting

### "xcodegen: command not found"

```bash
brew install xcodegen
# Se Homebrew não estiver no PATH:
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### "LexendScholar.xcodeproj not found"

O `.xcodeproj` precisa ser gerado antes de abrir no Xcode:

```bash
make generate
```

### "Supabase connection refused"

Verifique se está usando a URL correta no `Local.xcconfig`:
- Para Supabase local: `http://127.0.0.1:54321`
- Para staging: use a URL do projeto Supabase de dev (ver 1Password)

### Testes falhando por simulador não encontrado

```bash
make simulators   # lista os simuladores disponíveis
# No Makefile, altere SIM_NAME para um disponível na sua máquina
```

### SwiftLint com muitos warnings após pull

```bash
make lint-swift-fix   # autocorrige o que for possível
```
