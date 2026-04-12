# Guia de Onboarding de Engenharia — LexendScholar

Bem-vindo ao time de engenharia do Lexend Scholar! Este guia cobre tudo que você precisa para estar produtivo no primeiro dia.

---

## O que é o LexendScholar?

O **Lexend Scholar** é um sistema de gestão escolar que combina um app iOS nativo com um portal web, ambos integrados com Supabase como backend. O produto serve escolas de ensino básico para gerenciar alunos, turmas, notas e comunicação entre escola e família.

---

## Stack de Tecnologia

| Camada | Tecnologia |
|---|---|
| App iOS | Swift 6, SwiftUI, iOS 18+, XcodeGen |
| Website | HTML estático, Tailwind CSS via CDN |
| Backend | Supabase (PostgreSQL, Auth, Storage, Edge Functions) |
| CI/CD iOS | Xcode Cloud + GitHub Actions |
| CI/CD Web | Vercel (deploy automático) |
| Monitoramento | Sentry (iOS) |
| Gerenciamento de issues | Linear |
| Repositório | GitHub |

---

## Acesso e Contas (Semana 1)

Solicite ao seu manager os seguintes acessos:

### Obrigatórios antes do primeiro dia
- [ ] **GitHub** — Adicionar à organização `lexendscholar` e ao repositório `lexend-scholar`
- [ ] **Linear** — Convite para o workspace (você receberá por email)
- [ ] **Supabase** — Acesso ao projeto de desenvolvimento (ambiente dev)
- [ ] **1Password** — Convite para o cofre "Engineering" (onde ficam os secrets de dev)
- [ ] **Slack** — Convite para os canais `#eng`, `#builds`, `#eng-alerts`

### Obrigatórios na primeira semana
- [ ] **Apple Developer Program** — Adicionar ao time como Developer (para builds no Xcode Cloud)
- [ ] **App Store Connect** — Acesso para ver builds e TestFlight
- [ ] **Vercel** — Acesso ao projeto `lexend-scholar`
- [ ] **Sentry** — Acesso ao projeto iOS para ver erros em produção

---

## Setup do Ambiente Local

Siga o guia completo em [`docs/eng/setup-local.md`](./setup-local.md).

**Resumo rápido (para quem já tem Xcode e Homebrew):**

```bash
# 1. Clone o repositório
git clone git@github.com:lexendscholar/lexend-scholar.git
cd lexend-scholar

# 2. Setup completo (instala XcodeGen, SwiftLint, Node tools, git hooks)
make setup

# 3. Pegar secrets de dev no 1Password
#    Cofre: Engineering → "LexendScholar - Dev Secrets"
#    Criar: iosapp/Config/Local.xcconfig com os valores

# 4. Gerar e abrir o projeto iOS
make ios

# 5. Rodar o website localmente
make web   # → http://localhost:3000
```

---

## Estrutura do Repositório

```
lexend-scholar/
├── app/                    ← Código Swift do app iOS (lógica de negócio)
├── iosapp/                 ← Configurações iOS (xcconfig, assets, Info.plist)
├── website/                ← Website estático (HTML/Tailwind)
├── webapp/                 ← Web app (futuro Next.js)
├── android/                ← App Android (futuro)
├── sql/                    ← Scripts SQL e migrations do Supabase
│   └── migrations/         ← Migrations numeradas (001_*.sql)
├── tests/                  ← Testes do app iOS (XCTest)
├── docs/                   ← Toda a documentação do projeto
│   ├── eng/                ← Documentação de engenharia
│   │   ├── ci-cd.md        ← Pipeline de CI/CD
│   │   ├── setup-local.md  ← Setup do ambiente local
│   │   ├── rollback-procedure.md ← Procedimentos de rollback
│   │   └── onboarding.md   ← Este arquivo
│   ├── infra/              ← Infraestrutura e segurança
│   ├── adr/                ← Architecture Decision Records
│   └── ...
├── ci_scripts/             ← Scripts para Xcode Cloud (post-clone, pre-build)
├── .github/
│   └── workflows/          ← GitHub Actions (lint, CD, notificações, Vercel)
├── .githooks/
│   └── pre-commit          ← Hook de pre-commit (SwiftLint)
├── .swiftlint.yml          ← Configuração do SwiftLint
├── project.yml             ← Configuração do XcodeGen (gera o .xcodeproj)
├── vercel.json             ← Configuração do Vercel (website)
└── Makefile                ← Comandos de desenvolvimento (make help)
```

---

## Processo de Desenvolvimento

### Fluxo de trabalho

```
1. Issue no Linear → 2. Branch feature/* → 3. Desenvolvimento → 4. PR → 5. Review → 6. Merge → 7. Deploy
```

### Branches

| Branch | Propósito | Deploy |
|---|---|---|
| `main` | Código de produção | Vercel prod + TestFlight "Produção" |
| `feature/xyz` | Nova feature em desenvolvimento | Vercel preview + TestFlight "Beta" |

### Convenções de commit

Seguimos [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: LS-XX descrição curta da feature
fix: LS-XX correção do bug X
refactor: LS-XX refatoração do módulo Y
docs: LS-XX atualizar documentação de Z
test: LS-XX adicionar testes para W
chore: LS-XX tarefa de manutenção
```

**Obrigatório:** sempre incluir o identificador do issue do Linear (ex: `LS-42`).

### Criando uma nova feature

```bash
# 1. Sempre partir de uma main atualizada
git checkout main
git pull origin main

# 2. Criar branch com prefixo feature/
git checkout -b feature/LS-42-nome-da-feature

# 3. Gerar projeto se o project.yml mudou
make generate

# 4. Desenvolver e commitar
git add <arquivos específicos>
git commit -m "feat: LS-42 descrição da mudança"
# → O pre-commit hook roda SwiftLint automaticamente

# 5. Rodar lint e testes localmente antes do PR
make lint
make test-ios

# 6. Push e abrir PR no GitHub
git push origin feature/LS-42-nome-da-feature
# → GitHub Actions roda lint
# → Xcode Cloud roda build + testes
# → Vercel cria preview deployment do website
```

### Abrindo um Pull Request

- Título: `feat: LS-XX Título do issue`
- Description: o que mudou, por quê, como testar
- Sempre linkar o issue do Linear no corpo do PR
- Mínimo de **1 review** antes de mergear para `main`
- Todos os checks de CI precisam estar verdes

---

## CI/CD Pipeline

### Para o App iOS

```
Push/PR
   │
   ├── GitHub Actions
   │   ├── SwiftLint (lint.yml)
   │   └── Notificações de build (build-notifications.yml)
   │
   └── Xcode Cloud (configurado no Xcode IDE)
       ├── main → TestFlight grupo "Produção"
       └── feature/* → TestFlight grupo "Beta Testers"
```

### Para o Website

```
Push para main    → Vercel deploy automático (produção)
PR aberto        → Vercel preview deployment (URL única no comentário do PR)
```

**Documentação completa:** [`docs/eng/ci-cd.md`](./ci-cd.md)

---

## Arquitetura do App iOS

### Padrão de arquitetura: MVVM + SwiftUI

```
View (SwiftUI)
  └── ViewModel (@Observable / @StateObject)
        └── Repository (protocolo)
              └── SupabaseClient (networking)
```

### Módulos principais

| Módulo | Responsabilidade |
|---|---|
| `Authentication` | Login, logout, sessão de usuário via Supabase Auth |
| `Students` | Listagem, cadastro e edição de alunos |
| `Grades` | Registro e consulta de notas |
| `Classes` | Gestão de turmas e horários |
| `Notifications` | Push notifications e alertas para pais |
| `Dashboard` | Tela principal com métricas da escola |

### Adicionando um novo módulo

1. Criar pasta em `app/Features/NomeDoModulo/`
2. Estrutura padrão:
   ```
   NomeDoModulo/
   ├── Views/
   │   └── NomeDoModuloView.swift
   ├── ViewModels/
   │   └── NomeDoModuloViewModel.swift
   ├── Models/
   │   └── NomeDoModulo.swift
   └── Repositories/
       └── NomeDoModuloRepository.swift
   ```
3. Adicionar ao `project.yml` se necessário e rodar `make generate`
4. Adicionar testes em `tests/`

---

## Banco de Dados (Supabase)

### Convenções de banco

- Tabelas em `snake_case`, plural: `students`, `grade_entries`, `class_schedules`
- Colunas: `snake_case`
- Primary keys: `id uuid DEFAULT gen_random_uuid()`
- Timestamps: `created_at timestamptz DEFAULT now()`, `updated_at timestamptz`
- Soft delete: coluna `deleted_at timestamptz` (nunca deletar fisicamente)

### Adicionando uma migration

```bash
# Criar arquivo de migration (use o próximo número em sequência)
# Formato: NNN_descricao_da_mudanca.sql

# Exemplo:
touch sql/migrations/007_add_parent_contacts.sql

# Escrever o SQL da migration no arquivo
# Sempre incluir um arquivo de rollback:
touch sql/migrations/007_add_parent_contacts.down.sql

# Aplicar localmente (com Supabase CLI rodando)
supabase db push
```

### Testando permissões (RLS)

Sempre teste as Row Level Security policies com usuários de diferentes roles:
- `admin` — acesso total à escola
- `teacher` — acesso às turmas que leciona
- `parent` — acesso apenas aos dados do(s) filho(s)

---

## SwiftLint e Qualidade de Código

O projeto usa SwiftLint com configuração em `.swiftlint.yml`.

```bash
# Verificar todos os arquivos
make lint-swift

# Autocorrigir violações simples
make lint-swift-fix

# O pre-commit hook roda automaticamente no git commit
```

**Regras mais importantes para o dia a dia:**
- `force_unwrapping` — nunca usar `!` para optional unwrap; use `guard let` ou `if let`
- `file_header` — cada arquivo Swift deve ter o header padrão do projeto
- `sorted_imports` — imports ordenados alfabeticamente
- `type_contents_order` — propriedades antes de métodos, na ordem definida

---

## Documentação

### Onde encontrar o quê

| Documento | Localização |
|---|---|
| Setup local completo | `docs/eng/setup-local.md` |
| Pipeline CI/CD | `docs/eng/ci-cd.md` |
| Rollback de produção | `docs/eng/rollback-procedure.md` |
| Arquitetura de infraestrutura | `docs/infra/` |
| Architecture Decision Records | `docs/adr/` |
| Schema do banco de dados | `database_schema.sql` |
| Checklist de launch | `LAUNCH_CHECKLIST.md` |

### Adicionando documentação

- Documentação de engenharia → `docs/eng/`
- Decisões de arquitetura → `docs/adr/NNN-titulo.md` (formato ADR)
- Documentação de infra → `docs/infra/`

---

## Dúvidas e Suporte

| Canal | Quando usar |
|---|---|
| `#eng` no Slack | Dúvidas técnicas gerais, discussões de arquitetura |
| `#builds` no Slack | Notificações de build, problemas de CI |
| Issue no Linear | Bugs, features, tasks — sempre registrar no Linear |
| PR no GitHub | Code review, discussões de implementação |

**Regra de ouro:** se você bloqueou mais de 30 minutos em algo, pergunte no `#eng`. Ninguém espera que você resolva tudo sozinho.

---

## Checklist de Onboarding (Semana 1)

### Dia 1
- [ ] Receber todos os acessos listados na seção de Acesso e Contas
- [ ] Clonar o repositório
- [ ] Executar `make setup` com sucesso
- [ ] Rodar o app iOS no simulador (`make ios` → `⌘R`)
- [ ] Rodar o website local (`make web`)
- [ ] Ler `docs/eng/ci-cd.md`

### Dias 2-3
- [ ] Criar primeiro branch `feature/LS-XX-onboarding-<seu-nome>`
- [ ] Fazer uma mudança pequena (ex: corrigir typo na documentação)
- [ ] Abrir o primeiro PR e passar pelo processo de review
- [ ] Ver o build rodar no Xcode Cloud e/ou GitHub Actions
- [ ] Ver o preview deployment do Vercel no PR

### Semana 1
- [ ] Ler todos os documentos em `docs/eng/`
- [ ] Navegar pelos ADRs em `docs/adr/` para entender decisões passadas
- [ ] Assistir demo do produto com o time de produto
- [ ] Conversar 1:1 com pelo menos um engenheiro sênior do time
- [ ] Fechar seu primeiro issue no Linear (mesmo que pequeno)

---

Bem-vindo ao time! Qualquer dúvida, é só perguntar no `#eng`.
