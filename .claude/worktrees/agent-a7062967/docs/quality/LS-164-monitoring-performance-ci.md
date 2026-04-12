# LS-164 — Configurar Monitoring de Performance Contínua no CI

## Objetivo

Integrar métricas de performance no pipeline CI/CD do Lexend Scholar,
alertar automaticamente quando houver regressões > 10% em relação ao baseline,
e manter histórico de trends para análise ao longo do tempo.

---

## Arquitetura de Monitoring

```
                    ┌─────────────────────┐
                    │   GitHub Actions CI  │
                    │                     │
  Push/PR ──────── │  ┌──────────────┐   │
                    │  │  Build App   │   │
                    │  └──────┬───────┘   │
                    │         │           │
                    │  ┌──────▼───────┐   │
                    │  │  Testes de   │   │
                    │  │  Performance │   │
                    │  └──────┬───────┘   │
                    │         │           │
                    │  ┌──────▼───────┐   │
                    │  │  Comparar    │   │
                    │  │  c/ Baseline │   │
                    │  └──────┬───────┘   │
                    │         │           │
                    └─────────┼───────────┘
                              │
               ┌──────────────┼──────────────┐
               │              │              │
          ✓ OK │        ⚠ +10%│        ✗ +25%│
               │              │              │
          Continua       Alerta Slack    Bloqueia Build
          o pipeline     #performance    + Issue Linear
```

---

## Métricas Monitoradas

### iOS

| Métrica | Baseline | Alerta (+10%) | Bloqueante (+25%) |
|---------|---------|--------------|------------------|
| Cold Start | 1,5s | > 1,65s | > 1,875s |
| Warm Start | 0,5s | > 0,55s | > 0,625s |
| Memória Idle | 80 MB | > 88 MB | > 100 MB |
| Memória Pico | 200 MB | > 220 MB | > 250 MB |

### Web (Lighthouse)

| Métrica | Baseline | Alerta | Bloqueante |
|---------|---------|--------|-----------|
| Performance Score | 90 | < 85 | < 80 |
| LCP | 1,8s | > 2,2s | > 2,8s |
| CLS | 0,05 | > 0,08 | > 0,12 |
| TBT | 150ms | > 220ms | > 300ms |

### API (k6)

| Métrica | Baseline | Alerta (+10%) | Bloqueante (+25%) |
|---------|---------|--------------|------------------|
| p95 latência (geral) | 350ms | > 385ms | > 438ms |
| p95 frequência | 300ms | > 330ms | > 375ms |
| p95 boletim | 400ms | > 440ms | > 500ms |
| Taxa de erro | 0,2% | > 0,5% | > 1,0% |

---

## Implementação — Script de Comparação com Baseline

```python
#!/usr/bin/env python3
# scripts/qa/check-performance-regression.py

import json
import sys
import os
from datetime import datetime

ALERT_THRESHOLD = 0.10    # 10% de aumento
BLOCK_THRESHOLD = 0.25    # 25% de aumento

def load_baseline(baseline_path: str) -> dict:
    """Carrega métricas de baseline salvas."""
    if not os.path.exists(baseline_path):
        print(f"AVISO: Baseline não encontrado em {baseline_path}")
        print("Primeira execução — salvando como baseline inicial.")
        return None
    
    with open(baseline_path) as f:
        return json.load(f)

def save_baseline(baseline_path: str, metrics: dict):
    """Salva métricas atuais como novo baseline."""
    os.makedirs(os.path.dirname(baseline_path), exist_ok=True)
    with open(baseline_path, 'w') as f:
        json.dump({**metrics, 'updated_at': datetime.now().isoformat()}, f, indent=2)
    print(f"Baseline atualizado em: {baseline_path}")

def check_regression(metric_name: str, baseline_val: float, current_val: float) -> str:
    """Retorna 'ok', 'alerta' ou 'bloqueante'."""
    if baseline_val == 0:
        return 'ok'
    
    delta = (current_val - baseline_val) / baseline_val
    
    if delta > BLOCK_THRESHOLD:
        return 'bloqueante'
    elif delta > ALERT_THRESHOLD:
        return 'alerta'
    return 'ok'

def main():
    current_metrics_path = sys.argv[1] if len(sys.argv) > 1 else 'current-metrics.json'
    baseline_path = sys.argv[2] if len(sys.argv) > 2 else 'docs/quality/performance-baseline.json'
    
    with open(current_metrics_path) as f:
        current = json.load(f)
    
    baseline = load_baseline(baseline_path)
    
    if baseline is None:
        save_baseline(baseline_path, current)
        print("Baseline inicial salvo. Nenhuma regressão a verificar.")
        sys.exit(0)
    
    results = []
    has_bloqueante = False
    has_alerta = False
    
    # Checar métricas configuradas
    metrics_to_check = {
        'lighthouse_performance': 'inverse',  # Menor = pior (inverter)
        'lcp_ms': 'normal',
        'tbt_ms': 'normal',
        'api_p95_ms': 'normal',
        'api_error_rate': 'normal',
        'ios_cold_start_ms': 'normal',
        'ios_memory_peak_mb': 'normal',
    }
    
    for metric, direction in metrics_to_check.items():
        if metric not in current or metric not in baseline:
            continue
        
        current_val = current[metric]
        baseline_val = baseline[metric]
        
        # Para scores invertidos (maior é melhor), inverter a lógica
        if direction == 'inverse':
            status = check_regression(metric, current_val, baseline_val)
            # Inverter: se baseline era 90 e agora é 80, é regressão
            delta_pct = (baseline_val - current_val) / baseline_val * 100
        else:
            status = check_regression(metric, baseline_val, current_val)
            delta_pct = (current_val - baseline_val) / baseline_val * 100
        
        result = {
            'metric': metric,
            'baseline': baseline_val,
            'current': current_val,
            'delta_pct': round(delta_pct, 1),
            'status': status,
        }
        results.append(result)
        
        if status == 'bloqueante':
            has_bloqueante = True
        elif status == 'alerta':
            has_alerta = True
    
    # Imprimir relatório
    print("\n" + "="*60)
    print("RELATÓRIO DE REGRESSÃO DE PERFORMANCE")
    print("="*60)
    
    for r in results:
        symbol = {'ok': '✓', 'alerta': '⚠', 'bloqueante': '✗'}[r['status']]
        sign = '+' if r['delta_pct'] > 0 else ''
        print(f"{symbol} {r['metric']:35} {sign}{r['delta_pct']:+.1f}% ({r['baseline']} → {r['current']})")
    
    print("="*60)
    
    if has_bloqueante:
        print("✗ BLOQUEANTE: Regressão > 25% detectada. Build bloqueado.")
        sys.exit(1)
    elif has_alerta:
        print("⚠ ALERTA: Regressão > 10% detectada. Verificar antes do release.")
        # Não bloqueia, mas o CI pode configurar para notificar
        sys.exit(0)
    else:
        print("✓ Nenhuma regressão detectada.")
        sys.exit(0)

if __name__ == '__main__':
    main()
```

---

## GitHub Actions — Workflow Completo de Performance

```yaml
# .github/workflows/performance-monitoring.yml
name: Performance Monitoring

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 5 * * *'  # Diariamente às 5h UTC

jobs:
  lighthouse-monitoring:
    name: Lighthouse Performance Monitor
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install tools
        run: npm install -g lighthouse serve
      
      - name: Serve website
        run: |
          serve website -p 8080 &
          sleep 5
      
      - name: Run Lighthouse
        run: |
          lighthouse http://localhost:8080 \
            --output=json \
            --output-path=lh-result \
            --chrome-flags="--headless --no-sandbox" \
            --quiet
          
          # Extrair métricas relevantes
          python3 -c "
          import json
          with open('lh-result.report.json') as f:
              data = json.load(f)
          
          cats = data['categories']
          audits = data['audits']
          
          metrics = {
              'lighthouse_performance': int(cats['performance']['score'] * 100),
              'lighthouse_accessibility': int(cats['accessibility']['score'] * 100),
              'lighthouse_seo': int(cats['seo']['score'] * 100),
              'lcp_ms': audits['largest-contentful-paint']['numericValue'],
              'tbt_ms': audits['total-blocking-time']['numericValue'],
              'cls': audits['cumulative-layout-shift']['numericValue'],
              'fcp_ms': audits['first-contentful-paint']['numericValue'],
          }
          
          with open('current-metrics.json', 'w') as f:
              json.dump(metrics, f, indent=2)
          
          print(json.dumps(metrics, indent=2))
          "
      
      - name: Download Baseline
        uses: actions/download-artifact@v4
        continue-on-error: true
        with:
          name: performance-baseline
          path: docs/quality/
      
      - name: Check Regression
        run: python3 scripts/qa/check-performance-regression.py current-metrics.json docs/quality/performance-baseline.json
      
      - name: Save New Baseline (only on main branch)
        if: github.ref == 'refs/heads/main'
        run: cp current-metrics.json docs/quality/performance-baseline.json
      
      - name: Upload Baseline
        if: github.ref == 'refs/heads/main'
        uses: actions/upload-artifact@v4
        with:
          name: performance-baseline
          path: docs/quality/performance-baseline.json
          overwrite: true
      
      - name: Notify Slack on Alert
        if: failure()
        uses: slackapi/slack-github-action@v1.26.0
        with:
          channel-id: 'C_PERFORMANCE_ALERTS'
          slack-message: |
            :warning: *Regressão de Performance Detectada — Lexend Scholar*
            Branch: `${{ github.ref_name }}`
            Commit: `${{ github.sha }}`
            Workflow: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
        env:
          SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}

  api-performance-monitoring:
    name: API Load Test Monitor
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Install k6
        run: |
          sudo apt-get install -y gnupg
          sudo gpg --no-default-keyring \
            --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
            --keyserver hkp://keyserver.ubuntu.com:80 \
            --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
          echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] \
            https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
          sudo apt-get update && sudo apt-get install -y k6
      
      - name: Run Load Test (reduced VUs for monitoring)
        env:
          API_URL: ${{ secrets.STAGING_API_URL }}
        run: |
          k6 run \
            --vus 50 \
            --duration 2m \
            --summary-export k6-summary.json \
            scripts/qa/load-test-api.js
      
      - name: Upload k6 Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: k6-performance-results-${{ github.run_number }}
          path: |
            k6-summary.json
            docs/quality/load-test-results.json
```

---

## Dashboard de Trends (Histórico)

```
docs/quality/
└── performance-history/
    ├── 2026-04-07.json
    ├── 2026-04-08.json
    ├── 2026-04-09.json
    └── performance-baseline.json
```

### Script para Gerar Gráfico de Trend

```bash
#!/bin/bash
# scripts/qa/generate-performance-trend.sh

echo "Gerando trend de performance..."

python3 -c "
import json, glob, os
from datetime import datetime

files = sorted(glob.glob('docs/quality/performance-history/*.json'))
trend = []

for f in files[-30:]:  # Últimos 30 dias
    with open(f) as fp:
        data = json.load(fp)
    trend.append({
        'date': os.path.basename(f).replace('.json', ''),
        'lighthouse_performance': data.get('lighthouse_performance', 0),
        'api_p95_ms': data.get('api_p95_ms', 0),
        'ios_cold_start_ms': data.get('ios_cold_start_ms', 0),
    })

print('Data                 | Lighthouse | API p95 | iOS Cold Start')
print('-' * 60)
for t in trend:
    print(f\"{t['date']} | {t['lighthouse_performance']:>10} | {t['api_p95_ms']:>7}ms | {t['ios_cold_start_ms']:>14}ms\")
"
```

---

## Alertas no Slack

### Formato da Mensagem de Alerta

```
⚠️ Regressão de Performance — Lexend Scholar

📊 Métricas afetadas:
• Lighthouse Performance: 87 → 78 (-10.3%) ⚠️
• LCP: 1.8s → 2.4s (+33.3%) 🚨

📋 Detalhes:
• Branch: feature/nova-landing
• Commit: abc1234 — "feat: adicionar seção de depoimentos"
• Autor: João Silva

🔗 Ver build: [Link para GitHub Actions]

Próximos passos:
1. Verificar imagens adicionadas (sem otimização?)
2. Verificar scripts novos sem defer
3. Rodar Lighthouse localmente: npm run lighthouse
```

---

## Referências

- [GitHub Actions — Performance Testing](https://docs.github.com/en/actions/automating-builds-and-tests)
- [k6 — Continuous Performance Testing](https://grafana.com/docs/k6/latest/misc/integrations/)
- [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci)
- [Load Test — LS-162](./LS-162-load-test-api.md)
- [Baseline iOS — LS-158](./LS-158-baseline-performance-ios.md)
- [Lighthouse — LS-160](./LS-160-lighthouse-audit.md)
