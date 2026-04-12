# LS-9 — Configurar WAF e Rate Limiting

## Visão Geral

O Lexend Scholar implementa múltiplas camadas de proteção contra ataques: WAF via Vercel/Cloudflare, rate limiting na borda e proteção contra abusos na API Supabase.

## Camadas de Proteção

```
Internet → Cloudflare (WAF + DDoS) → Vercel Edge (Rate Limiting) → Next.js API → Supabase (RLS + Rate Limit)
                                                                         ↑
                                                              iOS App (certificate pinning)
```

## 1. Vercel — Rate Limiting na Borda

O Vercel oferece rate limiting configurável via `vercel.json` e Middleware:

### vercel.json

```json
{
  "functions": {
    "app/api/**": {
      "maxDuration": 30
    }
  }
}
```

### Middleware de Rate Limiting (Next.js)

Criar `middleware.ts` na raiz do projeto web:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(60, '1 m'), // 60 req/min por IP
  analytics: true,
  prefix: 'lexend:rl',
})

// Rate limits mais restritos por rota sensível
const strictLimiter = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.fixedWindow(10, '1 m'), // 10 req/min
  prefix: 'lexend:rl:strict',
})

const STRICT_ROUTES = [
  '/api/auth/login',
  '/api/auth/signup',
  '/api/auth/reset-password',
  '/api/stripe/webhook',
]

export async function middleware(req: NextRequest) {
  const ip = req.headers.get('x-forwarded-for')?.split(',')[0] ?? '127.0.0.1'
  const pathname = req.nextUrl.pathname

  // Selecionar limiter baseado na rota
  const limiter = STRICT_ROUTES.some(r => pathname.startsWith(r))
    ? strictLimiter
    : ratelimit

  const { success, limit, reset, remaining } = await limiter.limit(ip)

  if (!success) {
    return NextResponse.json(
      { error: 'Too Many Requests', retryAfter: Math.ceil((reset - Date.now()) / 1000) },
      {
        status: 429,
        headers: {
          'X-RateLimit-Limit': limit.toString(),
          'X-RateLimit-Remaining': remaining.toString(),
          'X-RateLimit-Reset': reset.toString(),
          'Retry-After': Math.ceil((reset - Date.now()) / 1000).toString(),
        },
      }
    )
  }

  const response = NextResponse.next()
  response.headers.set('X-RateLimit-Limit', limit.toString())
  response.headers.set('X-RateLimit-Remaining', remaining.toString())
  response.headers.set('X-RateLimit-Reset', reset.toString())

  return response
}

export const config = {
  matcher: ['/api/:path*'],
}
```

### Variáveis necessárias

```bash
UPSTASH_REDIS_REST_URL=https://<region>.upstash.io
UPSTASH_REDIS_REST_TOKEN=<token>
```

## 2. Supabase — Rate Limiting Nativo

Configurar no dashboard em **Settings → API → Rate Limiting**:

| Endpoint                    | Limite Padrão | Configurado |
|-----------------------------|--------------|-------------|
| `POST /auth/v1/token`       | 30/hora      | 30/hora     |
| `POST /auth/v1/signup`      | 30/hora      | 10/hora     |
| `POST /auth/v1/recover`     | 2/hora       | 2/hora      |
| `POST /auth/v1/otp`         | 60/hora      | 30/hora     |
| REST API (geral)            | Sem limite   | Via Middleware |

## 3. Cloudflare WAF (Opcional — Domínio Customizado)

Se o domínio `app.lexendscholar.com.br` for roteado via Cloudflare:

### Regras WAF Recomendadas

```
Regra 1: Block SQL Injection
  - Expression: (cf.waf.score.sqli > 50)
  - Action: Block

Regra 2: Block XSS
  - Expression: (cf.waf.score.xss > 50)
  - Action: Block

Regra 3: Block Bad Bots
  - Expression: (cf.client.bot) and not (cf.verified_bot_category in {"Search Engine Crawlers" "Monitoring & Analytics"})
  - Action: Block

Regra 4: Rate Limit API
  - Expression: (http.request.uri.path matches "^/api/")
  - Rate: 200 requests per minute per IP
  - Action: Block for 60 seconds

Regra 5: Challenge Suspicious Countries (opcional)
  - Expression: (ip.geoip.country not in {"BR" "US" "PT"})
  - Action: Managed Challenge
```

### Cloudflare via Terraform (infra como código)

```hcl
# terraform/cloudflare.tf
resource "cloudflare_ruleset" "lexend_waf" {
  zone_id = var.cloudflare_zone_id
  name    = "Lexend Scholar WAF Rules"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules {
    action      = "block"
    expression  = "(cf.waf.score.sqli > 50) or (cf.waf.score.xss > 50)"
    description = "Block SQLi and XSS"
    enabled     = true
  }

  rules {
    action      = "block"
    expression  = "(http.request.uri.path matches \"^/api/auth\") and (rate.requests > 10)"
    description = "Rate limit auth endpoints"
    enabled     = true
  }
}
```

## 4. Proteção contra Abuse no iOS

O app iOS inclui proteção adicional:

```swift
// APIClient.swift — Retry com exponential backoff ao receber 429
func handleRateLimit(response: HTTPURLResponse) async throws {
    guard let retryAfter = response.value(forHTTPHeaderField: "Retry-After"),
          let seconds = TimeInterval(retryAfter) else {
        throw APIError.rateLimited(retryAfter: 60)
    }
    throw APIError.rateLimited(retryAfter: seconds)
}

// Usar retry com backoff exponencial
extension URLSession {
    func dataWithRetry(request: URLRequest, maxRetries: Int = 3) async throws -> (Data, URLResponse) {
        for attempt in 0..<maxRetries {
            do {
                return try await data(for: request)
            } catch APIError.rateLimited(let retryAfter) {
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
                } else {
                    throw APIError.rateLimited(retryAfter: retryAfter)
                }
            }
        }
        throw APIError.maxRetriesExceeded
    }
}
```

## 5. Monitoramento de Abusos

### Dashboard Upstash

Monitorar analytics de rate limiting em `https://console.upstash.com` → Redis → Analytics.

### Alertas via Sentry

```typescript
// Logar tentativas de rate limiting para análise
export async function middleware(req: NextRequest) {
  // ... rate limit check ...

  if (!success) {
    // Log para Sentry (sem dados pessoais)
    Sentry.captureEvent({
      message: 'Rate limit exceeded',
      level: 'warning',
      extra: {
        pathname: req.nextUrl.pathname,
        remaining,
        limit,
      },
    })

    return rateLimitResponse
  }
}
```

## Checklist

- [ ] Upstash Redis provisionado (via Vercel Marketplace ou direto)
- [ ] Middleware de rate limiting deployado
- [ ] Variáveis `UPSTASH_REDIS_REST_URL` e `UPSTASH_REDIS_REST_TOKEN` configuradas
- [ ] Rate limits do Supabase Auth configurados no dashboard
- [ ] Cloudflare configurado para domínio de produção (opcional)
- [ ] Regras WAF ativas e testadas
- [ ] Monitoramento de rate limiting no Upstash Analytics
- [ ] Alertas de abuso configurados no Sentry

## Referências

- `docs/infra/api-monitoring.md` — monitoramento e logs de API
- `docs/infra/uptime-sla.md` — SLA e alertas de uptime
- [Upstash Ratelimit](https://github.com/upstash/ratelimit-js)
- [Vercel Middleware](https://vercel.com/docs/functions/edge-middleware)
- [Cloudflare WAF Rules](https://developers.cloudflare.com/waf/custom-rules/)
