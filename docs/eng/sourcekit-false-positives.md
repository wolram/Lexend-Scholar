# SourceKit — Falsos Positivos de Resolução de Tipos

Guia para entender e resolver erros de "cannot find type in scope" reportados pelo SourceKit no projeto Lexend Scholar.

---

## O que está acontecendo

O SourceKit (serviço de análise estática que alimenta o editor do Xcode) reporta erros como:

```
cannot find 'SchoolPalette' in scope
cannot find type 'SchoolCard' in scope
cannot find 'AcademicService' in scope
```

Esses erros aparecem como sublinhados vermelhos no editor — mas o projeto **compila com sucesso** via `xcodebuild`.

---

## Por que acontece

O SourceKit analisa arquivos Swift **em isolamento**, sem o contexto completo do módulo. Isso significa que ele não sabe quais arquivos fazem parte do target a menos que o `.xcodeproj` esteja atualizado e carregado corretamente.

Este projeto usa **XcodeGen** para gerar o `LexendScholar.xcodeproj` a partir do `project.yml`. Se o `.xcodeproj` estiver desatualizado (por exemplo, após adicionar novos arquivos `.swift`), o SourceKit não encontra os tipos definidos nesses arquivos novos — mesmo que o compilador os encontre via `sources: path: app`.

**Fluxo do problema:**

```
Novo arquivo adicionado em app/
       ↓
project.yml não muda (usa sources por diretório)
       ↓
.xcodeproj está desatualizado / não foi regenerado
       ↓
SourceKit não indexa os novos arquivos
       ↓
Erros "cannot find X in scope" no editor
       ↓
xcodebuild build compila tudo (lê o sistema de arquivos diretamente)
```

---

## Como verificar que é um falso positivo

Execute um build completo do módulo. Se compilar sem erros, os avisos do editor são falsos positivos:

```bash
cd "/Users/marlow/Documents/Documents - Marlow's MacBook Pro/Sistema de Gestao Escolar"

xcodebuild build \
  -scheme LexendScholar \
  -destination 'platform=iOS Simulator,name=iPhone 16 Plus' \
  | tail -20
```

Resultado esperado:
```
** BUILD SUCCEEDED **
```

Se o build falhar com os mesmos erros de tipo, o problema é real (não um falso positivo do SourceKit) e deve ser investigado separadamente.

---

## Solução: regenerar o .xcodeproj

Sempre que o SourceKit reportar erros de tipo após adicionar ou mover arquivos:

```bash
cd "/Users/marlow/Documents/Documents - Marlow's MacBook Pro/Sistema de Gestao Escolar"

# Regenerar o .xcodeproj a partir do project.yml
xcodegen generate

# Reabrir o projeto no Xcode para reindexar
open LexendScholar.xcodeproj
```

Após reabrir, aguarde o Xcode concluir a indexação (barra de progresso na parte inferior). Os erros do SourceKit devem desaparecer.

---

## Configuração recomendada — Makefile

O `Makefile` do projeto já possui o target `generate` para automatizar isso (adicionado em LS-24):

```bash
make generate   # executa xcodegen generate
make dev        # generate + abre o .xcodeproj
```

**Boas práticas:**

1. Sempre executar `make generate` (ou `xcodegen generate`) após:
   - Criar novos arquivos `.swift`
   - Mover ou renomear arquivos
   - Alterar o `project.yml`
   - Fazer `git pull` com mudanças no `project.yml`

2. **Não commitar o `.xcodeproj` gerado** — ele é derivado do `project.yml` e deve ser regenerado localmente. O `.gitignore` do projeto já exclui `*.xcodeproj/project.pbxproj` para evitar conflitos de merge.

3. Em CI/CD, o pipeline já executa `xcodegen generate` antes de `xcodebuild` (ver `ci_scripts/`).

---

## Erros reais vs. falsos positivos

Nem todo erro do SourceKit é falso positivo. Use esta tabela para distinguir:

| Sintoma | Falso positivo? | Ação |
|---------|-----------------|------|
| Erro de tipo após adicionar arquivo novo | Sim (provavelmente) | `xcodegen generate` |
| Erro de tipo em arquivo antigo sem mudanças | Sim (provavelmente) | `xcodegen generate` + reindexar |
| Erro de sintaxe (`:` esperado, `{` esperado) | **Não** — erro real | Corrigir o código |
| `'nil' requires a contextual type` | **Não** — erro real | Adicionar anotação de tipo explícita |
| `cannot find type 'X'` após `xcodebuild` falhar | **Não** — erro real | Verificar se o arquivo está em `project.yml` / `sources` |
| Erro somente no editor, build passa | Sim | `xcodegen generate` |

---

## Tipos afetados no projeto (referência)

Os seguintes tipos são definidos em `app/DesignSystem.swift` e `app/Models.swift` e podem gerar falsos positivos no SourceKit se o `.xcodeproj` estiver desatualizado:

- `SchoolPalette` — definido em `app/DesignSystem.swift`
- `SchoolCard` — definido em `app/DesignSystem.swift`
- `DashboardMetric` — definido em `app/DesignSystem.swift`
- `AcademicService` — definido em `app/Services/AcademicService.swift`
- `SupabaseService` — definido em `app/Services/SupabaseService.swift`
- `Student`, `Teacher`, `Guardian` — definidos em `app/Models.swift` ou `app/Models/`

---

## Resultado mais recente (LS-208)

Data: 2026-04-12
Status: Projeto gerado com sucesso
Arquivo: `LexendScholar.xcodeproj/project.pbxproj` atualizado

---

## Referências

- [XcodeGen Documentation](https://github.com/yonaskolb/XcodeGen)
- [SourceKit — Swift.org](https://www.swift.org/documentation/articles/getting-started-with-the-language-server.html)
- [Xcode Index — Apple Developer Forums](https://developer.apple.com/forums/tags/xcode-index)
