# Analytics — Lexend Scholar Website

O website do Lexend Scholar usa **Plausible Analytics** como solução de analytics
privacy-first, sem cookies, sem GDPR/LGPD consent banner, sem dados pessoais.

---

## Por que Plausible?

| Critério | Plausible | Google Analytics 4 |
|----------|-----------|---------------------|
| Cookies | Não usa | Usa (requer consent) |
| LGPD | Compliant out-of-the-box | Requer banner de consent |
| Dados pessoais | Nenhum coletado | IP, User-Agent, etc. |
| Open source | Sim | Não |
| Dashboard simples | Sim | Complexo |
| Peso do script | ~1 KB | ~45 KB |
| Servidor dos dados | UE (GDPR) | EUA |

---

## Setup — Como foi configurado

### Script adicionado em todas as páginas

O seguinte snippet foi adicionado antes de `</body>` em todas as páginas do website:

```html
<!-- Analytics: Plausible (ver docs/eng/analytics.md) -->
<script defer data-domain="lexendscholar.com.br" src="https://plausible.io/js/script.js"></script>
```

- `defer`: não bloqueia o carregamento da página
- `data-domain`: identifica o site no dashboard Plausible
- O script é carregado do CDN da Plausible (não há dependência local)

### Páginas com tracking

Todas as 9 páginas do website têm o script instalado:
- `/` — index.html
- `/sobre` — about.html
- `/precos` — pricing.html
- `/blog` — blog.html
- `/contato` — contact.html
- `/carreiras` — careers.html
- `/privacidade` — privacy.html
- `/termos` — terms.html
- `/lgpd` — lgpd.html

---

## Configuração no Plausible Dashboard

### 1. Criar conta e adicionar site

1. Acessar [plausible.io](https://plausible.io) e criar conta
2. Clicar em **+ Add website**
3. Domain: `lexendscholar.com.br`
4. Reporting timezone: `America/Sao_Paulo`
5. Clicar em **Add snippet** — copiar o código e confirmar que está nos HTMLs

### 2. Verificar instalação

Após adicionar o snippet, o Plausible mostra uma página de verificação.
Acessar qualquer página do site — a visita deve aparecer em tempo real no dashboard.

### 3. Configurar goals (eventos personalizados)

Para rastrear conversões (CTA clicks, formulários), adicionar custom events:

```html
<!-- Exemplo: rastrear clique no botão "Começar Grátis" -->
<a href="https://app.lexendscholar.com.br/cadastro"
   onclick="plausible('Signup CTA Click', {props: {location: 'hero'}})"
   class="bg-primary text-white ...">
  Começar Grátis
</a>
```

**Goals sugeridos para configurar no Plausible:**

| Goal | Trigger | Página |
|------|---------|--------|
| `Signup CTA Click` | Click em "Começar Grátis" | Todas |
| `Demo Request` | Click em "Ver Demonstração" | Homepage |
| `Contact Form Submit` | Submit do formulário | /contato |
| `Newsletter Signup` | Submit do form de newsletter | /blog |
| `Pricing View Pro` | Click em "Assinar Pro" | /precos |
| `Enterprise Contact` | Click em "Falar com Vendas" | /precos |

### 4. Configurar funnels (fluxo de conversão)

No dashboard Plausible > **Funnels**:
1. Criar funil: `Homepage → Pricing → Signup`
2. Steps:
   - Step 1: Pageview `/`
   - Step 2: Pageview `/precos`
   - Step 3: Goal `Signup CTA Click`

---

## Como ver os dados

### Dashboard principal

Acessar: `plausible.io/lexendscholar.com.br`

**Métricas disponíveis:**
- Visitantes únicos, pageviews, bounce rate, visit duration
- Fontes de tráfego (direto, Google, redes sociais, referrals)
- Páginas mais visitadas
- Países, cidades, idiomas
- Dispositivos (mobile, desktop, tablet)
- Navegadores e sistemas operacionais

### Filtros úteis

```
# Ver apenas tráfego orgânico do Google
Source: Google

# Ver usuários que visitaram a página de preços
Page: /precos

# Ver tráfego dos últimos 30 dias
Period: Last 30 days

# Ver dados de uma campanha específica (UTM)
UTM Campaign: google-ads-04-2025
```

### Relatórios por e-mail

No Plausible Dashboard > **Settings > Email Reports**:
- Configurar relatório semanal automático
- Destinatários: equipe de marketing e fundadores

---

## UTM Parameters para campanhas

Usar UTM params em todos os links externos para rastrear origem:

```
# Google Ads
https://www.lexendscholar.com.br/?utm_source=google&utm_medium=cpc&utm_campaign=gestao-escolar

# LinkedIn
https://www.lexendscholar.com.br/?utm_source=linkedin&utm_medium=social&utm_campaign=brand-awareness

# Email marketing
https://www.lexendscholar.com.br/precos?utm_source=email&utm_medium=newsletter&utm_campaign=upsell-pro
```

---

## Privacidade e LGPD

O Plausible:
- **Não usa cookies** — não requer banner de consentimento no Brasil (LGPD)
- **Não coleta dados pessoais** — IP é anonimizado, sem fingerprinting
- **Dados agregados apenas** — impossível identificar usuários individuais
- **Servidores na UE** — conformidade com GDPR por design

Esta configuração está mencionada na [Política de Privacidade](/privacy.html) e na
[página LGPD](/lgpd.html) do website.

---

## Acesso ao dashboard

| Perfil | Acesso |
|--------|--------|
| Fundadores | Admin — acesso total |
| Marketing | Viewer — leitura apenas |
| Engenharia | Admin — para configurar goals |

Solicitar acesso via `contato@lexendscholar.com.br` indicando o e-mail da conta Plausible.
