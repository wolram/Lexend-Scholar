# Screenshots Guide — Lexend Scholar

Guia completo para captura e preparação dos screenshots para App Store (iPhone 6.7" e iPad 12.9").

---

## 1. Telas Essenciais (10 screenshots prioritários)

| # | Tela | Descrição | Destaque |
|---|------|-----------|----------|
| 1 | **Dashboard** | Visão geral com métricas da escola | Cards de resumo: alunos, frequência, pendências financeiras |
| 2 | **Lista de Alunos** | Listagem com busca e filtros | Busca por nome, turma, status |
| 3 | **Perfil do Aluno** | Detalhes completos do aluno | Foto, contatos, histórico |
| 4 | **Lançamento de Notas** | Grid de notas por disciplina | Boletim interativo, médias automáticas |
| 5 | **Controle de Frequência** | Chamada diária por turma | Marcar presença/falta com um toque |
| 6 | **Comunicados** | Feed de avisos da escola | Publicar e receber comunicados |
| 7 | **Financeiro** | Mensalidades e cobranças | Status de pagamento, vencimentos |
| 8 | **Turmas** | Gestão de turmas e horários | Grade horária semanal |
| 9 | **Relatórios** | Gráficos e análises | Evolução de desempenho, frequência |
| 10 | **Onboarding** | Tela de boas-vindas ou login | Primeira impressão do app |

---

## 2. Especificações Técnicas

### iPhone 6.7" (obrigatório)
- **Resolução:** 1290 × 2796 px
- **Dispositivo:** iPhone 15 Pro Max / iPhone 16 Plus
- **Scale:** @3x
- **Formato:** PNG ou JPEG (sem transparência)
- **Tamanho máximo:** 500 MB por arquivo

### iPad 12.9" (obrigatório para iPad)
- **Resolução:** 2048 × 2732 px
- **Dispositivo:** iPad Pro 12.9" (6ª geração)
- **Scale:** @2x
- **Formato:** PNG ou JPEG (sem transparência)
- **Tamanho máximo:** 500 MB por arquivo

### Opcionais adicionais
| Formato | Resolução |
|---------|-----------|
| iPhone 6.5" | 1242 × 2688 px |
| iPhone 5.5" | 1242 × 2208 px |
| iPad 11" | 1668 × 2388 px |

---

## 3. Passo a Passo — Captura no Xcode Simulator

### Preparação
```bash
# Gerar o .xcodeproj atualizado
cd "/Users/marlow/Documents/Documents - Marlow's MacBook Pro/Sistema de Gestao Escolar"
xcodegen generate

# Abrir o projeto
open LexendScholar.xcodeproj
```

### Configurar o Simulator

1. No Xcode: **Xcode → Open Developer Tool → Simulator**
2. Selecionar o dispositivo alvo:
   - iPhone: `File → New Simulator` → **iPhone 16 Plus** (6.7")
   - iPad: `File → New Simulator` → **iPad Pro 13-inch (M4)** (12.9")
3. Definir escala adequada: `Window → Physical Size` (Cmd+1)
4. Desativar a barra de status customizada: `Features → Toggle In-Call Status Bar` (desligado)
5. Definir hora fixa para aparência consistente:
   ```bash
   # Exibe status bar limpa (opcional — via SimulatorStatusMagic se instalado)
   xcrun simctl status_bar "iPhone 16 Plus" override --time "9:41" --batteryState charged --batteryLevel 100 --wifiBars 3
   ```

### Navegar até a tela e capturar

1. Execute o app no simulator desejado (Cmd+R)
2. Navegue até a tela do screenshot
3. Capture com um dos métodos:

**Método A — Xcode Simulator (recomendado):**
```
Simulator → File → Save Screen (Cmd+S)
```
Salva automaticamente na pasta `~/Desktop` no tamanho nativo correto.

**Método B — macOS Screenshot:**
```
Cmd+Shift+4 → Espaço → Clicar na janela do Simulator
```
Salva com sombra; remover sombra: `Cmd+Shift+4 → Espaço → Option+Clicar`

**Método C — xcrun (linha de comando, para automação):**
```bash
xcrun simctl io booted screenshot ~/Desktop/screenshot-dashboard.png
```

---

## 4. Guia de Texto Overlay (por screenshot)

Adicione textos explicativos sobre as imagens usando Figma, Sketch ou Preview (macOS).

| # | Tela | Título sugerido | Subtítulo sugerido |
|---|------|-----------------|--------------------|
| 1 | Dashboard | **Sua escola em um só lugar** | Métricas em tempo real, sempre atualizadas |
| 2 | Lista de Alunos | **Gestão de alunos simplificada** | Busque, filtre e acesse qualquer aluno |
| 3 | Perfil do Aluno | **Histórico completo do aluno** | Notas, frequência e contatos dos responsáveis |
| 4 | Lançamento de Notas | **Notas em segundos** | Lance e consulte o boletim de qualquer turma |
| 5 | Frequência | **Chamada digital sem papel** | Registre presença com um toque |
| 6 | Comunicados | **Comunicação direta com famílias** | Avisos, eventos e recados em um feed |
| 7 | Financeiro | **Controle financeiro transparente** | Mensalidades, vencimentos e inadimplência |
| 8 | Turmas | **Grade horária organizada** | Gerencie turmas e horários com facilidade |
| 9 | Relatórios | **Relatórios inteligentes** | Acompanhe o desempenho da sua escola |
| 10 | Onboarding | **Lexend Scholar** | Sistema de gestão escolar moderno |

### Padrão visual dos overlays
- **Fonte título:** SF Pro Display Bold, 52pt (para 1290×2796)
- **Fonte subtítulo:** SF Pro Text Regular, 36pt
- **Posição:** barra inferior com fundo sólido ou gradiente da cor principal
- **Cor primária do app:** `#1A3C5E` (azul escolar)
- **Cor de fundo overlay:** `rgba(26, 60, 94, 0.92)`
- **Texto:** branco `#FFFFFF`

---

## 5. Checklist de Revisão Antes de Submeter

### Técnico
- [ ] Resolução correta: 1290×2796 (iPhone) e 2048×2732 (iPad)
- [ ] Formato PNG ou JPEG (sem camada alpha)
- [ ] Nenhum screenshot abaixo de 72 DPI
- [ ] Status bar limpa: horário 9:41, bateria 100%, Wi-Fi 3 barras
- [ ] Sem barra de debug do Xcode visível
- [ ] Sem cursor do mouse ou artefatos do simulator
- [ ] Mínimo 3 screenshots, máximo 10 por localidade

### Conteúdo
- [ ] Dados de exemplo realistas (não "Lorem ipsum", não dados pessoais reais)
- [ ] Nenhum conteúdo ofensivo ou protegido por direitos autorais
- [ ] Logo/marca visível mas não excessiva
- [ ] Textos em português (pt-BR) para a localidade principal
- [ ] Telas mostram funcionalidades reais e disponíveis na versão submetida

### App Store Connect
- [ ] Mínimo de 3 screenshots na localidade padrão (pt-BR)
- [ ] Screenshots na ordem lógica de descoberta do produto
- [ ] Preview de vídeo (opcional) com duração de 15–30 segundos
- [ ] Versão para iPad submetida separadamente (se app universal)

---

## Referências

- [App Store Screenshot Specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications)
- [Human Interface Guidelines — App Screenshots](https://developer.apple.com/design/human-interface-guidelines/screenshots)
- [xcrun simctl status_bar](https://www.jessesquires.com/blog/2020/04/01/overriding-status-bar-settings-ios-simulator/)
