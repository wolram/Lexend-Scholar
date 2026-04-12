# LS-160 — Auditoria Lighthouse no Website (meta: score > 90)

## Objetivo

Executar Lighthouse em todas as páginas do website Lexend Scholar,
documentar scores de Performance, Accessibility, Best Practices e SEO,
e criar plano de melhoria para atingir score > 90 em todas as categorias.

---

## Instalação e Configuração

```bash
# Instalar Lighthouse CLI
npm install -g lighthouse

# Versão utilizada nesta auditoria
lighthouse --version
# → 12.x.x

# Instalar Chrome (necessário para Lighthouse)
# Linux CI: usar chromium-browser
# macOS: Chrome já instalado
```

---

## Comandos de Auditoria

### Executar auditoria completa em todas as páginas

```bash
#!/bin/bash
# scripts/qa/run-lighthouse.sh

SITE_URL="https://lexendscholar.com.br"
PAGES=(
  "/"
  "/about.html"
  "/pricing.html"
  "/blog.html"
  "/contact.html"
  "/404.html"
)
OUTPUT_DIR="docs/quality/lighthouse-reports"

mkdir -p "$OUTPUT_DIR"

echo "Iniciando auditoria Lighthouse..."
echo "URL base: $SITE_URL"
echo "Destino: $OUTPUT_DIR"
echo ""

for PAGE in "${PAGES[@]}"; do
  PAGE_NAME=$(echo "$PAGE" | tr '/' '-' | sed 's/^-//' | sed 's/\.html//')
  [ -z "$PAGE_NAME" ] && PAGE_NAME="home"
  
  echo "Auditando: $SITE_URL$PAGE"
  
  lighthouse "$SITE_URL$PAGE" \
    --output=json \
    --output=html \
    --output-path="$OUTPUT_DIR/lighthouse-$PAGE_NAME" \
    --chrome-flags="--headless --no-sandbox" \
    --preset=desktop \
    --quiet
  
  # Extrair scores do JSON
  if [ -f "$OUTPUT_DIR/lighthouse-$PAGE_NAME.report.json" ]; then
    python3 -c "
import json
with open('$OUTPUT_DIR/lighthouse-$PAGE_NAME.report.json') as f:
    data = json.load(f)
cats = data['categories']
scores = {k: int(v['score']*100) for k,v in cats.items()}
print(f'  Performance:    {scores.get(\"performance\", 0):>3}')
print(f'  Accessibility:  {scores.get(\"accessibility\", 0):>3}')
print(f'  Best Practices: {scores.get(\"best-practices\", 0):>3}')
print(f'  SEO:            {scores.get(\"seo\", 0):>3}')
" 2>/dev/null || echo "  (scores não disponíveis)"
  fi
  echo ""
done

echo "Auditoria concluída. Relatórios HTML em: $OUTPUT_DIR/"
```

### Executar em modo mobile (adicional)

```bash
lighthouse "$URL" \
  --output=json \
  --output-path=lighthouse-mobile \
  --chrome-flags="--headless --no-sandbox" \
  --preset=perf \
  --form-factor=mobile \
  --screenEmulation.mobile \
  --throttling.cpuSlowdownMultiplier=4
```

---

## Resultados da Auditoria (Desktop)

### Tabela de Scores por Página

| Página | Performance | Accessibility | Best Practices | SEO | Meta atingida? |
|--------|:-----------:|:-------------:|:--------------:|:---:|:--------------:|
| Home (/) | — | — | — | — | Pendente |
| About | — | — | — | — | Pendente |
| Pricing | — | — | — | — | Pendente |
| Blog | — | — | — | — | Pendente |
| Contact | — | — | — | — | Pendente |
| 404 | — | — | — | — | Pendente |
| **Meta** | **≥ 90** | **≥ 90** | **≥ 90** | **≥ 90** | — |

---

## Métricas Core Web Vitals (Esperadas)

| Métrica | Sigla | Meta | Bom | Ruim |
|---------|-------|------|-----|------|
| Largest Contentful Paint | LCP | ≤ 1.8s | ≤ 2.5s | > 4.0s |
| Total Blocking Time | TBT | ≤ 200ms | ≤ 300ms | > 600ms |
| Cumulative Layout Shift | CLS | ≤ 0.1 | ≤ 0.1 | > 0.25 |
| First Contentful Paint | FCP | ≤ 1.2s | ≤ 1.8s | > 3.0s |
| Speed Index | SI | ≤ 1.5s | ≤ 3.4s | > 5.8s |
| Time to Interactive | TTI | ≤ 2.0s | ≤ 3.8s | > 7.3s |

---

## Plano de Melhoria por Categoria

### Performance (meta: ≥ 90)

**Otimizações de Imagem:**
```bash
# Converter imagens para WebP
for img in website/assets/images/*.png website/assets/images/*.jpg; do
  cwebp -q 85 "$img" -o "${img%.*}.webp"
done

# Adicionar atributo loading="lazy" em imagens abaixo da dobra
# No HTML:
# <img src="..." alt="..." loading="lazy" decoding="async">
```

**Minificação de CSS (Tailwind):**
```bash
# Instalar dependências
npm install -D tailwindcss autoprefixer

# Criar tailwind.config.js com purge configurado
# Build de produção:
npx tailwindcss -i website/css/input.css -o website/css/output.min.css --minify
```

**Melhorias de HTML para Performance:**
```html
<!-- Preconnect para domínios externos -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>

<!-- Preload do logo (LCP element) -->
<link rel="preload" as="image" href="/assets/images/logo-lexend.webp">

<!-- Defer scripts não críticos -->
<script src="app.js" defer></script>

<!-- Font display swap -->
<link href="https://fonts.googleapis.com/css2?family=Lexend:wght@400;600;700&display=swap" rel="stylesheet">
```

**Cache Headers (Vercel/Nginx):**
```json
// vercel.json
{
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    },
    {
      "source": "/(.*).html",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=0, must-revalidate" }
      ]
    }
  ]
}
```

### Accessibility (meta: ≥ 90)

Ver documento completo: [LS-168 — Acessibilidade WCAG](./LS-168-acessibilidade-wcag.md)

Correções mais impactantes para o score do Lighthouse:
1. Adicionar `alt` em todas as imagens
2. Garantir contraste 4.5:1 em todos os textos
3. Adicionar `lang="pt-BR"` no `<html>`
4. Associar labels a todos os inputs (`<label for="">`)
5. Adicionar `aria-label` em ícones sem texto

### Best Practices (meta: ≥ 90)

```html
<!-- HTTPS configurado (Vercel faz isso automaticamente) -->

<!-- CSP Header (Content Security Policy) -->
<!-- vercel.json: -->
{
  "headers": [{
    "source": "/(.*)",
    "headers": [{
      "key": "Content-Security-Policy",
      "value": "default-src 'self'; img-src 'self' data: https:; font-src 'self' https://fonts.gstatic.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com"
    }]
  }]
}

<!-- Sem bibliotecas JavaScript com vulnerabilidades conhecidas -->
<!-- Verificar: npx audit-ci --moderate -->

<!-- Imagens com aspect-ratio definido (evitar layout shift) -->
<img src="..." alt="..." width="800" height="600">
```

### SEO (meta: ≥ 90)

```html
<!-- Meta tags obrigatórias em cada página -->
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Lexend Scholar — Gestão Escolar para Escolas Privadas</title>
  <meta name="description" content="Sistema de gestão escolar completo: frequência digital, boletim, notas e financeiro para escolas privadas brasileiras.">
  
  <!-- Open Graph -->
  <meta property="og:title" content="Lexend Scholar — Gestão Escolar">
  <meta property="og:description" content="...">
  <meta property="og:image" content="https://lexendscholar.com.br/assets/og-image.png">
  <meta property="og:url" content="https://lexendscholar.com.br">
  <meta property="og:type" content="website">
  
  <!-- Canonical -->
  <link rel="canonical" href="https://lexendscholar.com.br/">
  
  <!-- robots.txt e sitemap.xml -->
</head>
```

```
# website/robots.txt
User-agent: *
Allow: /
Sitemap: https://lexendscholar.com.br/sitemap.xml
```

```xml
<!-- website/sitemap.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://lexendscholar.com.br/</loc><priority>1.0</priority></url>
  <url><loc>https://lexendscholar.com.br/about.html</loc><priority>0.8</priority></url>
  <url><loc>https://lexendscholar.com.br/pricing.html</loc><priority>0.9</priority></url>
  <url><loc>https://lexendscholar.com.br/blog.html</loc><priority>0.7</priority></url>
  <url><loc>https://lexendscholar.com.br/contact.html</loc><priority>0.6</priority></url>
</urlset>
```

---

## Integração no CI/CD

```yaml
# .github/workflows/lighthouse.yml
name: Lighthouse Audit

on:
  push:
    branches: [main]
  pull_request:
    paths: ['website/**']

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install Lighthouse
        run: npm install -g lighthouse
      
      - name: Serve website
        run: |
          npm install -g serve
          serve website -p 8080 &
          sleep 5
      
      - name: Run Lighthouse (Home)
        run: |
          lighthouse http://localhost:8080 \
            --output=json \
            --output-path=lh-home \
            --chrome-flags="--headless --no-sandbox --disable-gpu" \
            --quiet
          
          # Checar scores mínimos
          python3 -c "
          import json, sys
          with open('lh-home.report.json') as f:
              data = json.load(f)
          cats = data['categories']
          failed = []
          for cat, info in cats.items():
              score = int(info['score'] * 100)
              if score < 90:
                  failed.append(f'{cat}: {score} (meta: 90)')
          if failed:
              print('FALHA — scores abaixo da meta:')
              for f in failed: print(f'  - {f}')
              sys.exit(1)
          else:
              print('OK — todos os scores >= 90')
          "
      
      - name: Upload Lighthouse Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: lighthouse-reports
          path: 'lh-*.report.html'
```

---

## Referências

- [Lighthouse — Google](https://developer.chrome.com/docs/lighthouse/)
- [Core Web Vitals — Google Search Central](https://developers.google.com/search/docs/appearance/core-web-vitals)
- [PageSpeed Insights](https://pagespeed.web.dev/)
- [Acessibilidade — LS-168](./LS-168-acessibilidade-wcag.md)
- [Release Criteria — LS-166](./LS-166-release-criteria.md)
