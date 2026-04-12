# Dark Mode — Documentação de Variantes

> Guia de implementação SwiftUI + mapeamento de cores para dark mode.
> Última revisão: 2026-04-12.

## Mapeamento SchoolPalette → Dark Mode

| Token (Light) | Hex Light | Token (Dark) | Hex Dark | Justificativa |
|---|---|---|---|---|
| `primary` | `#137FEC` | `#4DA3FF` | Azul levemente mais claro para manter contraste sobre fundo escuro |
| `background` | `#F6F7F8` | `#0F1117` | Fundo quase preto, evita preto puro para reduzir fadiga |
| `surface` | `#FFFFFF` | `#1C1E26` | Superfície elevada: cinza escuro azulado |
| `surfaceAlt` | `#F1F3FD` | `#252836` | Superfície alternativa: um tom acima do surface |
| `primaryText` | `#111418` | `#F0F2F5` | Texto quase branco sobre fundo escuro |
| `secondaryText` | `#617589` | `#8A9BB0` | Mantém hierarquia, mais suave que o primário |
| `outline` | `rgba(0,0,0,0.06)` | `rgba(255,255,255,0.08)` | Bordas visíveis mas sutis no escuro |
| `success` | `#12965B` | `#34D28C` | Verde mais claro para contraste em fundo escuro |
| `warning` | `#F59E0B` | `#FBC02D` | Âmbar levemente mais claro |
| `danger` | `#EF4444` | `#FF6B6B` | Vermelho mais suave, evita agressividade no escuro |
| `violet` | `#6366F1` | `#818CF8` | Violeta mais claro para manter vibração no escuro |

### Referências de Contraste WCAG 2.1 AA

- **primaryText sobre background dark**: ~14:1 — AAA
- **primary sobre background dark**: ~4.8:1 — AA
- **secondaryText sobre background dark**: ~5.2:1 — AA
- **success sobre surface dark**: ~4.5:1 — AA mínimo atingido

---

## Implementação em SwiftUI

### Abordagem 1 — Color Assets (recomendada)

Crie um `Color Set` no `Assets.xcassets` para cada token com variantes Any/Light e Dark:

```
Assets.xcassets/
  Colors/
    Primary.colorset/         Any: #137FEC  Dark: #4DA3FF
    Background.colorset/      Any: #F6F7F8  Dark: #0F1117
    Surface.colorset/         Any: #FFFFFF  Dark: #1C1E26
    SurfaceAlt.colorset/      Any: #F1F3FD  Dark: #252836
    PrimaryText.colorset/     Any: #111418  Dark: #F0F2F5
    SecondaryText.colorset/   Any: #617589  Dark: #8A9BB0
    Success.colorset/         Any: #12965B  Dark: #34D28C
    Warning.colorset/         Any: #F59E0B  Dark: #FBC02D
    Danger.colorset/          Any: #EF4444  Dark: #FF6B6B
    Violet.colorset/          Any: #6366F1  Dark: #818CF8
```

Depois, atualize `SchoolPalette` em `DesignSystem.swift`:

```swift
enum SchoolPalette {
    static let primary      = Color("Primary")
    static let background   = Color("Background")
    static let surface      = Color("Surface")
    static let surfaceAlt   = Color("SurfaceAlt")
    static let primaryText  = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")
    static let outline      = Color("Outline")
    static let success      = Color("Success")
    static let warning      = Color("Warning")
    static let danger       = Color("Danger")
    static let violet       = Color("Violet")
}
```

O SwiftUI troca automaticamente as cores quando o sistema muda para dark mode.

### Abordagem 2 — @Environment(\.colorScheme)

Use quando precisar de lógica condicional (ex.: gradientes diferentes):

```swift
struct SchoolCanvasBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color("Background"), Color("Surface"), Color("SurfaceAlt").opacity(0.8)]
                    : [SchoolPalette.background, Color.white, SchoolPalette.surfaceAlt.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // orbs decorativas...
        }
        .ignoresSafeArea()
    }
}
```

### Abordagem 3 — ShapeStyle adaptativo inline

Para casos pontuais onde não vale criar um Color Asset:

```swift
// Exemplo: fundo de card adaptativo
.background(
    colorScheme == .dark
        ? Color(hex: "#1C1E26")
        : Color.white,
    in: RoundedRectangle(cornerRadius: 28, style: .continuous)
)
```

---

## Checklist de Componentes para Adaptação Dark Mode

### Design System (app/DesignSystem.swift)

- [ ] `SchoolCanvasBackground` — gradiente e orbs com opacidade ajustada
- [ ] `SchoolCard` — background `surface`, stroke `outline`
- [ ] `AdaptiveGlassGroup` — glass no iOS 26 adapta automaticamente; fallback precisa de atenção
- [ ] `SchoolSectionHeader` — apenas cores de texto (já usa tokens)
- [ ] `StatusChip` — cor do chip com opacidade, verificar contraste
- [ ] `InitialAvatar` — fundo com opacidade da cor de acento (ok), verificar texto
- [ ] `SchoolSearchBar` — fundo branco @ 78% precisa de variante escura (ex: `surface` @ 80%)
- [ ] `MetricCard` — container de ícone com opacidade, verificar legibilidade

### Views de Alunos (app/Views/Alunos/)

- [ ] `AlunosListView` — fundo de lista, células, separadores
- [ ] `AlunoFormView` — campos de formulário, labels

### Views de Autenticação (app/Views/Auth/)

- [ ] `LoginView` — fundo, campos, botão primário
- [ ] `ProfileSelectionView` — cards de perfil, fundo

### Views de Boletim

- [ ] `BoletimView` — tabela de notas, células de nota, cores semânticas (verde/vermelho)

### Views de Calendário

- [ ] `CalendarioLetivoView` — células de dia, eventos coloridos

### Views Financeiro

- [ ] `CobrancasView` — status de cobrança (pago/pendente/atrasado)
- [ ] `MensalidadesConfigView` — formulário de configuração

### Views de Frequência

- [ ] `FrequenciaView` — células de presença/falta, percentuais

### Views de Matrícula

- [ ] `MatriculaFlowView` — stepper de etapas, progresso

### Views de Notas

- [ ] `NotasLancamentoView` — células de lançamento, inputs

### Views de Professores

- [ ] `ProfessoresListView` — lista, avatares
- [ ] `ProfessorFormView` — formulário

### Views de Responsáveis

- [ ] `ResponsavelFormView` — formulário de responsável

### Views de Turmas

- [ ] `TurmasListView` — cards de turma
- [ ] `TurmaFormView` — formulário

### Shell

- [ ] `AppShellView` — tab bar, sidebar, fundo principal

---

## Testes de Dark Mode

```swift
// Preview com ambos os modos
struct SchoolCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SchoolCard(title: "Exemplo") { Text("Conteúdo") }
                .preferredColorScheme(.light)
            SchoolCard(title: "Exemplo") { Text("Conteúdo") }
                .preferredColorScheme(.dark)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
```

Ative dark mode no Simulator: **Settings → Developer → Dark Appearance**.
