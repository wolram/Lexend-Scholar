# LS-4 — Configurar Variáveis de Ambiente e Secrets

## Visão Geral

Este documento define todas as variáveis de ambiente necessárias para o Lexend Scholar, como organizá-las por ambiente e como gerenciá-las de forma segura.

## Ambientes

| Ambiente | Uso                  | Fonte de Secrets         |
|----------|----------------------|--------------------------|
| `dev`    | Desenvolvimento local| `.env.local` (gitignored)|
| `staging`| Testes/QA            | GitHub Secrets + Vercel  |
| `prod`   | Produção             | GitHub Secrets + Vercel  |

## Variáveis por Serviço

### Supabase

```bash
# URL pública do projeto Supabase (usada no cliente)
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co

# Chave anônima (segura para expor no cliente — respeita RLS)
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...

# Service Role Key — NUNCA expor no cliente
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# URL direta do banco (migrations, scripts admin)
SUPABASE_DB_URL=postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres

# URL pooled (Next.js server-side, API routes)
DATABASE_URL=postgresql://postgres.<ref>:<password>@aws-0-sa-east-1.pooler.supabase.com:6543/postgres
```

### Stripe

```bash
# Chave pública (cliente)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_...

# Chave secreta (servidor apenas)
STRIPE_SECRET_KEY=sk_live_...

# Webhook secret (validação de eventos Stripe)
STRIPE_WEBHOOK_SECRET=whsec_...

# IDs dos produtos/prices
STRIPE_PRICE_STARTER=price_...
STRIPE_PRICE_PRO=price_...
STRIPE_PRICE_ENTERPRISE=price_...
```

### iOS App (Supabase Swift)

Configurar no Xcode via `Info.plist` ou variáveis de ambiente do Xcode Cloud:

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=eyJ...
SENTRY_DSN_IOS=https://<key>@<org>.ingest.sentry.io/<project>
```

### Sentry

```bash
# Web (Next.js)
SENTRY_DSN=https://<key>@<org>.ingest.sentry.io/<project>
SENTRY_ORG=lexend-scholar
SENTRY_PROJECT=lexend-scholar-web
SENTRY_AUTH_TOKEN=sntrys_...

# iOS (Xcode Cloud)
SENTRY_DSN_IOS=https://<key>@<org>.ingest.sentry.io/<project-ios>
```

### Aplicação Web

```bash
# URL base da aplicação
NEXT_PUBLIC_APP_URL=https://app.lexendscholar.com.br

# Ambiente
NODE_ENV=production
NEXT_PUBLIC_ENV=production

# Segredo para NextAuth/cookies (se aplicável)
NEXTAUTH_SECRET=<32-bytes-hex>
NEXTAUTH_URL=https://app.lexendscholar.com.br
```

### Notificações Push (iOS)

```bash
# Apple Push Notification Service
APNS_KEY_ID=<key-id>
APNS_TEAM_ID=<team-id>
APNS_BUNDLE_ID=com.lexendscholar.app
# O arquivo .p8 deve ser armazenado como secret base64
APNS_PRIVATE_KEY_BASE64=<base64-encoded-p8>
```

## Arquivo .env.local (desenvolvimento)

Criar `.env.local` na raiz do projeto web (nunca commitar):

```bash
# .env.local — Development
NEXT_PUBLIC_SUPABASE_URL=https://<ref-dev>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
SUPABASE_DB_URL=postgresql://postgres:<password>@db.<ref-dev>.supabase.co:5432/postgres
DATABASE_URL=postgresql://postgres.<ref-dev>:<password>@aws-0-sa-east-1.pooler.supabase.com:6543/postgres

NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

SENTRY_DSN=
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development
```

## Gitignore

Garantir que os arquivos de environment estão no `.gitignore`:

```gitignore
# Environment files
.env
.env.local
.env.*.local
.env.development.local
.env.test.local
.env.production.local

# iOS secrets
*.p8
*.mobileprovision
ExportOptions.plist
```

## GitHub Secrets

Configurar em `Settings → Secrets and variables → Actions`:

### Production Secrets

| Nome do Secret                        | Descrição                          |
|---------------------------------------|-------------------------------------|
| `SUPABASE_URL_PROD`                   | URL do projeto prod                 |
| `SUPABASE_ANON_KEY_PROD`              | Anon key prod                       |
| `SUPABASE_SERVICE_ROLE_KEY_PROD`      | Service role key prod               |
| `SUPABASE_DB_URL_PROD`               | Database URL prod                   |
| `STRIPE_SECRET_KEY_PROD`             | Stripe secret key live              |
| `STRIPE_WEBHOOK_SECRET_PROD`         | Stripe webhook secret prod          |
| `SENTRY_AUTH_TOKEN`                  | Token para upload de source maps    |
| `APNS_PRIVATE_KEY_BASE64`            | Chave APNs em base64                |

### Staging Secrets

| Nome do Secret                        | Descrição                          |
|---------------------------------------|-------------------------------------|
| `SUPABASE_URL_STAGING`               | URL do projeto staging              |
| `SUPABASE_ANON_KEY_STAGING`          | Anon key staging                    |
| `SUPABASE_SERVICE_ROLE_KEY_STAGING`  | Service role key staging            |
| `STRIPE_SECRET_KEY_STAGING`          | Stripe secret key test              |

## Vercel Environment Variables

Configurar via `vercel env add` ou dashboard:

```bash
# Adicionar variável de produção
vercel env add NEXT_PUBLIC_SUPABASE_URL production
vercel env add SUPABASE_SERVICE_ROLE_KEY production

# Adicionar variável de preview (staging)
vercel env add NEXT_PUBLIC_SUPABASE_URL preview

# Pull para .env.local
vercel env pull .env.local
```

## Rotação de Secrets

- **Supabase JWT Secret**: Rotacionar a cada 90 dias em prod
- **Stripe Webhook Secret**: Rotacionar se houver suspeita de comprometimento
- **Service Role Key**: Nunca expor; rotacionar imediatamente se comprometida
- Usar o script `scripts/rotate-secrets.sh` para automação

## Auditoria

Verificar se algum secret foi comprometido:

```bash
# Verificar se há secrets no histórico git
git log --all --full-history -- "*.env*"
git secrets --scan-history

# Instalar git-secrets
brew install git-secrets
git secrets --install
git secrets --register-aws
```

## Referências

- `docs/infra/supabase-setup.md` — configuração Supabase
- `docs/infra/encryption-ssl.md` — criptografia e SSL
- [Supabase Secrets](https://supabase.com/docs/guides/functions/secrets)
- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
