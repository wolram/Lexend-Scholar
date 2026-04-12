#!/usr/bin/env python3
"""
LS-164 — Verificação de Regressão de Performance
Uso: python3 scripts/qa/check-performance-regression.py [current-metrics.json] [baseline.json]

Codes de saída:
  0 — OK (nenhuma regressão)
  1 — BLOQUEANTE (regressão > 25%)
  2 — ALERTA (regressão > 10%, não bloqueante)
"""

import json
import sys
import os
from datetime import datetime

ALERT_THRESHOLD = 0.10    # +10% → alerta
BLOCK_THRESHOLD = 0.25    # +25% → bloqueante


def load_json(path: str) -> dict | None:
    if not os.path.exists(path):
        return None
    with open(path) as f:
        return json.load(f)


def save_json(path: str, data: dict):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    with open(path, 'w') as f:
        json.dump({**data, 'updated_at': datetime.now().isoformat()}, f, indent=2)


def check_regression(baseline_val: float, current_val: float, inverse: bool = False) -> tuple[str, float]:
    """
    Retorna (status, delta_pct).
    inverse=True: menor é melhor (ex: scores Lighthouse).
    inverse=False: menor é pior (ex: latências, uso de memória).
    """
    if baseline_val == 0:
        return 'ok', 0.0

    if inverse:
        # Score: baseline 90, current 80 → regressão de 11%
        delta = (baseline_val - current_val) / baseline_val
    else:
        # Latência: baseline 300ms, current 400ms → regressão de 33%
        delta = (current_val - baseline_val) / baseline_val

    if delta > BLOCK_THRESHOLD:
        return 'bloqueante', round(delta * 100, 1)
    elif delta > ALERT_THRESHOLD:
        return 'alerta', round(delta * 100, 1)
    return 'ok', round(delta * 100, 1)


# Definição das métricas e se menor é melhor (inverse=True) ou pior (inverse=False)
METRICS_CONFIG = {
    # Lighthouse (maior é melhor → inverse=True quando decresce)
    'lighthouse_performance':   {'label': 'Lighthouse Performance', 'unit': '', 'inverse': True},
    'lighthouse_accessibility': {'label': 'Lighthouse Accessibility', 'unit': '', 'inverse': True},
    'lighthouse_seo':           {'label': 'Lighthouse SEO', 'unit': '', 'inverse': True},
    # Core Web Vitals (menor é melhor → inverse=False, queremos detectar aumento)
    'lcp_ms':                   {'label': 'LCP', 'unit': 'ms', 'inverse': False},
    'tbt_ms':                   {'label': 'TBT', 'unit': 'ms', 'inverse': False},
    'cls':                      {'label': 'CLS', 'unit': '', 'inverse': False},
    # API (menor é melhor)
    'api_p95_ms':               {'label': 'API p95', 'unit': 'ms', 'inverse': False},
    'api_error_rate':           {'label': 'API Taxa de Erro', 'unit': '%', 'inverse': False},
    # iOS (menor é melhor)
    'ios_cold_start_ms':        {'label': 'iOS Cold Start', 'unit': 'ms', 'inverse': False},
    'ios_warm_start_ms':        {'label': 'iOS Warm Start', 'unit': 'ms', 'inverse': False},
    'ios_memory_idle_mb':       {'label': 'iOS Memória Idle', 'unit': 'MB', 'inverse': False},
    'ios_memory_peak_mb':       {'label': 'iOS Memória Pico', 'unit': 'MB', 'inverse': False},
}


def main():
    current_path = sys.argv[1] if len(sys.argv) > 1 else 'current-metrics.json'
    baseline_path = sys.argv[2] if len(sys.argv) > 2 else 'docs/quality/performance-baseline.json'

    current = load_json(current_path)
    if current is None:
        print(f"ERRO: Arquivo de métricas atuais não encontrado: {current_path}")
        sys.exit(1)

    baseline = load_json(baseline_path)
    if baseline is None:
        print(f"Baseline não encontrado em: {baseline_path}")
        print("Primeira execução — salvando como baseline inicial.")
        save_json(baseline_path, current)
        print(f"✓ Baseline salvo em: {baseline_path}")
        sys.exit(0)

    results = []
    has_bloqueante = False
    has_alerta = False

    for key, config in METRICS_CONFIG.items():
        if key not in current or key not in baseline:
            continue

        curr_val = float(current[key])
        base_val = float(baseline[key])
        status, delta_pct = check_regression(base_val, curr_val, inverse=config['inverse'])

        results.append({
            'key': key,
            'label': config['label'],
            'unit': config['unit'],
            'baseline': base_val,
            'current': curr_val,
            'delta_pct': delta_pct,
            'status': status,
        })

        if status == 'bloqueante':
            has_bloqueante = True
        elif status == 'alerta':
            has_alerta = True

    # Imprimir relatório
    print()
    print('=' * 68)
    print('RELATÓRIO DE REGRESSÃO DE PERFORMANCE — LEXEND SCHOLAR')
    print('=' * 68)

    symbols = {'ok': '✓', 'alerta': '⚠', 'bloqueante': '✗'}
    labels_status = {'ok': 'OK', 'alerta': 'ALERTA', 'bloqueante': 'BLOQUEANTE'}

    for r in results:
        sym = symbols[r['status']]
        sign = '+' if r['delta_pct'] > 0 else ''
        unit = r['unit']
        baseline_str = f"{r['baseline']}{unit}"
        current_str = f"{r['current']}{unit}"
        delta_str = f"{sign}{r['delta_pct']:.1f}%"
        label_status = labels_status[r['status']]
        print(f"  {sym} {r['label']:<32} {delta_str:>7}  ({baseline_str} → {current_str})  [{label_status}]")

    print('=' * 68)

    if has_bloqueante:
        print()
        print('✗ RESULTADO: BLOQUEANTE')
        print('  Regressão > 25% detectada. Build bloqueado.')
        print('  Investigue o commit que introduziu a regressão.')
        print(f'  Consulte: docs/quality/LS-164-monitoring-performance-ci.md')
        sys.exit(1)
    elif has_alerta:
        print()
        print('⚠ RESULTADO: ALERTA')
        print('  Regressão > 10% detectada. Verificar antes do próximo release.')
        print(f'  Consulte: docs/quality/LS-164-monitoring-performance-ci.md')
        sys.exit(0)  # Alerta não bloqueia o build
    else:
        print()
        print('✓ RESULTADO: OK — Nenhuma regressão de performance detectada.')
        sys.exit(0)


if __name__ == '__main__':
    main()
