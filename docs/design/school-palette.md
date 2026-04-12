# SchoolPalette — Auditoria e Documentação

> Extraído de `app/DesignSystem.swift`. Última revisão: 2026-04-12.

## Cores — Tabela de Tokens

| Token | Valor Hex | RGB | Uso |
|---|---|---|---|
| `primary` | `#137FEC` | rgb(19, 127, 236) | Botões primários, links, destaques de ação, ícones ativos |
| `background` | `#F6F7F8` | rgb(246, 247, 248) | Fundo geral de telas, canvas principal |
| `surface` | `#FFFFFF` | rgb(255, 255, 255) | Cards, modais, sheets, superfícies elevadas |
| `surfaceAlt` | `#F1F3FD` | rgb(241, 243, 253) | Fundo alternativo de seções, linhas de tabela alternadas |
| `primaryText` | `#111418` | rgb(17, 20, 24) | Texto principal, títulos, body copy |
| `secondaryText` | `#617589` | rgb(97, 117, 137) | Subtítulos, placeholders, labels secundários, eyebrows |
| `outline` | `#00000010` | rgba(0,0,0, 0.06) | Bordas de cards, separadores, divisores |
| `success` | `#12965B` | rgb(18, 150, 91) | Status ativo, confirmações, badges de presença |
| `warning` | `#F59E0B` | rgb(245, 158, 11) | Alertas, atrasos, atenção necessária |
| `danger` | `#EF4444` | rgb(239, 68, 68) | Erros, exclusões, ausências, inadimplência |
| `violet` | `#6366F1` | rgb(99, 102, 241) | Destaques secundários, ilustrações, gradientes decorativos |

## Gradientes e Efeitos Visuais

### SchoolCanvasBackground
Gradiente linear de três paradas aplicado ao fundo principal de telas:
- Direção: `topLeading → bottomTrailing`
- Parada 1: `background` (#F6F7F8)
- Parada 2: `surface` (#FFFFFF)
- Parada 3: `surfaceAlt` a 80% de opacidade (#F1F3FD @ 0.8)

**Orbs decorativas (blur circles):**
- Orb primária: `primary` @ 10% opacidade, 360×360pt, offset (240, -260), blur 30pt
- Orb violeta: `violet` @ 8% opacidade, 280×280pt, offset (-240, 360), blur 24pt

## Tipografia

A tipografia é baseada no sistema de design rounded do iOS (`design: .rounded`), espelhando visualmente a fonte Lexend.

| Estilo | Tamanho | Peso | Kerning | Uso |
|---|---|---|---|---|
| Display / Título Principal | 34pt | Bold | — | `SchoolSectionHeader` — título de seção |
| Card Title | 22pt | Bold | — | `SchoolCard` — título de card |
| Body / Subtítulo | 16pt | Medium | — | `SchoolSectionHeader` — subtítulo |
| Card Subtitle | 14pt | Medium | — | `SchoolCard` — subtítulo de card |
| Eyebrow / Label | 11pt | Semibold | 1.5 | `SchoolSectionHeader` — eyebrow label (uppercase) |
| Status Chip | 11pt | Bold | — | `StatusChip` — texto de badge (uppercase) |
| Metric Value | 34pt | Bold | — | `MetricCard` — valor principal de métrica |
| Metric Title | 15pt | Medium | — | `MetricCard` — label de métrica |
| Metric Change | 12pt | Bold | — | `MetricCard` — variação percentual |
| Search | 15pt | Medium | — | `SchoolSearchBar` — texto de busca |

## Espaçamentos

| Contexto | Valor |
|---|---|
| Padding interno de card (`SchoolCard`) | 24pt |
| Espaçamento interno de card | 18pt |
| Espaçamento entre eyebrow/título/subtítulo | 8pt |
| Espaçamento entre título e subtítulo de card | 6pt |
| Espaçamento entre ícone e conteúdo (`SchoolSectionHeader`) | 20pt |
| Padding horizontal da search bar | 16pt |
| Padding vertical da search bar | 14pt |
| Espaçamento entre ícone e campo de busca | 12pt |
| Container de ícone em MetricCard | 52×52pt |
| Border radius de MetricCard icon | 14pt |
| Border radius de cards | 28pt |
| Border radius de search bar | 18pt |

## Componentes Documentados

### SchoolCard
- Padding: 24pt
- Corner radius: 28pt (continuous)
- iOS 26+: `.glassEffect(.regular)` com stroke branco 35%
- iOS < 26: background `surface` branco, stroke `outline`, sombra preta 4% / blur 18 / y 10

### SchoolSectionHeader
- Layout: HStack com VStack de textos + Trailing view
- Eyebrow: uppercased, kerning 1.5, `secondaryText`
- Título: 34pt bold, `primaryText`
- Subtítulo: 16pt medium, `secondaryText`, multiline

### StatusChip
- Formato: Capsule
- Texto uppercase, 11pt bold
- Background: cor do chip @ 12% opacidade
- Padding: 12pt horizontal, 8pt vertical

### InitialAvatar
- Formato: Círculo
- Tamanho padrão: 48pt
- Fundo: cor do acento @ 14% opacidade
- Iniciais: até 2 letras, `size * 0.34` pt, bold

### SchoolSearchBar
- Corner radius: 18pt
- Fundo: branco @ 78% opacidade
- Stroke: `outline`
- Sombra: preta 3% / blur 12 / y 8

### MetricCard
- Usa `SchoolCard` como container
- Ícone: container 52×52pt, corner radius 14pt
- Badge de variação: Capsule, cor de variação @ 12%

### AdaptiveGlassGroup
- iOS 26+: `GlassEffectContainer` nativo
- iOS < 26: VStack puro sem glass
