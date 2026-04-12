# LS-14 — Configurar Logs e Monitoramento de API

## Visão Geral

O monitoramento de API do Lexend Scholar cobre o Supabase (PostgREST + Auth), as API Routes do Next.js no Vercel e as chamadas de rede do iOS. A stack de observabilidade usa Sentry, Vercel Analytics e logs nativos do Supabase.

## Stack de Observabilidade

| Camada                  | Ferramenta            | O que monitora                         |
|-------------------------|-----------------------|----------------------------------------|
| Erros e crashes         | Sentry                | Exceções, stack traces, contexto       |
| Performance web         | Vercel Analytics      | TTFB, LCP, CLS, FID por rota          |
| Logs de função          | Vercel Runtime Logs   | stdout/stderr de API routes            |
| Banco de dados          | Supabase Dashboard    | Query performance, conexões, erros     |
| Auth                    | Supabase Auth Logs    | Logins, falhas, cadastros              |
| Uptime                  | BetterStack           | Health checks externos                 |

## 1. Sentry — Monitoramento de API Routes (Next.js)

### Instalação

```bash
npx @sentry/wizard@latest -i nextjs
```

Ou manualmente:

```bash
npm install @sentry/nextjs
```

### Configuração

```typescript
// sentry.server.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NEXT_PUBLIC_ENV ?? 'development',
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
  integrations: [
    Sentry.prismaIntegration(), // se usar Prisma
  ],
  beforeSend(event) {
    // Redactar Authorization header dos breadcrumbs
    if (event.request?.headers) {
      delete event.request.headers['authorization']
      delete event.request.headers['cookie']
    }
    return event
  },
})
```

```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NEXT_PUBLIC_ENV ?? 'development',
  tracesSampleRate: 0.1,
  replaysSessionSampleRate: 0.05,
  replaysOnErrorSampleRate: 1.0,
  integrations: [
    Sentry.replayIntegration({
      maskAllText: true,
      blockAllMedia: true,
    }),
  ],
})
```

### Instrumentação de API Routes

```typescript
// lib/api-logger.ts
import * as Sentry from '@sentry/nextjs'
import { NextRequest } from 'next/server'

export interface APIMetrics {
  route: string
  method: string
  statusCode: number
  duration: number
  schoolId?: string
  userId?: string
  error?: Error
}

export function logAPICall(metrics: APIMetrics) {
  // Log estruturado para Vercel Logs
  console.log(JSON.stringify({
    type: 'api_call',
    route: metrics.route,
    method: metrics.method,
    status: metrics.statusCode,
    duration_ms: metrics.duration,
    school_id: metrics.schoolId,
    user_id: metrics.userId,
    timestamp: new Date().toISOString(),
  }))

  // Erro para Sentry se necessário
  if (metrics.error || metrics.statusCode >= 500) {
    Sentry.withScope(scope => {
      scope.setTag('route', metrics.route)
      scope.setContext('api', {
        method: metrics.method,
        statusCode: metrics.statusCode,
        durationMs: metrics.duration,
      })
      if (metrics.error) {
        Sentry.captureException(metrics.error)
      } else {
        Sentry.captureMessage(`API error ${metrics.statusCode}: ${metrics.route}`, 'error')
      }
    })
  }
}

// Wrapper para API routes
export function withMonitoring(
  handler: (req: NextRequest) => Promise<Response>,
  routeName: string
) {
  return async (req: NextRequest): Promise<Response> => {
    const start = Date.now()

    try {
      const response = await handler(req)
      logAPICall({
        route: routeName,
        method: req.method,
        statusCode: response.status,
        duration: Date.now() - start,
      })
      return response
    } catch (error) {
      logAPICall({
        route: routeName,
        method: req.method,
        statusCode: 500,
        duration: Date.now() - start,
        error: error instanceof Error ? error : new Error(String(error)),
      })
      throw error
    }
  }
}
```

## 2. Vercel Analytics e Speed Insights

```typescript
// app/layout.tsx
import { Analytics } from '@vercel/analytics/react'
import { SpeedInsights } from '@vercel/speed-insights/next'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt-BR">
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  )
}
```

Instalar pacotes:

```bash
npm install @vercel/analytics @vercel/speed-insights
```

## 3. Supabase — Monitoramento de Banco

### Dashboard nativo

Supabase Dashboard → **Reports**:

- **Query Performance**: queries mais lentas (P50, P95, P99)
- **Database Health**: conexões ativas, cache hit rate, index usage
- **Auth Activity**: logins, registros, tokens expirados

### Alertas de Performance

Configurar via Supabase CLI:

```bash
# Queries lentas (> 500ms)
psql "$SUPABASE_DB_URL" -c "
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 500
ORDER BY mean_exec_time DESC
LIMIT 20;"
```

### Log de Erros de API (PostgREST)

Acessar em Supabase Dashboard → **Logs → API Logs**. Filtros úteis:

```
status_code:500         -- erros de servidor
status_code:403         -- violações de RLS
path:/rest/v1/students  -- queries em tabela específica
```

## 4. Health Check Endpoint

Criar endpoint para monitoramento externo:

```typescript
// app/api/health/route.ts
import { createClient } from '@supabase/supabase-js'
import { NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

export async function GET() {
  const checks: Record<string, 'ok' | 'error'> = {}
  let overallStatus = 200

  // Check banco de dados
  try {
    const supabase = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!
    )
    const { error } = await supabase.from('schools').select('id').limit(1)
    checks.database = error ? 'error' : 'ok'
    if (error) overallStatus = 503
  } catch {
    checks.database = 'error'
    overallStatus = 503
  }

  return NextResponse.json(
    {
      status: overallStatus === 200 ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      checks,
    },
    { status: overallStatus }
  )
}
```

## 5. Alertas de Monitoramento

### BetterStack (Uptime Monitor)

```bash
# Configurar monitor via API BetterStack
curl -X POST https://uptime.betterstack.com/api/v2/monitors \
  -H "Authorization: Bearer $BETTERSTACK_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://app.lexendscholar.com.br/api/health",
    "monitor_type": "status",
    "check_frequency": 60,
    "expected_status_codes": [200],
    "call": true,
    "email": true,
    "slack": true,
    "team_wait": 5
  }'
```

### Sentry Alerts

| Alert                     | Threshold               | Destino            |
|---------------------------|-------------------------|--------------------|
| Error rate                | > 1% em 5 min           | Slack `#alerts`    |
| Slow API (P95)            | > 3000ms em 10 min      | Slack `#alerts`    |
| New fatal issue           | Qualquer ocorrência     | Slack + email      |
| Volume de erros           | > 100 erros em 1h       | PagerDuty          |

## Checklist

- [ ] `@sentry/nextjs` instalado e configurado
- [ ] `sentry.server.config.ts` e `sentry.client.config.ts` criados
- [ ] `@vercel/analytics` e `@vercel/speed-insights` instalados
- [ ] Health check endpoint `/api/health` criado
- [ ] BetterStack monitor apontando para `/api/health`
- [ ] Variáveis `SENTRY_DSN`, `SENTRY_AUTH_TOKEN` configuradas no Vercel
- [ ] Alertas de error rate e performance configurados no Sentry
- [ ] Supabase Reports habilitados

## Referências

- `docs/infra/sentry-ios-setup.md` — Sentry para iOS
- `docs/infra/uptime-sla.md` — SLA e alertas
- [Sentry Next.js Docs](https://docs.sentry.io/platforms/javascript/guides/nextjs/)
- [Vercel Analytics](https://vercel.com/docs/analytics)
- [Supabase Logs](https://supabase.com/docs/guides/platform/logs)
