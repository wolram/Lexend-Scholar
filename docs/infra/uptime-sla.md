# LS-15 — Configurar Alertas de Uptime e Definir SLA

## Visão Geral

Este documento define o SLA de disponibilidade do Lexend Scholar, configura o monitoramento de uptime via BetterStack e estabelece os procedimentos de resposta a alertas.

## SLA por Componente

### Disponibilidade Garantida

| Componente              | SLA      | Downtime máx/mês | Downtime máx/ano |
|-------------------------|----------|------------------|------------------|
| API Backend (Supabase)  | 99.9%    | 43,8 min         | 8,7 h            |
| Web App (Vercel)        | 99.95%   | 21,9 min         | 4,4 h            |
| Autenticação            | 99.9%    | 43,8 min         | 8,7 h            |
| Processamento Financeiro| 99.5%    | 3,6 h            | 43,8 h           |
| Sistema geral (SLA cliente) | 99.5% | 3,6 h           | 43,8 h           |

### Exclusões de SLA

- Manutenções planejadas com aviso prévio ≥ 48h
- Incidentes causados pelo Supabase, Vercel ou AWS (fora de controle)
- Ataques DDoS de grande escala
- Force majeure

## BetterStack — Uptime Monitoring

### Monitors Configurados

| Monitor                        | URL / Check                                  | Frequência | Alertar em  |
|--------------------------------|----------------------------------------------|-----------|-------------|
| API Health Check               | `https://app.lexendscholar.com.br/api/health`| 1 min     | 2 falhas    |
| Web App Homepage               | `https://app.lexendscholar.com.br`           | 1 min     | 2 falhas    |
| Supabase Auth                  | `https://<ref>.supabase.co/auth/v1/health`   | 2 min     | 2 falhas    |
| Status Page (própria)          | `https://status.lexendscholar.com.br`        | 5 min     | 3 falhas    |

### Configuração via BetterStack API

```bash
#!/bin/bash
# scripts/setup-betterstack.sh

BETTERSTACK_TOKEN="$BETTERSTACK_API_TOKEN"
BASE_URL="https://uptime.betterstack.com/api/v2"

create_monitor() {
  local name="$1" url="$2" freq="$3"
  curl -s -X POST "$BASE_URL/monitors" \
    -H "Authorization: Bearer $BETTERSTACK_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"monitor_type\": \"status\",
      \"url\": \"$url\",
      \"friendly_name\": \"$name\",
      \"check_frequency\": $freq,
      \"expected_status_codes\": [200, 204],
      \"confirmation_period\": 120,
      \"call\": true,
      \"email\": true,
      \"slack\": true,
      \"paused\": false
    }"
}

create_monitor "Lexend Scholar — API Health" \
  "https://app.lexendscholar.com.br/api/health" 60

create_monitor "Lexend Scholar — Web App" \
  "https://app.lexendscholar.com.br" 60

create_monitor "Lexend Scholar — Auth" \
  "https://${SUPABASE_REF}.supabase.co/auth/v1/health" 120

echo "Monitors configurados!"
```

### Status Page

```bash
# Criar status page no BetterStack
curl -X POST "$BASE_URL/status-pages" \
  -H "Authorization: Bearer $BETTERSTACK_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "company_name": "Lexend Scholar",
    "company_website": "https://lexendscholar.com.br",
    "subdomain": "status-lexend",
    "custom_domain": "status.lexendscholar.com.br",
    "timezone": "America/Sao_Paulo",
    "subscribable": true
  }'
```

Configurar CNAME: `status.lexendscholar.com.br` → `<subdomain>.betteruptime.com`

## Alertas no Sentry

### Error Rate Alert

```json
{
  "name": "High Error Rate",
  "aggregate": "percentage(sessions_crashed, sessions)",
  "query": "",
  "threshold_type": "above",
  "critical_threshold": 1.0,
  "warning_threshold": 0.5,
  "time_window": 5,
  "alert_channel": "slack-lexend-alerts"
}
```

### Latência Alta

```json
{
  "name": "API P95 Latency High",
  "aggregate": "p95(transaction.duration)",
  "query": "transaction.op:http.server",
  "threshold_type": "above",
  "critical_threshold": 3000,
  "warning_threshold": 1500,
  "time_window": 10,
  "alert_channel": "slack-lexend-alerts"
}
```

## GitHub Actions — Verificação de Saúde Pós-Deploy

```yaml
# Adicionar ao workflow de deploy
- name: Health check pós-deploy
  run: |
    echo "Aguardando 30s para propagação..."
    sleep 30

    MAX_ATTEMPTS=10
    ATTEMPT=0

    until [ $ATTEMPT -ge $MAX_ATTEMPTS ]; do
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        https://app.lexendscholar.com.br/api/health)

      if [ "$STATUS" = "200" ]; then
        echo "Health check passed (status: $STATUS)"
        exit 0
      fi

      echo "Attempt $((ATTEMPT+1))/$MAX_ATTEMPTS — status: $STATUS"
      ATTEMPT=$((ATTEMPT+1))
      sleep 10
    done

    echo "Health check FAILED após $MAX_ATTEMPTS tentativas"
    exit 1
```

## Relatório Mensal de SLA

Script para gerar relatório de disponibilidade:

```bash
#!/bin/bash
# scripts/sla-report.sh — Gerar relatório mensal de SLA

MONTH="${1:-$(date +%Y-%m)}"
BETTERSTACK_TOKEN="$BETTERSTACK_API_TOKEN"

echo "=== Relatório de SLA — $MONTH ==="
echo ""

# Buscar estatísticas de uptime via API BetterStack
curl -s "https://uptime.betterstack.com/api/v2/monitors?page=1" \
  -H "Authorization: Bearer $BETTERSTACK_TOKEN" \
  | jq '.data[] | {name: .attributes.url, uptime: .attributes.availability}'
```

## Definição de Incidente para SLA

Um incidente que impacta o SLA é definido como:

1. **Indisponibilidade total**: endpoint `/api/health` retornando código diferente de 200 por > 2 minutos consecutivos
2. **Degradação severa**: P95 de latência > 10 segundos por > 5 minutos
3. **Taxa de erro elevada**: > 5% das requisições retornando 5xx por > 5 minutos

## Comunicação de Incidentes

### Canais por Severidade

| Severidade | Slack       | E-mail    | Status Page | SMS/Ligue |
|------------|-------------|-----------|-------------|-----------|
| P1         | Imediato    | 5 min     | 5 min       | Sim       |
| P2         | Imediato    | 15 min    | 15 min      | Não       |
| P3         | 30 min      | 1 hora    | 1 hora      | Não       |

### Templates de Status Page

**Em andamento**:
```
Estamos investigando um problema que pode estar afetando [componente].
Início: [hora]. Próxima atualização: [hora].
```

**Resolvido**:
```
O incidente foi resolvido às [hora]. Causa: [breve descrição].
Post-mortem será publicado em até 48 horas.
```

## Checklist

- [ ] Conta BetterStack criada e configurada
- [ ] 3 monitores ativos (API, Web, Auth)
- [ ] Status page configurada com domínio customizado
- [ ] CNAME `status.lexendscholar.com.br` configurado
- [ ] Alertas Sentry de error rate e latência ativos
- [ ] Health check pós-deploy adicionado ao CI
- [ ] Canais Slack `#alerts` e `#incidents` configurados para receber alertas
- [ ] `BETTERSTACK_API_TOKEN` configurado nos GitHub Secrets
- [ ] Relatório mensal de SLA agendado

## Referências

- `docs/infra/rto-rpo.md` — objetivos RTO/RPO
- `docs/infra/contingency-plan.md` — resposta a incidentes
- `docs/infra/api-monitoring.md` — monitoramento de API
- [BetterStack Docs](https://betterstack.com/docs/uptime/)
- [Sentry Alerts](https://docs.sentry.io/product/alerts/)
