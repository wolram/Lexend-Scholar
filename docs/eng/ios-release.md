# Processo de Release iOS — Lexend Scholar

Guia completo para publicar o app Lexend Scholar na App Store,
desde o bump de versão até a promoção para produção.

---

## Pré-requisitos

| Item | Detalhe |
|------|---------|
| Conta Apple Developer | `contato@lexendscholar.com.br` — Program Individual ou Organização |
| Xcode | Versão mínima exigida pelo xcodeproj atual (verificar `XCODE_COMPATIBLE_MACHINE_OS_BUILD`) |
| Certificados | Distribution Certificate + Provisioning Profile válidos no Keychain |
| App Store Connect | Acesso como Admin ou App Manager |

---

## 1. Bump de Versão

### Arquivos a atualizar

| Campo | Arquivo | Exemplo |
|-------|---------|---------|
| `MARKETING_VERSION` | `LexendScholar.xcodeproj/project.pbxproj` | `1.3.0` |
| `CURRENT_PROJECT_VERSION` | `LexendScholar.xcodeproj/project.pbxproj` | `42` (inteiro, auto-incrementado) |

### Via Xcode (recomendado)

1. Abrir `LexendScholar.xcodeproj`
2. Selecionar o target **LexendScholar** → aba **General**
3. Atualizar **Version** (= MARKETING_VERSION) e **Build** (= CURRENT_PROJECT_VERSION)
4. O Build deve ser sempre maior que o build anterior aceito pelo TestFlight/App Store

### Via linha de comando (CI)

```bash
# Definir variáveis
VERSION="1.3.0"
BUILD=$(date +%Y%m%d%H%M)   # Ex: 202504121430

# Atualizar via xcrun agvtool (dentro do diretório do projeto)
cd /path/to/repo
xcrun agvtool new-marketing-version "$VERSION"
xcrun agvtool new-version -all "$BUILD"

# Commit do bump
git add LexendScholar.xcodeproj/project.pbxproj
git commit -m "chore(ios): bump versão para $VERSION ($BUILD)"
git tag -a "v$VERSION" -m "Release iOS $VERSION"
git push origin main --tags
```

---

## 2. Build e Archive no Xcode

### Configurações de build para release

- **Scheme:** `LexendScholar`
- **Destination:** `Any iOS Device (arm64)` (não simulador)
- **Configuration:** `Release`

### Passo a passo

1. Selecionar `Product → Scheme → LexendScholar`
2. Selecionar destino `Any iOS Device (arm64)`
3. Verificar que `Build Configuration` está em `Release`:
   - `Product → Scheme → Edit Scheme → Run → Build Configuration → Release`
4. Executar `Product → Archive`
5. Aguardar o build (pode levar 5–15 minutos dependendo da máquina)
6. O Organizer abrirá automaticamente com o novo archive

### Verificações pré-archive

```bash
# Garantir que não há warnings de segurança graves
xcodebuild -workspace LexendScholar.xcodeproj/project.xcworkspace \
  -scheme LexendScholar \
  -configuration Release \
  -destination generic/platform=iOS \
  clean build | xcpretty

# Rodar testes antes do archive
xcodebuild test \
  -scheme LexendScholar \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' | xcpretty
```

---

## 3. Upload ao TestFlight

### Via Xcode Organizer (recomendado para primeira release)

1. No Xcode Organizer (`Window → Organizer`), selecionar o archive recém-criado
2. Clicar em **Distribute App**
3. Selecionar **TestFlight & App Store**
4. Opções de signing:
   - **Automatically manage signing** (recomendado para CI simples)
   - Ou selecionar Distribution Certificate + Provisioning Profile manualmente
5. Clicar em **Upload**
6. Aguardar processamento pela Apple (geralmente 10–30 minutos)

### Via Xcode Cloud (CI automático)

O workflow `.xcode-cloud/` (ou `ci_scripts/`) é configurado para:
- Trigger: push em `main` ou tag `v*`
- Build: `Release`
- Post-action: upload automático para TestFlight

Ver detalhes em `.github/workflows/` e nos scripts `ci_scripts/`.

### Via `altool` / `notarytool` (linha de comando legado)

```bash
# Exportar IPA do archive
xcodebuild -exportArchive \
  -archivePath ./build/LexendScholar.xcarchive \
  -exportPath ./build/ipa \
  -exportOptionsPlist ./ExportOptions.plist

# Upload via altool
xcrun altool --upload-app \
  -f ./build/ipa/LexendScholar.ipa \
  -t ios \
  -u "contato@lexendscholar.com.br" \
  -p "@keychain:AC_PASSWORD"
```

> **Nota:** `altool` está deprecated desde Xcode 14. Prefira `notarytool` ou o Organizer.

---

## 4. Configuração do TestFlight

### Grupos de teste

| Grupo | Membros | Propósito |
|-------|---------|-----------|
| Internal Testers | Equipe Lexend Scholar (máx. 100) | Smoke tests, regressão rápida |
| Closed Beta — Escolas Parceiras | 5–10 escolas selecionadas | Validação em ambiente real |
| Open Beta (opcional) | Público via link público | Feedback em escala |

### Notas de release para o TestFlight

Sempre preencher o campo **"What to Test"** com:
- Funcionalidades novas a testar
- Bugs corrigidos a verificar
- Fluxos críticos (login, lançamento de notas, boletim)
- Instruções de reprodução para bugs conhecidos

### Critérios de promoção Internal → Closed Beta

- Zero crashes críticos em 48 horas com internal testers
- Funcionalidades do milestone validadas pelo PO
- Cobertura de testes automatizados > 80% (verificada no CI)

---

## 5. Review Apple

### Submissão para revisão

1. No App Store Connect, acessar o app **Lexend Scholar**
2. Criar nova versão (se não existir): `+ Version or Platform`
3. Preencher obrigatoriamente:
   - **What's New** (em português — máx. 4000 caracteres)
   - Screenshots para todos os tamanhos necessários (iPhone 6.7", iPad 12.9")
   - **Privacy Nutrition Labels** (atualizar se necessário)
   - **Age Rating** (Education)
4. Selecionar o build do TestFlight que passou nos testes
5. Clicar em **Add for Review** → **Submit to App Review**

### Prazo típico de review

- **Primeira submissão:** 24–48 horas
- **Atualizações:** 12–24 horas
- **Revisão acelerada (Expedited):** disponível em casos de bug crítico

### Informações de demo obrigatórias

A Apple exige conta de demonstração funcional:
- **Login:** `reviewer@lexendscholar.demo`
- **Senha:** (manter em 1Password, compartilhar apenas com a Apple via notes privadas)
- **Dados de demo:** escola com 30 alunos, 5 turmas, dados fictícios

### Motivos comuns de rejeição e como evitar

| Motivo | Prevenção |
|--------|-----------|
| Privacy policy URL inválida | Verificar que `https://www.lexendscholar.com.br/privacy.html` está acessível |
| App crashes na review | Testar em iOS 16+ e em device físico antes da submissão |
| Missing data use descriptions | Preencher `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` no Info.plist |
| In-app purchase não testável | Garantir que StoreKit sandbox está configurado |
| LGPD/Dados de menores | Privacy nutrition labels corretos; App Store não deve coletar dados sem consentimento |

---

## 6. Promoção para Produção

### Opções de lançamento

| Modo | Configuração | Quando usar |
|------|-------------|-------------|
| **Manual Release** | Não ativar auto-release | Para coordenar com campanha de marketing |
| **Automatic Release** | Imediatamente após aprovação | Para hotfixes e patches urgentes |
| **Phased Release** | 7 dias, 1%→2%→5%→10%→20%→50%→100% | Para releases MAJOR com risco de regressão |

### Após aprovação da Apple

1. No App Store Connect, clicar em **Release This Version**
2. Monitorar no Crashlytics/Sentry as métricas de crash nas primeiras 2 horas
3. Verificar no App Store que a nova versão está visível (pode levar até 1 hora para propagar)
4. Notificar equipe no Slack: `#releases`
5. Criar GitHub Release com as notas de versão:
   ```bash
   git tag -a "v1.3.0" -m "Release iOS v1.3.0"
   git push origin --tags
   # O workflow changelog.yml cria a GitHub Release automaticamente
   ```

### Rollback

Não é possível fazer rollback na App Store (Apple não permite rebaixar versões).
Em caso de bug crítico pós-release:
- Publicar hotfix como nova versão PATCH imediatamente
- Usar **Phased Release** para limitar exposição nas próximas releases
- Ver [docs/eng/rollback-procedure.md](rollback-procedure.md) para mitigações no backend

---

## Checklist de Release iOS

```
[ ] Versão e Build atualizados no xcodeproj
[ ] Testes automatizados passando (CI verde)
[ ] Archive gerado em Release configuration
[ ] IPA validado localmente (no device físico)
[ ] Upload para TestFlight concluído
[ ] Internal testers aprovaram (48h sem crash crítico)
[ ] Closed beta aprovada (se aplicável)
[ ] What's New redigido em português
[ ] Screenshots atualizados (se houve mudança de UI)
[ ] Privacy Nutrition Labels revisados
[ ] Conta de demo funcional
[ ] Privacy policy URL acessível
[ ] Submetido para App Review
[ ] Aprovação Apple recebida
[ ] Modo de release definido (manual/auto/phased)
[ ] Release executado
[ ] Sentry/Crashlytics monitorados por 2h
[ ] GitHub Release criado
[ ] Slack #releases notificado
```
