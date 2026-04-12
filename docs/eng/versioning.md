# Convenção de Versionamento Semântico — Lexend Scholar

## Formato: `MAJOR.MINOR.PATCH`

O Lexend Scholar adota o **Semantic Versioning 2.0.0** (semver.org) para versionar todas as releases — plataforma web, app iOS e app Android.

---

## O que incrementa cada componente

| Componente | Quando incrementar | Exemplo |
|------------|-------------------|---------|
| **MAJOR** | Mudança incompatível de API ou contrato de dados; migração de banco obrigatória para todos os clientes; remoção de feature existente | `1.x.x → 2.0.0` |
| **MINOR** | Nova funcionalidade compatível com versões anteriores; nova endpoint pública; novo módulo (ex.: módulo financeiro v2) | `1.2.x → 1.3.0` |
| **PATCH** | Bug fix retrocompatível; ajuste de performance; melhoria de texto/UI sem nova feature; hotfix de segurança | `1.2.3 → 1.2.4` |

### Regras adicionais

- O PATCH é zerado quando MINOR aumenta: `1.2.9 → 1.3.0`
- MINOR e PATCH são zerados quando MAJOR aumenta: `1.5.3 → 2.0.0`
- Versões de pré-release usam sufixo: `1.3.0-beta.1`, `2.0.0-rc.2`
- Versões de build interno usam metadados: `1.3.0+20250412`

---

## Conventional Commits

Todos os commits **devem** seguir o padrão [Conventional Commits 1.0.0](https://www.conventionalcommits.org/):

```
<tipo>[escopo opcional]: <descrição curta>

[corpo opcional]

[rodapé opcional — breaking change, issue refs]
```

### Tipos de commit e impacto no semver

| Tipo | Descrição | Impacto |
|------|-----------|---------|
| `feat` | Nova funcionalidade | MINOR |
| `fix` | Correção de bug | PATCH |
| `perf` | Melhoria de performance sem mudança de API | PATCH |
| `refactor` | Refatoração sem nova feature ou fix | nenhum |
| `docs` | Documentação apenas | nenhum |
| `style` | Formatação, espaçamento (sem lógica) | nenhum |
| `test` | Adição ou correção de testes | nenhum |
| `build` | Mudanças no sistema de build ou dependências externas | nenhum |
| `ci` | Mudanças em arquivos e scripts de CI | nenhum |
| `chore` | Tarefas de manutenção sem impacto no código de produção | nenhum |
| `revert` | Reverte um commit anterior | depende do revertido |

### Breaking Changes → MAJOR

Um commit de qualquer tipo com `BREAKING CHANGE:` no rodapé (ou `!` após o tipo) incrementa MAJOR:

```
feat!: remover endpoint legado /api/v1/alunos

BREAKING CHANGE: A API /api/v1/alunos foi removida. Use /api/v2/students.
Todos os clientes que integram via API devem atualizar suas integrações.
```

### Exemplos de commits

```bash
# Patch — bug fix
fix(auth): corrigir loop de redirect após logout no Safari

# Minor — nova feature
feat(financeiro): adicionar exportação de boletos em PDF em lote

# Minor com escopo
feat(app-ios): implementar Face ID como autenticação biométrica

# Patch — hotfix de segurança
fix(security): sanitizar input de busca para prevenir XSS no portal de pais

# Docs (sem impacto semver)
docs(api): adicionar exemplos de autenticação JWT na documentação

# Breaking change — Major
feat(api)!: migrar autenticação para OAuth 2.0 com PKCE

BREAKING CHANGE: O endpoint POST /api/auth/login foi descontinuado.
Clientes devem implementar o fluxo OAuth 2.0 descrito em docs/api/oauth.md
antes de 2025-06-01.

Refs: LS-120
```

---

## Geração do CHANGELOG

O CHANGELOG é gerado automaticamente a partir dos commits convencionais usando **git-cliff**.

### Configuração

O arquivo `cliff.toml` na raiz do repositório define:
- Quais tipos de commit aparecem no changelog
- A formatação de cada entrada
- A ordem das seções (`feat` → `fix` → `perf` → `refactor` → ...)

### Fluxo de geração

1. **CI automático (push em main):** O workflow `.github/workflows/changelog.yml` executa `git-cliff --latest` e atualiza `CHANGELOG.md` com os commits desde a última tag.
2. **Release manual:** Antes de criar uma tag, execute localmente:
   ```bash
   git-cliff --tag v1.3.0 -o CHANGELOG.md
   git add CHANGELOG.md
   git commit -m "chore: atualizar CHANGELOG para v1.3.0"
   git tag -a v1.3.0 -m "Release v1.3.0"
   git push origin main --tags
   ```

### Seções do CHANGELOG

```markdown
## [1.3.0] — 2025-04-12

### Novidades
- feat(financeiro): exportação de boletos em PDF em lote (#145)

### Correções
- fix(auth): loop de redirect após logout no Safari (#142)
- fix(security): sanitizar input de busca no portal de pais (#140)

### Performance
- perf(dashboard): reduzir tempo de carregamento inicial em 40% (#138)
```

---

## Versão atual

A versão atual do produto está definida em:

| Plataforma | Arquivo |
|-----------|---------|
| Web/API | `package.json` → campo `"version"` |
| iOS | `LexendScholar.xcodeproj` → MARKETING_VERSION |
| Android | `android/app/build.gradle` → `versionName` |

A versão de cada plataforma pode divergir, mas **MAJOR deve ser sempre sincronizado** entre plataformas para indicar compatibilidade de API.
