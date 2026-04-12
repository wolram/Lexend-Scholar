# Deploy no Vercel — Lexend Scholar Website

Processo completo para fazer deploy do website `lexendscholar.com.br` no Vercel,
desde a instalação da CLI até a configuração do domínio personalizado com HTTPS.

---

## Visão geral da configuração

| Campo | Valor |
|-------|-------|
| Framework | Static HTML (sem framework) |
| Build command | `cd website && npm install && npm run build` |
| Output directory | `website` |
| Região | `gru1` (São Paulo) |
| Arquivo de config | `vercel.json` na raiz do repositório |

O build compila o Tailwind CSS local (`website/input.css → website/assets/css/style.css`)
antes de servir os arquivos estáticos.

---

## 1. Pré-requisitos

```bash
# Instalar Vercel CLI globalmente
npm install -g vercel

# Verificar instalação
vercel --version
```

Conta necessária: acesso ao time **lexend-scholar** no Vercel Dashboard
(`vercel.com/lexend-scholar`).

---

## 2. Primeiro deploy (setup inicial)

### Vincular o repositório ao projeto Vercel

```bash
# No diretório raiz do repositório
cd "/path/to/Sistema de Gestao Escolar"

# Login na conta Vercel (abre browser)
vercel login

# Vincular ao projeto existente (ou criar novo)
vercel link
# → Responder às perguntas:
#   Set up "~/...": Y
#   Which scope: lexend-scholar (ou seu time)
#   Link to existing project: Y → lexend-scholar
#   (ou N para criar novo projeto)
```

### Deploy de preview (branch/PR)

```bash
# Deploy de preview — não vai para produção
vercel

# Vercel retorna uma URL de preview, ex:
# https://lexend-scholar-git-feature-xyz-lexendscholar.vercel.app
```

### Deploy de produção

```bash
# Deploy para produção (lexendscholar.com.br)
vercel --prod
```

---

## 3. Variáveis de ambiente

O website atual é estático e não requer variáveis de ambiente no Vercel.
Se no futuro forem adicionados form handlers ou edge functions, usar:

```bash
# Adicionar variável
vercel env add NOME_DA_VAR production

# Listar variáveis
vercel env ls

# Puxar variáveis para .env.local (desenvolvimento)
vercel env pull .env.local
```

Nunca commitar `.env.local` no repositório — ele está no `.gitignore`.

---

## 4. Configurar domínio personalizado

### Via Vercel Dashboard

1. Acessar `vercel.com/lexend-scholar/lexend-scholar/settings/domains`
2. Clicar em **Add Domain**
3. Digitar `lexendscholar.com.br` → **Add**
4. Vercel mostrará os registros DNS a configurar:

| Tipo | Nome | Valor |
|------|------|-------|
| `A` | `@` | `76.76.21.21` |
| `CNAME` | `www` | `cname.vercel-dns.com` |

5. Configurar esses registros no painel do registrador de domínio (ex.: Registro.br, Cloudflare, GoDaddy)
6. Aguardar propagação DNS (geralmente 5–30 minutos; pode levar até 48h)
7. Vercel provisiona o certificado TLS/HTTPS automaticamente via Let's Encrypt

### Via Vercel CLI

```bash
# Adicionar domínio ao projeto
vercel domains add lexendscholar.com.br

# Verificar status do domínio
vercel domains ls

# Inspecionar certificado e DNS
vercel certs ls
```

### Subdomínios

```bash
# App web (quando existir)
vercel domains add app.lexendscholar.com.br

# Staging/preview
vercel domains add staging.lexendscholar.com.br
```

---

## 5. Deploy contínuo via GitHub

O Vercel está integrado ao repositório GitHub. A cada push:

| Branch | Ação |
|--------|------|
| `main` | Deploy automático para produção (`lexendscholar.com.br`) |
| Qualquer outra branch | Deploy de preview com URL única |
| Pull Request aberto | Preview deployment + comentário automático no PR |

Para desativar o deploy automático em uma branch específica:
```bash
# No vercel.json, adicionar:
# "github": { "silent": false, "autoJobCancelation": true }
# (já configurado)
```

---

## 6. Reverter um deploy (rollback)

### Via Dashboard

1. Acessar `vercel.com/lexend-scholar/lexend-scholar/deployments`
2. Localizar o deploy estável anterior
3. Clicar nos três pontos → **Promote to Production**

### Via CLI

```bash
# Listar deployments recentes
vercel ls

# Promover deployment específico para produção
vercel promote <deployment-url-ou-id>

# Exemplo:
vercel promote https://lexend-scholar-abc123.vercel.app
```

---

## 7. Monitoramento e logs

```bash
# Ver logs em tempo real do último deployment de produção
vercel logs lexend-scholar --follow

# Ver logs de um deployment específico
vercel logs <deployment-url>

# Inspecionar detalhes de um deployment
vercel inspect <deployment-url>
```

---

## 8. Headers de segurança

O `vercel.json` já configura os seguintes headers em todas as rotas:

| Header | Valor |
|--------|-------|
| `X-Content-Type-Options` | `nosniff` |
| `X-Frame-Options` | `DENY` |
| `X-XSS-Protection` | `1; mode=block` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Content-Security-Policy` | Restringe scripts/estilos a origens confiáveis |
| `Cache-Control` (HTML) | `no-cache, must-revalidate` |
| `Cache-Control` (assets) | `max-age=31536000, immutable` |

---

## 9. URLs limpas e rewrites

O `vercel.json` configura `"cleanUrls": true` e rewrites para URLs sem extensão `.html`:

| URL de entrada | Serve |
|----------------|-------|
| `/` | `index.html` |
| `/sobre` | `about.html` |
| `/precos` | `pricing.html` |
| `/contato` | `contact.html` |
| `/blog` | `blog.html` |
| `/carreiras` | `careers.html` |
| `/privacidade` | `privacy.html` |
| `/termos` | `terms.html` |
| `/lgpd` | `lgpd.html` |

---

## 10. Checklist de deploy

```
[ ] vercel.json revisado e commitado
[ ] Build local testado: cd website && npm install && npm run build
[ ] Todas as páginas abrindo localmente: npx serve website
[ ] vercel (preview) executado e URL testada
[ ] vercel --prod executado
[ ] Domínio lexendscholar.com.br resolvendo corretamente
[ ] HTTPS ativo (cadeado verde no browser)
[ ] Headers de segurança verificados (securityheaders.com)
[ ] Lighthouse score > 90 em todas as páginas
[ ] Analytics Plausible registrando visitas
[ ] Redirects funcionando (/about → /sobre, etc.)
```
