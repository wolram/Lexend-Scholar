# Design Tokens — Lexend Scholar

> Tokens em formato compatível com [Style Dictionary](https://styledictionary.com/).
> Gerado em: 2026-04-12.

## Tokens JSON (Style Dictionary)

```json
{
  "color": {
    "brand": {
      "primary": {
        "value": "#137FEC",
        "type": "color",
        "description": "Cor primária da marca. Botões, links, destaques de ação."
      },
      "violet": {
        "value": "#6366F1",
        "type": "color",
        "description": "Cor de destaque secundária. Ilustrações e gradientes decorativos."
      }
    },
    "background": {
      "default": {
        "value": "#F6F7F8",
        "type": "color",
        "description": "Fundo geral de telas e canvas principal."
      },
      "surface": {
        "value": "#FFFFFF",
        "type": "color",
        "description": "Superfície de cards, modais e sheets."
      },
      "surfaceAlt": {
        "value": "#F1F3FD",
        "type": "color",
        "description": "Superfície alternativa para seções e linhas alternadas."
      }
    },
    "text": {
      "primary": {
        "value": "#111418",
        "type": "color",
        "description": "Texto principal, títulos, body."
      },
      "secondary": {
        "value": "#617589",
        "type": "color",
        "description": "Texto secundário, subtítulos, placeholders."
      }
    },
    "border": {
      "default": {
        "value": "rgba(0, 0, 0, 0.06)",
        "type": "color",
        "description": "Bordas de cards e separadores."
      }
    },
    "semantic": {
      "success": {
        "value": "#12965B",
        "type": "color",
        "description": "Status positivo, confirmações, presença."
      },
      "warning": {
        "value": "#F59E0B",
        "type": "color",
        "description": "Alertas, atrasos, atenção."
      },
      "danger": {
        "value": "#EF4444",
        "type": "color",
        "description": "Erros, exclusões, ausências, inadimplência."
      }
    }
  },
  "typography": {
    "fontFamily": {
      "primary": {
        "value": "Lexend, system-ui, -apple-system, sans-serif",
        "type": "fontFamily",
        "description": "Fonte principal do produto."
      }
    },
    "fontSize": {
      "xs": { "value": "11px", "type": "fontSize" },
      "sm": { "value": "12px", "type": "fontSize" },
      "md": { "value": "14px", "type": "fontSize" },
      "base": { "value": "15px", "type": "fontSize" },
      "lg": { "value": "16px", "type": "fontSize" },
      "xl": { "value": "22px", "type": "fontSize" },
      "2xl": { "value": "34px", "type": "fontSize" }
    },
    "fontWeight": {
      "medium": { "value": "500", "type": "fontWeight" },
      "semibold": { "value": "600", "type": "fontWeight" },
      "bold": { "value": "700", "type": "fontWeight" }
    },
    "letterSpacing": {
      "eyebrow": { "value": "0.12em", "type": "letterSpacing", "description": "Eyebrow labels em uppercase." },
      "normal": { "value": "0", "type": "letterSpacing" }
    },
    "lineHeight": {
      "tight": { "value": "1.2", "type": "lineHeight" },
      "normal": { "value": "1.5", "type": "lineHeight" },
      "relaxed": { "value": "1.6", "type": "lineHeight" }
    }
  },
  "spacing": {
    "1": { "value": "4px", "type": "spacing" },
    "2": { "value": "8px", "type": "spacing" },
    "3": { "value": "12px", "type": "spacing" },
    "4": { "value": "16px", "type": "spacing" },
    "5": { "value": "20px", "type": "spacing" },
    "6": { "value": "24px", "type": "spacing" },
    "7": { "value": "28px", "type": "spacing" },
    "8": { "value": "32px", "type": "spacing" },
    "10": { "value": "40px", "type": "spacing" },
    "12": { "value": "48px", "type": "spacing" }
  },
  "borderRadius": {
    "sm": { "value": "8px", "type": "borderRadius" },
    "md": { "value": "14px", "type": "borderRadius", "description": "Ícones de métrica." },
    "lg": { "value": "18px", "type": "borderRadius", "description": "Search bars, campos." },
    "xl": { "value": "28px", "type": "borderRadius", "description": "Cards principais." },
    "full": { "value": "9999px", "type": "borderRadius", "description": "Chips, badges, avatares." }
  },
  "shadow": {
    "card": {
      "value": "0 10px 18px rgba(0, 0, 0, 0.04)",
      "type": "shadow",
      "description": "Sombra padrão de cards."
    },
    "searchBar": {
      "value": "0 8px 12px rgba(0, 0, 0, 0.03)",
      "type": "shadow",
      "description": "Sombra da barra de busca."
    }
  }
}
```

---

## Como importar no Figma via Tokens Studio

### Pré-requisitos
- Plugin **Tokens Studio for Figma** instalado (gratuito na Figma Community).
- Arquivo Figma do Lexend Scholar aberto.

### Passo a passo

1. **Abra o Tokens Studio** no painel de plugins do Figma.

2. **Crie um novo Token Set** chamado `lexend-scholar/base`.

3. **Cole o JSON acima** na aba "JSON Editor" do plugin.
   - O plugin aceita o formato Style Dictionary v3 com a estrutura `{ "tipo": { "nome": { "value": "...", "type": "..." } } }`.

4. **Aplique os tokens:**
   - Vá para a aba "Tokens" e clique em "Apply All Tokens".
   - Isso vincula as variáveis Figma aos tokens do JSON.

5. **Crie Sets por tema:**
   - `lexend-scholar/light` — tokens de modo claro (padrão acima).
   - `lexend-scholar/dark` — tokens de modo escuro (ver `dark-mode.md`).
   - Ative/desative sets para alternar temas no Figma.

6. **Exporte para código:**
   - No painel do Tokens Studio, vá em "Export" → "Style Dictionary".
   - O arquivo gerado pode ser processado pelo `style-dictionary` CLI para gerar variáveis CSS, Swift, ou Kotlin.

### Estrutura de arquivos recomendada para Style Dictionary

```
tokens/
  base.json          ← este arquivo
  dark.json          ← overrides dark mode
config.json          ← configuração do style-dictionary
```

### config.json (Style Dictionary)

```json
{
  "source": ["tokens/base.json"],
  "platforms": {
    "css": {
      "transformGroup": "css",
      "buildPath": "dist/css/",
      "files": [{ "destination": "variables.css", "format": "css/variables" }]
    },
    "swift": {
      "transformGroup": "ios-swift",
      "buildPath": "dist/swift/",
      "files": [{ "destination": "StyleDictionary.swift", "format": "ios-swift/class.swift" }]
    }
  }
}
```
