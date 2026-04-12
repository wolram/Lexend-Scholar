# Guia de Onboarding iOS — Configuração do Ambiente de Desenvolvimento

**Perfil**: Desenvolvedor iOS (novo no projeto)
**Tempo estimado**: 45-90 minutos
**Última atualização**: Abril 2026

---

## Visão Geral

Este guia leva você do zero até o app Lexend Scholar rodando no simulador do seu Mac. Siga os passos na ordem indicada.

**Pré-requisitos do seu Mac:**
- macOS 14 Sonoma ou superior (recomendado: macOS 15 Sequoia)
- Mac com chip Apple Silicon (M1, M2, M3 ou superior) — recomendado fortemente
- Ao menos 16 GB de RAM e 50 GB de espaço livre em disco
- Conta Apple Developer (solicitar acesso ao time antes de começar)

---

## Passo 1: Instalar o Homebrew

O Homebrew é o gerenciador de pacotes que usaremos para instalar as ferramentas de desenvolvimento.

```bash
# Verificar se já tem Homebrew instalado
which brew

# Se não tiver, instalar:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Após instalação, adicionar ao PATH (Apple Silicon):
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile

# Verificar instalação:
brew --version
# Deve mostrar: Homebrew 4.x.x
```

---

## Passo 2: Instalar o Xcode 16

O Xcode é o IDE oficial para desenvolvimento iOS.

### Opção A: Via Mac App Store (recomendada para primeira instalação)
1. Abra o **Mac App Store**
2. Busque "Xcode"
3. Clique em **Obter** (pode demorar 30-60 minutos para baixar ~15GB)
4. Após instalar, abra o Xcode para aceitar os termos e instalar os componentes adicionais

### Opção B: Via developer.apple.com (para versões específicas)
1. Acesse developer.apple.com/download/applications
2. Faça login com Apple ID de desenvolvedor
3. Baixe o arquivo `.xip` da versão desejada
4. Descompacte e mova para a pasta `/Applications`

### Configuração pós-instalação
```bash
# Selecionar a versão do Xcode correta para ferramentas de linha de comando
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Aceitar licença (necessário para usar xcodebuild)
sudo xcodebuild -license accept

# Verificar versão:
xcodebuild -version
# Deve mostrar: Xcode 16.x, Build version XX
```

---

## Passo 3: Instalar o XcodeGen

O XcodeGen gera o arquivo `.xcodeproj` a partir do arquivo `project.yml`. Isso evita conflitos de merge no arquivo de projeto.

```bash
# Instalar XcodeGen via Homebrew
brew install xcodegen

# Verificar instalação
xcodegen --version
# Deve mostrar: XcodeGen 2.x.x
```

**O que é o XcodeGen?**
Em vez de versionar o `.xcodeproj` (que causa conflitos constantes no Git), versionamos o `project.yml` (um arquivo YAML legível) e geramos o `.xcodeproj` localmente. Nunca commite o `.xcodeproj` — ele está no `.gitignore`.

---

## Passo 4: Instalar o SwiftLint

SwiftLint é o linter de código Swift que garante consistência no estilo do código.

```bash
# Instalar via Homebrew
brew install swiftlint

# Verificar instalação
swiftlint --version
# Deve mostrar: 0.54.x

# Verificar se as regras estão configuradas (na raiz do projeto):
cat .swiftlint.yml
```

---

## Passo 5: Instalar ferramentas adicionais

```bash
# Instalar mise (ou rbenv) para gerenciar versões de ferramentas
brew install mise

# Instalar tuist (opcional — pode ser usado para organização de features)
brew install tuist

# Instalar xcbeautify — formata a saída do xcodebuild de forma legível
brew install xcbeautify

# Instalar swiftformat — formatador de código complementar ao SwiftLint
brew install swiftformat
```

---

## Passo 6: Clonar o Repositório

Antes de clonar, certifique-se de ter:
- [ ] Acesso ao repositório GitHub do Lexend Scholar (solicitar ao Engineering Lead)
- [ ] SSH key configurada no GitHub (ou use HTTPS)

```bash
# Configurar SSH key (se ainda não tiver):
ssh-keygen -t ed25519 -C "seu@email.com"
cat ~/.ssh/id_ed25519.pub
# Copie a chave pública e adicione em github.com → Settings → SSH Keys

# Clonar o repositório:
git clone git@github.com:lexend-scholar/app.git lexend-scholar
cd lexend-scholar

# Verificar estrutura:
ls -la
# Deve mostrar: project.yml, Sources/, Tests/, .swiftlint.yml, .gitignore, etc.
```

---

## Passo 7: Configurar Variáveis de Ambiente

O app precisa de credenciais do Supabase para funcionar. Elas são configuradas via arquivo de ambiente.

```bash
# Copiar o template de configuração:
cp Config/Debug.xcconfig.example Config/Debug.xcconfig

# Editar com suas credenciais de desenvolvimento:
open Config/Debug.xcconfig
```

Edite o arquivo adicionando:
```
SUPABASE_URL = https://[PROJECT_ID].supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
APP_ENVIRONMENT = development
```

**Onde obter as credenciais?**
- Solicitar ao Engineering Lead ou acessar o Supabase Dashboard
- Use o projeto de desenvolvimento/staging, NUNCA as credenciais de produção

**Segurança**: Os arquivos `Config/Debug.xcconfig` e `Config/Release.xcconfig` estão no `.gitignore`. Nunca os commite.

---

## Passo 8: Gerar o Projeto Xcode com XcodeGen

```bash
# Na raiz do repositório:
xcodegen generate

# Saída esperada:
# ✓ Generating project
# ✓ Writing project file LexendScholar.xcodeproj
# Done in 1.23s

# Verificar se o arquivo foi gerado:
ls -la | grep xcodeproj
# Deve mostrar: LexendScholar.xcodeproj
```

**Atenção**: Sempre que o `project.yml` for modificado (ao fazer `git pull`, por exemplo), você precisa rodar `xcodegen generate` novamente. É recomendado criar um alias:

```bash
# Adicionar ao ~/.zshrc:
alias xg="xcodegen generate"
```

---

## Passo 9: Abrir no Xcode e Configurar Simulador

```bash
# Abrir o projeto no Xcode:
open LexendScholar.xcodeproj

# Ou via linha de comando:
xed .
```

No Xcode:
1. Aguarde o índice ser construído (pode levar alguns minutos na primeira vez)
2. Selecione o **Scheme**: `LexendScholar` (ou `LexendScholar-Dev`)
3. Selecione o **Simulator**: iPhone 15 Pro (iOS 17 ou 18)

Se o simulador preferido não aparecer:
1. Vá em **Xcode → Settings (⌘,) → Platforms**
2. Clique em **+** para adicionar o iOS Simulator
3. Baixe o runtime desejado (iOS 17 ou 18)

---

## Passo 10: Rodar no Simulador

```bash
# Opção 1: Pelo Xcode — clique no botão Play (▶) ou pressione ⌘R

# Opção 2: Via linha de comando (mais rápido para CI/CD):
xcodebuild build \
  -scheme LexendScholar \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  | xcbeautify
```

**Primeira vez rodando:**
- O Xcode vai compilar todas as dependências (pode levar 3-5 minutos)
- O simulador vai abrir automaticamente
- O app aparece na tela do simulador

**Resultado esperado:** A tela de login do Lexend Scholar aparece no simulador.

---

## Passo 11: Rodar os Testes

```bash
# Via linha de comando:
xcodebuild test \
  -scheme LexendScholar \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  | xcbeautify

# Via Xcode: ⌘U para rodar todos os testes

# Resultado esperado: X testes passando, 0 falhos
```

---

## Passo 12: Rodar o SwiftLint

```bash
# Na raiz do projeto:
swiftlint lint

# Resultado esperado:
# Done linting! Found 0 violations, 0 serious in XX files.

# Para corrigir automaticamente (safe fixes):
swiftlint --fix
```

O SwiftLint também roda automaticamente na build via **Build Phase** configurado no `project.yml`. Se houver warnings, a build vai falhar.

---

## Troubleshooting

### "Cannot find module 'Supabase'"
```bash
# Resolução de pacotes Swift:
# No Xcode: File → Packages → Resolve Package Versions
# Ou via linha de comando:
xcodebuild -resolvePackageDependencies -scheme LexendScholar
```

### "xcodegen: command not found"
```bash
# Recarregar o PATH:
source ~/.zprofile
# Se ainda não funcionar:
brew install xcodegen
```

### "Build failed: missing config file"
```bash
# Você não criou o arquivo de configuração:
cp Config/Debug.xcconfig.example Config/Debug.xcconfig
# Editar com as credenciais corretas
```

### Simulador não aparece ou está desatualizado
```bash
# Listar simuladores disponíveis:
xcrun simctl list devices available

# Criar simulador manualmente:
xcrun simctl create "iPhone 15 Pro" "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro" "com.apple.CoreSimulator.SimRuntime.iOS-17-5"
```

### `xcodegen generate` falha com erro de sintaxe no project.yml
```bash
# Verificar se o project.yml é YAML válido:
ruby -e "require 'yaml'; YAML.load_file('project.yml')"
# Ou:
python3 -c "import yaml; yaml.safe_load(open('project.yml'))"
```

---

## Próximos Passos

Com o ambiente configurado, você está pronto para:

1. **Entender a arquitetura**: Ler [arquitetura.md](arquitetura.md) e [ios-arquitetura.md](ios-arquitetura.md)
2. **Explorar o Design System**: Ver `Sources/DesignSystem/SchoolPalette.swift`
3. **Pegar sua primeira issue**: Filtrar por label `good-first-issue` no Linear
4. **Entender o Git workflow**: Criar branch `feature/LS-XXX-descricao` e abrir PR

---

## Contato para Dúvidas

Se tiver problemas durante o setup que não estão cobertos aqui:
1. Perguntar no canal Slack `#eng` ou `#ios`
2. Abrir issue no Linear com label `Documentation` para atualizar este guia
