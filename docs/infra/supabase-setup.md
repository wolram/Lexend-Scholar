# LS-1 — Provisionar Projeto Supabase (Produção, Staging, Dev)

## Visão Geral

O Lexend Scholar utiliza três projetos Supabase isolados para garantir separação completa entre ambientes. Cada projeto tem sua própria instância de PostgreSQL, Auth, Storage e Realtime.

## Projetos

| Ambiente | Nome do Projeto        | URL de Referência                     | Região           |
|----------|------------------------|---------------------------------------|------------------|
| prod     | lexend-scholar-prod    | `https://<ref-prod>.supabase.co`      | sa-east-1 (SP)   |
| staging  | lexend-scholar-staging | `https://<ref-staging>.supabase.co`   | sa-east-1 (SP)   |
| dev      | lexend-scholar-dev     | `https://<ref-dev>.supabase.co`       | sa-east-1 (SP)   |

> Substitua `<ref-*>` pelo Project Reference ID exibido no dashboard de cada projeto.

## Pré-requisitos

- Conta Supabase com organização `Lexend Scholar`
- Supabase CLI instalado: `brew install supabase/tap/supabase`
- Acesso ao repositório `wolram/Lexend-Scholar`

## Criação dos Projetos via CLI

```bash
# Login
supabase login

# Criar projeto produção
supabase projects create lexend-scholar-prod \
  --org-id <org-id> \
  --region sa-east-1 \
  --db-password "<PROD_DB_PASSWORD>"

# Criar projeto staging
supabase projects create lexend-scholar-staging \
  --org-id <org-id> \
  --region sa-east-1 \
  --db-password "<STAGING_DB_PASSWORD>"

# Criar projeto dev
supabase projects create lexend-scholar-dev \
  --org-id <org-id> \
  --region sa-east-1 \
  --db-password "<DEV_DB_PASSWORD>"
```

## Estrutura de Links no Repositório

```bash
# Vincular projeto local ao ambiente dev
supabase link --project-ref <ref-dev>

# Para trocar de ambiente
supabase link --project-ref <ref-staging>
supabase link --project-ref <ref-prod>
```

## Migrations

Todas as migrations ficam em `supabase/migrations/`. Para aplicar:

```bash
# Dev
supabase db push

# Staging/Prod (via CI ou manualmente)
supabase db push --project-ref <ref-staging>
supabase db push --project-ref <ref-prod>
```

## Variáveis de Ambiente por Ambiente

Cada ambiente exporta as seguintes variáveis (salvas no GitHub Secrets e no Vercel):

```
NEXT_PUBLIC_SUPABASE_URL=https://<ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
SUPABASE_DB_URL=postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres
```

## Configurações do Dashboard

Para cada projeto, configurar no dashboard Supabase:

1. **Auth → Settings**
   - Site URL: URL do ambiente correspondente
   - Redirect URLs: incluir URLs do app iOS e web
   - Email templates: customizar com branding Lexend Scholar
   - JWT expiry: 3600s (prod), 86400s (dev)

2. **Storage → Buckets**
   - `avatars` — público, 5MB máx, accept: `image/*`
   - `documents` — privado, 50MB máx, accept: `application/pdf,image/*`
   - `reports` — privado, 20MB máx, accept: `application/pdf`

3. **Database → Extensions**
   - `uuid-ossp` — habilitado
   - `pgcrypto` — habilitado
   - `pg_stat_statements` — habilitado (monitoramento)

4. **API → Settings**
   - Schema exposto: `public`
   - Max rows: 1000 (prod), 5000 (dev)

## Configurações de Rede (produção)

- Habilitar SSL enforced
- Allowlist de IPs: IPs dos runners do GitHub Actions + IPs do Vercel
- Connection pooling: PgBouncer modo `transaction`, pool size 25

## Checklist de Provisionamento

- [ ] Projeto prod criado e linkado
- [ ] Projeto staging criado e linkado
- [ ] Projeto dev criado e linkado
- [ ] Migrations aplicadas nos três ambientes
- [ ] Buckets de Storage configurados
- [ ] Extensions habilitadas
- [ ] Variáveis exportadas para GitHub Secrets
- [ ] Variáveis exportadas para Vercel (prod e preview)
- [ ] Auth configurada por ambiente
- [ ] SSL enforced em produção

## Referências

- [Supabase CLI Docs](https://supabase.com/docs/guides/cli)
- [Supabase Projects API](https://supabase.com/docs/reference/api/introduction)
- `docs/infra/env-secrets.md` — gerenciamento de secrets
- `docs/infra/postgres-config.md` — configuração do schema
