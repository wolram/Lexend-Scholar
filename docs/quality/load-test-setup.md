# Load Test Setup — API Lexend Scholar

> Issue: LS-162 | Criar load test para API: 100 alunos simultâneos

---

## Instalação do k6

### macOS (Homebrew)
```bash
brew install k6
k6 version  # verificar instalação
```

### Linux (Debian/Ubuntu)
```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update && sudo apt-get install k6
```

### Docker
```bash
docker pull grafana/k6
```

---

## Como Rodar o Script

### Contra ambiente local
```bash
# Garantir que a API está rodando em localhost:3000
k6 run scripts/qa/load-test-api.js
```

### Contra staging
```bash
API_URL=https://api-staging.lexendscholar.com.br k6 run scripts/qa/load-test-api.js
```

### Contra produção (cuidado — usar fora do horário de pico)
```bash
API_URL=https://api.lexendscholar.com.br k6 run scripts/qa/load-test-api.js
```

### Com output detalhado em JSON
```bash
k6 run --out json=docs/quality/load-test-results.json scripts/qa/load-test-api.js
```

### Via Docker
```bash
docker run --rm -i grafana/k6 run - < scripts/qa/load-test-api.js
```

---

## Interpretação dos Resultados

### Saída do k6

Após a execução, o k6 exibe um sumário como:

```
data_received..................: 45 MB  188 kB/s
data_sent......................: 8.9 MB 37 kB/s
http_req_blocked...............: avg=1.4ms   min=1µs    med=5µs    max=1.22s  p(90)=9µs    p(95)=12µs
http_req_connecting............: avg=952µs   min=0s     med=0s     max=1.22s  p(90)=0s     p(95)=0s
http_req_duration..............: avg=213ms   min=1.3ms  med=167ms  max=1.89s  p(90)=421ms  p(95)=489ms ✓
http_req_failed................: 0.00%  ✓ 0 out of 5430
http_reqs......................: 5430   22.625/s
iteration_duration.............: avg=2.35s   min=1.18s  med=2.26s  max=5.12s  p(90)=2.98s  p(95)=3.21s
iterations.....................: 1086   4.525/s
vus............................: 1      min=1        max=100
vus_max........................: 100    min=100      max=100
```

### Thresholds e Significado

| Threshold | Meta | Significado se Falhar |
|-----------|------|----------------------|
| `http_req_duration p(95) < 500ms` | 95% das requests respondem em < 500ms | API lenta — investigar N+1 queries, falta de índices no banco, ou lock contention |
| `http_req_failed rate < 0.01` | Menos de 1% de erros | Instabilidade da API — verificar logs de erro, timeouts, out-of-memory |

### Métricas Importantes

| Métrica | Como Ler |
|---------|---------|
| `http_req_duration p(95)` | Tempo que 95% das requests completam — o mais importante |
| `http_req_failed` | Taxa de erros HTTP (4xx/5xx são contados como falha) |
| `http_reqs` | Total de requests enviadas |
| `iterations` | Quantas vezes o script completo rodou |
| `vus` | Virtual users ativos no momento |

---

## Thresholds Detalhados por Endpoint

Para análise mais granular, adicione grupos ao script:

```javascript
import { group } from 'k6';

export default function () {
  group('auth', () => {
    // login
  });

  group('students', () => {
    // listar alunos
  });

  group('attendance', () => {
    // registrar frequência
  });
}
```

Thresholds por grupo:
```javascript
export const options = {
  thresholds: {
    'http_req_duration{group:::auth}': ['p(95)<300'],
    'http_req_duration{group:::students}': ['p(95)<400'],
    'http_req_duration{group:::attendance}': ['p(95)<500'],
  },
};
```

---

## Adicionando ao CI (GitHub Actions)

```yaml
name: Load Test

on:
  workflow_dispatch:
    inputs:
      api_url:
        description: 'URL da API para testar'
        required: true
        default: 'https://api-staging.lexendscholar.com.br'

jobs:
  load-test:
    name: API Load Test (100 users)
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install k6
        run: |
          sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
            --keyserver hkp://keyserver.ubuntu.com:80 \
            --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
          echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
            | sudo tee /etc/apt/sources.list.d/k6.list
          sudo apt-get update && sudo apt-get install k6

      - name: Run load test
        env:
          API_URL: ${{ github.event.inputs.api_url }}
        run: k6 run --out json=load-test-results.json scripts/qa/load-test-api.js

      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: load-test-results
          path: load-test-results.json
```

> **Nota:** Não rodar load test automático em PRs — apenas manual via `workflow_dispatch` contra staging. Rodar contra produção apenas fora do horário de pico (ex: 2h–4h da manhã).

---

## Interpretando Problemas Comuns

### p95 acima de 500ms
- Verificar queries lentas: `EXPLAIN ANALYZE` no PostgreSQL/Supabase
- Adicionar índices nas colunas mais filtradas (`student_id`, `class_id`, `date`)
- Verificar N+1 queries nos logs do ORM

### Taxa de erro > 1%
- Verificar logs de erro no Supabase/servidor
- Verificar se há limite de conexões no banco (Supabase Free: 60 connections)
- Considerar connection pooling com PgBouncer

### Timeout no login
- Verificar rate limiting configurado — pode estar bloqueando VUs do k6
- Usar IPs de staging na whitelist do rate limiter
