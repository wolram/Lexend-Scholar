# Componentes Web — Equivalentes iOS → Web

> Mapeamento dos componentes SwiftUI do Lexend Scholar para seus equivalentes HTML + Tailwind CSS.
> Última revisão: 2026-04-12.

## Configuração Base Tailwind

Adicione ao `tailwind.config.js`:

```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  theme: {
    extend: {
      colors: {
        school: {
          primary:       '#137FEC',
          background:    '#F6F7F8',
          surface:       '#FFFFFF',
          surfaceAlt:    '#F1F3FD',
          primaryText:   '#111418',
          secondaryText: '#617589',
          success:       '#12965B',
          warning:       '#F59E0B',
          danger:        '#EF4444',
          violet:        '#6366F1',
        },
      },
      fontFamily: {
        school: ['Lexend', 'system-ui', 'sans-serif'],
      },
      borderRadius: {
        card:   '28px',
        search: '18px',
        icon:   '14px',
        chip:   '9999px',
      },
    },
  },
}
```

---

## 1. SchoolCard → `.school-card`

**iOS:** `SchoolCard<Content>` — card com padding 24pt, corner radius 28, sombra sutil.

**Web:**

```html
<!-- SchoolCard simples -->
<div class="school-card">
  <div class="school-card-header">
    <h3 class="school-card-title">Título do Card</h3>
    <p class="school-card-subtitle">Subtítulo do card</p>
  </div>
  <div class="school-card-body">
    <!-- conteúdo -->
  </div>
</div>
```

**CSS com Tailwind:**

```html
<!-- Usando classes Tailwind diretamente -->
<div class="bg-white rounded-[28px] p-6 shadow-[0_10px_18px_rgba(0,0,0,0.04)] border border-black/[0.06] w-full">
  <!-- Header (opcional) -->
  <div class="flex flex-col gap-1.5 mb-4">
    <h3 class="text-[22px] font-bold text-school-primaryText font-school leading-tight">
      Título do Card
    </h3>
    <p class="text-[14px] font-medium text-school-secondaryText font-school">
      Subtítulo do card
    </p>
  </div>
  <!-- Conteúdo -->
  <div><!-- ... --></div>
</div>
```

**Classe CSS reutilizável (globals.css):**

```css
.school-card {
  @apply bg-white rounded-[28px] p-6 w-full;
  @apply shadow-[0_10px_18px_rgba(0,0,0,0.04)];
  @apply border border-black/[0.06];
}
.school-card-title {
  @apply text-[22px] font-bold text-[#111418] leading-tight;
  font-family: 'Lexend', system-ui, sans-serif;
}
.school-card-subtitle {
  @apply text-[14px] font-medium text-[#617589];
  font-family: 'Lexend', system-ui, sans-serif;
}
```

---

## 2. SchoolSectionHeader → `<h2 class="school-section-header">`

**iOS:** `SchoolSectionHeader` — eyebrow label + título 34pt bold + subtítulo + trailing view.

**Web:**

```html
<div class="flex items-start justify-between gap-5">
  <div class="flex flex-col gap-2">
    <!-- Eyebrow (opcional) -->
    <span class="text-[11px] font-semibold text-[#617589] tracking-[0.12em] uppercase font-school">
      MÓDULO
    </span>

    <!-- Título principal -->
    <h2 class="text-[34px] font-bold text-[#111418] leading-tight font-school">
      Alunos
    </h2>

    <!-- Subtítulo -->
    <p class="text-[16px] font-medium text-[#617589] font-school">
      Gerencie os alunos matriculados na escola
    </p>
  </div>

  <!-- Trailing action (opcional) -->
  <button class="flex-shrink-0 bg-[#137FEC] text-white px-4 py-2 rounded-full font-semibold text-sm font-school hover:bg-blue-600 transition-colors">
    + Novo Aluno
  </button>
</div>
```

**Responsivo (mobile-first):**

```html
<div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
  <div>
    <span class="block text-xs font-semibold text-school-secondaryText tracking-widest uppercase mb-2 font-school">
      SECRETARIA
    </span>
    <h2 class="text-3xl sm:text-[34px] font-bold text-school-primaryText font-school">
      Matrículas
    </h2>
    <p class="text-base font-medium text-school-secondaryText mt-2 font-school">
      Gerencie as matrículas do ano letivo
    </p>
  </div>
  <div class="flex-shrink-0"><!-- trailing --></div>
</div>
```

---

## 3. NavigationSplitView → Sidebar CSS Responsiva

**iOS:** `NavigationSplitView` — sidebar colapsável com lista de rotas + detail view.

**Web — Layout de duas colunas com sidebar:**

```html
<div class="flex min-h-screen bg-[#F6F7F8]">
  <!-- Sidebar -->
  <aside id="sidebar"
    class="fixed inset-y-0 left-0 z-50 w-64 bg-white border-r border-black/[0.06] shadow-lg
           transform -translate-x-full transition-transform duration-300 ease-in-out
           lg:relative lg:translate-x-0 lg:shadow-none">

    <!-- Logo -->
    <div class="flex items-center gap-3 px-6 py-5 border-b border-black/[0.06]">
      <div class="w-9 h-9 bg-[#137FEC] rounded-xl flex items-center justify-center">
        <span class="text-white font-bold text-sm">LS</span>
      </div>
      <span class="font-bold text-[#111418] text-lg font-school">Lexend Scholar</span>
    </div>

    <!-- Navegação -->
    <nav class="px-4 py-4 flex flex-col gap-1">
      <a href="/dashboard"
        class="flex items-center gap-3 px-3 py-2.5 rounded-xl text-[15px] font-medium font-school
               text-[#111418] hover:bg-[#F1F3FD] transition-colors
               [&.active]:bg-[#137FEC]/10 [&.active]:text-[#137FEC]">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <!-- ícone dashboard -->
        </svg>
        Dashboard
      </a>
      <a href="/alunos"
        class="flex items-center gap-3 px-3 py-2.5 rounded-xl text-[15px] font-medium font-school
               text-[#111418] hover:bg-[#F1F3FD] transition-colors">
        Alunos
      </a>
      <a href="/turmas" class="flex items-center gap-3 px-3 py-2.5 rounded-xl text-[15px] font-medium font-school text-[#111418] hover:bg-[#F1F3FD] transition-colors">Turmas</a>
      <a href="/professores" class="flex items-center gap-3 px-3 py-2.5 rounded-xl text-[15px] font-medium font-school text-[#111418] hover:bg-[#F1F3FD] transition-colors">Professores</a>
      <a href="/financeiro" class="flex items-center gap-3 px-3 py-2.5 rounded-xl text-[15px] font-medium font-school text-[#111418] hover:bg-[#F1F3FD] transition-colors">Financeiro</a>
      <a href="/comunicados" class="flex items-center gap-3 px-3 py-2.5 rounded-xl text-[15px] font-medium font-school text-[#111418] hover:bg-[#F1F3FD] transition-colors">Comunicados</a>
    </nav>
  </aside>

  <!-- Overlay mobile -->
  <div id="sidebar-overlay"
    class="fixed inset-0 z-40 bg-black/40 hidden lg:hidden"
    onclick="closeSidebar()">
  </div>

  <!-- Conteúdo principal -->
  <main class="flex-1 min-w-0 p-6 lg:p-8">
    <!-- header mobile com hamburger -->
    <div class="flex items-center gap-4 mb-6 lg:hidden">
      <button onclick="toggleSidebar()"
        class="p-2 rounded-xl hover:bg-[#F1F3FD] transition-colors">
        <svg class="w-6 h-6 text-[#111418]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
        </svg>
      </button>
      <span class="font-bold text-[#111418] font-school">Lexend Scholar</span>
    </div>

    <!-- Conteúdo da página -->
    <slot />
  </main>
</div>

<script>
function toggleSidebar() {
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('sidebar-overlay');
  sidebar.classList.toggle('-translate-x-full');
  overlay.classList.toggle('hidden');
}
function closeSidebar() {
  document.getElementById('sidebar').classList.add('-translate-x-full');
  document.getElementById('sidebar-overlay').classList.add('hidden');
}
</script>
```

---

## 4. StatusChip → `.school-chip`

**iOS:** `StatusChip` — badge com uppercase, cor semântica, fundo com opacidade.

```html
<!-- Variantes de StatusChip -->
<span class="inline-flex items-center px-3 py-1.5 rounded-full text-[11px] font-bold uppercase tracking-wide font-school bg-[#12965B]/10 text-[#12965B]">
  ATIVO
</span>

<span class="inline-flex items-center px-3 py-1.5 rounded-full text-[11px] font-bold uppercase tracking-wide font-school bg-[#EF4444]/10 text-[#EF4444]">
  INATIVO
</span>

<span class="inline-flex items-center px-3 py-1.5 rounded-full text-[11px] font-bold uppercase tracking-wide font-school bg-[#F59E0B]/10 text-[#F59E0B]">
  PENDENTE
</span>
```

---

## 5. MetricCard → `.school-metric-card`

**iOS:** `MetricCard` — card com ícone, título, valor grande, badge de variação.

```html
<div class="school-card">
  <div class="flex flex-col gap-4">
    <!-- Cabeçalho com ícone e variação -->
    <div class="flex items-center justify-between">
      <div class="w-[52px] h-[52px] rounded-[14px] bg-[#137FEC]/12 flex items-center justify-center flex-shrink-0">
        <svg class="w-6 h-6 text-[#137FEC]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <!-- ícone -->
        </svg>
      </div>
      <span class="text-[12px] font-bold font-school px-2.5 py-1.5 rounded-full bg-[#12965B]/12 text-[#12965B]">
        +5.2%
      </span>
    </div>

    <!-- Valor e título -->
    <div class="flex flex-col gap-1.5">
      <p class="text-[15px] font-medium text-[#617589] font-school">Total de Alunos</p>
      <p class="text-[34px] font-bold text-[#111418] leading-none font-school">342</p>
    </div>
  </div>
</div>
```

---

## 6. SchoolSearchBar → `<input class="school-search">`

```html
<div class="relative">
  <div class="absolute inset-y-0 left-4 flex items-center pointer-events-none">
    <svg class="w-5 h-5 text-[#617589]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0"/>
    </svg>
  </div>
  <input
    type="search"
    placeholder="Buscar alunos..."
    class="w-full pl-12 pr-4 py-3.5 bg-white/80 border border-black/[0.06] rounded-[18px]
           text-[15px] font-medium text-[#111418] font-school placeholder:text-[#617589]
           shadow-[0_8px_12px_rgba(0,0,0,0.03)] focus:outline-none focus:ring-2
           focus:ring-[#137FEC]/30 focus:border-[#137FEC]/40 transition-all"
  />
</div>
```

---

## 7. InitialAvatar → `.school-avatar`

```html
<!-- Avatar com iniciais -->
<div class="w-12 h-12 rounded-full bg-[#137FEC]/14 flex items-center justify-center flex-shrink-0">
  <span class="text-[16px] font-bold text-[#137FEC] font-school">AB</span>
</div>

<!-- Variante pequena (32px) -->
<div class="w-8 h-8 rounded-full bg-[#6366F1]/14 flex items-center justify-center flex-shrink-0">
  <span class="text-[11px] font-bold text-[#6366F1] font-school">CF</span>
</div>
```
