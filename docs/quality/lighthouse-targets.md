# Lighthouse Targets — Lexend Scholar Website

> Issue: LS-160 | Executar auditoria Lighthouse no website (meta: score >90)

---

## Metas por Categoria

| Categoria | Meta Mínima | Meta Ideal | Status Atual |
|-----------|------------|-----------|-------------|
| Performance | ≥ 90 | 95+ | A medir |
| Accessibility | ≥ 90 | 100 | A medir |
| Best Practices | ≥ 90 | 100 | A medir |
| SEO | ≥ 90 | 100 | A medir |

---

## Metas por Métrica de Performance

| Métrica | Sigla | Meta | Referência (Good) |
|---------|-------|------|------------------|
| Largest Contentful Paint | LCP | ≤ 1.8s | ≤ 2.5s (Google) |
| Total Blocking Time | TBT | ≤ 200ms | ≤ 200ms (Google) |
| Cumulative Layout Shift | CLS | ≤ 0.1 | ≤ 0.1 (Google) |
| First Contentful Paint | FCP | ≤ 1.2s | ≤ 1.8s (Google) |
| Speed Index | SI | ≤ 2.0s | ≤ 3.4s (Google) |
| Time to Interactive | TTI | ≤ 2.5s | ≤ 3.8s (Google) |

---

## Guia de Melhorias Específicas

### 1. Lazy Loading de Imagens

Todas as imagens abaixo do fold devem usar `loading="lazy"`:

```html
<!-- Antes -->
<img src="screenshot-app.png" width="800" height="600">

<!-- Depois -->
<img src="screenshot-app.png" 
     width="800" 
     height="600" 
     loading="lazy"
     decoding="async"
     alt="Screenshot do app Lexend Scholar mostrando o dashboard">
```

Usar formatos modernos para reduzir tamanho:
```html
<picture>
  <source srcset="screenshot-app.webp" type="image/webp">
  <source srcset="screenshot-app.avif" type="image/avif">
  <img src="screenshot-app.png" alt="..." loading="lazy">
</picture>
```

### 2. Remover Tailwind CDN e Usar Build Local

O CDN do Tailwind carrega o CSS completo (~3MB), causando TBT elevado.

```html
<!-- Antes (RUIM — CDN dev-only) -->
<script src="https://cdn.tailwindcss.com"></script>

<!-- Depois — usar PostCSS build -->
<link rel="stylesheet" href="/assets/css/tailwind.min.css">
```

Build do Tailwind com purge:
```bash
# Instalar dependências
npm install -D tailwindcss postcss autoprefixer

# Criar tailwind.config.js
npx tailwindcss init

# Build com purge do CSS não utilizado
npx tailwindcss -i ./src/input.css -o ./website/assets/css/tailwind.min.css --minify
```

`tailwind.config.js`:
```javascript
module.exports = {
  content: ["./website/**/*.html", "./website/**/*.js"],
  theme: { extend: {} },
  plugins: [],
}
```

**Impacto esperado:** redução de 3MB → ~15KB no CSS, melhoria de TBT de ~800ms → <50ms.

### 3. Preload de Fontes (Inter e SF Pro)

```html
<!-- No <head>, antes do link do CSS -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>

<!-- Preload das variantes mais usadas -->
<link rel="preload" as="font" type="font/woff2"
      href="https://fonts.gstatic.com/s/inter/v13/UcCO3FwrK3iLTeHuS_fvQtMwCp50KnMw2boKoduKmMEVuLyfAZ9hiJ-Ek-_EeA.woff2"
      crossorigin>

<!-- Carregar via Google Fonts com display=swap -->
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
```

Para fontes locais (mais rápido):
```css
@font-face {
  font-family: 'Inter';
  src: url('/assets/fonts/Inter-Regular.woff2') format('woff2');
  font-weight: 400;
  font-display: swap; /* Evita FOIT */
}
```

### 4. Meta Tags Open Graph e Twitter Card

Adicionar em todas as páginas para melhorar SEO e compartilhamento:

```html
<head>
  <!-- Open Graph (Facebook, LinkedIn, WhatsApp) -->
  <meta property="og:title" content="Lexend Scholar: Gestão Escolar">
  <meta property="og:description" content="Gerencie frequência, notas e financeiro da sua escola em um app. Boletim em PDF, comunicação com pais e controle de inadimplência.">
  <meta property="og:image" content="https://lexendscholar.com.br/assets/og-image.jpg">
  <meta property="og:url" content="https://lexendscholar.com.br">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="pt_BR">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Lexend Scholar: Gestão Escolar">
  <meta name="twitter:description" content="Gerencie frequência, notas e financeiro da sua escola em um app.">
  <meta name="twitter:image" content="https://lexendscholar.com.br/assets/og-image.jpg">

  <!-- Canonical URL -->
  <link rel="canonical" href="https://lexendscholar.com.br">

  <!-- Meta description (SEO) -->
  <meta name="description" content="Lexend Scholar é o sistema de gestão escolar completo para escolas particulares. Frequência, boletins e financeiro em um app. 14 dias grátis.">
</head>
```

**Especificações da imagem OG:**
- Tamanho: 1200×630px
- Formato: JPG ou PNG
- Conteúdo: logo + headline + screenshot do app

### 5. Otimização Adicional de Performance

**Minificar HTML:**
```bash
npm install -g html-minifier-terser
html-minifier-terser website/index.html \
  --collapse-whitespace \
  --remove-comments \
  --minify-css \
  --minify-js \
  -o website/index.min.html
```

**Adicionar cache headers (via servidor ou Vercel):**
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
        { "key": "Cache-Control", "value": "public, max-age=3600, must-revalidate" }
      ]
    }
  ]
}
```

---

## Como Rodar a Auditoria

```bash
# Instalar Lighthouse (se necessário)
npm install -g lighthouse

# Rodar para todas as páginas
chmod +x scripts/qa/run-lighthouse.sh
./scripts/qa/run-lighthouse.sh

# Verificar regressões vs. baseline
python3 scripts/qa/check-performance-regression.py docs/quality/lighthouse-index.json
```

---

## Interpretação dos Scores

| Score | Faixa | Significado |
|-------|-------|-------------|
| Verde | 90–100 | Bom — meta atingida |
| Laranja | 50–89 | Precisa melhorar |
| Vermelho | 0–49 | Ruim — correção urgente |
