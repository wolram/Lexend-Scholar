# Changelog

Todas as mudanças relevantes do projeto Lexend Scholar serão documentadas aqui.

O formato segue o padrão [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/)
e o projeto adota o [Versionamento Semântico](https://semver.org/lang/pt-BR/).

A geração deste arquivo é automatizada via [git-cliff](https://git-cliff.org/)
a partir de [Conventional Commits](https://www.conventionalcommits.org/pt-br/).
Veja a convenção completa em [docs/eng/versioning.md](docs/eng/versioning.md).

---

## [Não lançado]

### Novidades
- feat: criar website MVP com HTML + Tailwind CDN
- feat: criar app SwiftUI de gestão escolar (módulos: alunos, turmas, notas, frequência)
- feat: homepage (index.html) com hero, features, testimonials, pricing preview e footer
- feat: páginas about, blog, pricing, contact, careers, privacy, terms, lgpd
- feat: partials de header e footer reutilizáveis (website/_partials/)
- feat: favicon SVG e meta Open Graph em todas as páginas
- feat: assets próprios SVG (logo, hero, ícones) — sem dependência de imagens externas
- feat: build Tailwind local com package.json, tailwind.config.js e input.css
- feat: vercel.json com outputDirectory, headers de segurança, rewrites e clean URLs
- feat: sitemap.xml e robots.txt para SEO
- feat: integração Plausible Analytics em todas as páginas
- feat: workflows CI — changelog automático, build website, notificações, cobertura, lint
- docs: convenção de versionamento semântico (docs/eng/versioning.md)
- docs: processo de release iOS/TestFlight (docs/eng/ios-release.md)
- docs: processo de deploy Vercel (docs/eng/vercel-deploy.md)
- docs: setup de analytics Plausible (docs/eng/analytics.md)

### Correções
- fix: substituir todos os href="#" por links reais ou remover CTAs sem destino
- fix: remover dependência de imagens externas (Unsplash, Picsum)

---

## [0.1.0] — 2025-04-12

### Novidades
- Importação inicial do projeto: estrutura de repositório, xcodeproj, scripts de CI
- Criação do app SwiftUI Lexend Scholar (iOS)
- Criação do website MVP (HTML + Tailwind)

---

<!-- Este arquivo é atualizado automaticamente pelo workflow .github/workflows/changelog.yml
     a cada push na branch main. Não edite manualmente as seções geradas. -->
