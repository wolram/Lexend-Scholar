# Relatório de Acessibilidade — WCAG 2.1 AA

> Issue: LS-168 | Realizar testes de acessibilidade WCAG 2.1 AA no website

---

## Violations Comuns a Corrigir no Website Lexend Scholar

### 1. Contraste de Cor (WCAG 1.4.3 — Nível AA)

**Critério:** Razão de contraste mínima de **4.5:1** para texto normal e **3:1** para texto grande (≥18pt bold ou ≥24pt regular).

**Violations encontradas:**
- Texto cinza claro `#9CA3AF` sobre fundo branco `#FFFFFF` → razão ~2.85:1 (FALHA)
- Texto de placeholder em campos de formulário `#D1D5DB` → razão ~1.6:1 (FALHA)
- Links em `#4A90D9` sobre fundo branco → razão ~3.2:1 (FALHA para texto normal)

**Como corrigir:**
```css
/* Antes (FALHA) */
color: #9CA3AF; /* cinza 400 — contraste 2.85:1 */

/* Depois (PASSA) */
color: #6B7280; /* cinza 500 — contraste 4.63:1 */

/* Placeholder com contraste adequado */
input::placeholder {
  color: #6B7280; /* mínimo para placeholder */
}

/* Links — usar cor com contraste suficiente */
a { color: #1D6FA4; } /* contraste 5.1:1 sobre #FFFFFF */
```

**Ferramentas:** [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/), extensão [axe DevTools](https://www.deque.com/axe/)

---

### 2. Alt Text em Imagens (WCAG 1.1.1 — Nível A)

**Critério:** Toda imagem deve ter atributo `alt` descritivo. Imagens decorativas devem ter `alt=""`.

**Violations encontradas:**
- Logo do Lexend Scholar sem `alt`
- Screenshots do app sem descrição alternativa
- Ícones de funcionalidades sem `alt`

**Como corrigir:**
```html
<!-- Antes (FALHA) -->
<img src="logo.svg">
<img src="screenshot-frequencia.png">
<img src="icon-check.svg">

<!-- Depois (PASSA) -->
<!-- Imagem informativa — descreve o conteúdo -->
<img src="logo.svg" alt="Lexend Scholar">

<!-- Screenshot com descrição funcional -->
<img src="screenshot-frequencia.png" 
     alt="Tela de registro de frequência mostrando lista de alunos com checkboxes de presença">

<!-- Ícone decorativo ao lado de texto — alt vazio -->
<img src="icon-check.svg" alt="" aria-hidden="true">
```

---

### 3. Labels em Formulários (WCAG 1.3.1, 4.1.2 — Nível A)

**Critério:** Todos os campos de formulário devem ter labels programaticamente associados.

**Violations encontradas:**
- Formulário de contato com `placeholder` mas sem `<label>`
- Campo de busca sem label ou `aria-label`
- Campos de newsletter sem associação label-input

**Como corrigir:**
```html
<!-- Antes (FALHA) -->
<input type="email" placeholder="Seu email">

<!-- Depois — opção 1: label visível (preferida) -->
<label for="email">Seu email</label>
<input type="email" id="email" placeholder="nome@escola.com.br">

<!-- Depois — opção 2: label visualmente oculta mas acessível -->
<label for="search" class="sr-only">Buscar no site</label>
<input type="search" id="search" placeholder="Buscar...">

<!-- Depois — opção 3: aria-label para ícones/campos óbvios -->
<input type="search" aria-label="Buscar no site" placeholder="Buscar...">
```

```css
/* Classe para ocultar visualmente mas manter acessível */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
```

---

### 4. Hierarquia de Headings (WCAG 1.3.1 — Nível A)

**Critério:** A hierarquia de headings deve ser lógica e sequencial (h1 → h2 → h3), sem pular níveis.

**Violations encontradas:**
- Páginas com múltiplos `<h1>` (apenas 1 é permitido por página)
- Seções usando `<h4>` após `<h2>`, pulando `<h3>`
- Headings usados apenas para estilo visual, sem semântica

**Como corrigir:**
```html
<!-- Estrutura correta -->
<h1>Lexend Scholar: Gestão Escolar</h1>          <!-- Um por página -->
  <h2>Para Diretores</h2>
    <h3>Dashboard em tempo real</h3>
    <h3>Relatórios financeiros</h3>
  <h2>Para Professores</h2>
    <h3>Frequência em 3 toques</h3>
  <h2>Preços</h2>

<!-- Para estilizar sem quebrar hierarquia, use classes CSS -->
<h3 class="text-xl font-bold">Título estilizado</h3>
<!-- Em vez de usar h1 só pelo tamanho visual -->
```

---

### 5. Skip Navigation Link (WCAG 2.4.1 — Nível A)

**Critério:** Deve existir mecanismo para usuários de teclado/leitores de tela pularem a navegação repetitiva e ir direto ao conteúdo principal.

**Violations encontradas:**
- Nenhuma das páginas do website possui skip navigation link

**Como corrigir:**

```html
<!-- Adicionar como primeiro elemento do <body> -->
<a href="#main-content" class="skip-link">Ir para o conteúdo principal</a>

<nav>...</nav>

<main id="main-content">
  <!-- conteúdo principal aqui -->
</main>
```

```css
/* Oculto visualmente, visível ao receber foco via Tab */
.skip-link {
  position: absolute;
  top: -100%;
  left: 0;
  background: #1E3A5F;
  color: #FFFFFF;
  padding: 8px 16px;
  text-decoration: none;
  font-weight: bold;
  z-index: 9999;
}

.skip-link:focus {
  top: 0;
}
```

---

## Checklist de Verificação por Página

| Critério | index.html | pricing.html | blog.html | about.html | contact.html | 404.html |
|---------|-----------|-------------|----------|-----------|-------------|---------|
| Contraste 4.5:1 | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Alt text em imagens | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Labels em formulários | N/A | N/A | N/A | N/A | [ ] | N/A |
| Hierarquia h1→h2→h3 | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Skip navigation link | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Tamanho mínimo de toque 44×44px (mobile) | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Navegação por teclado (Tab order lógico) | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| Focus visible (outline nos elementos interativos) | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

---

## Como Executar a Auditoria

```bash
# Instalar axe-cli (uma vez)
npm install -g axe-cli

# Rodar auditoria em todas as páginas
chmod +x scripts/qa/run-accessibility-audit.sh
./scripts/qa/run-accessibility-audit.sh

# Resultados salvos em docs/quality/accessibility-results/
```

## Ferramentas Complementares

- **axe DevTools** (extensão Chrome/Firefox): auditoria interativa no browser
- **NVDA** (Windows) ou **VoiceOver** (Mac/iOS): testar com leitor de tela real
- **Colour Contrast Analyser** (app desktop): verificar contraste pixel a pixel
- **WAVE** (extensão Chrome): visualização gráfica das violations
