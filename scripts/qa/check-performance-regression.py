#!/usr/bin/env python3
"""
check-performance-regression.py
Compara scores Lighthouse atuais com o baseline e alerta/bloqueia em caso de regressão.

Uso:
  python3 scripts/qa/check-performance-regression.py [current_report.json]

Exit codes:
  0 — OK ou apenas alertas (regressão 10-25%)
  1 — BLOQUEADO (regressão > 25%)
"""

import json
import sys
import os
import shutil
from datetime import datetime

ALERT_THRESHOLD = 0.10   # 10% de regressão = alerta (aviso mas não bloqueia)
BLOCK_THRESHOLD = 0.25   # 25% de regressão = bloqueia CI


def load_scores(path):
    """Carrega scores de categoria de um relatório Lighthouse JSON."""
    with open(path) as f:
        data = json.load(f)

    categories = data.get('categories', {})
    return {
        'performance': categories.get('performance', {}).get('score', 0) * 100,
        'accessibility': categories.get('accessibility', {}).get('score', 0) * 100,
        'best-practices': categories.get('best-practices', {}).get('score', 0) * 100,
        'seo': categories.get('seo', {}).get('score', 0) * 100,
    }


def load_key_metrics(path):
    """Carrega métricas individuais (LCP, TBT, CLS) do relatório Lighthouse."""
    with open(path) as f:
        data = json.load(f)

    audits = data.get('audits', {})
    return {
        'lcp': audits.get('largest-contentful-paint', {}).get('numericValue', 0) / 1000,
        'tbt': audits.get('total-blocking-time', {}).get('numericValue', 0),
        'cls': audits.get('cumulative-layout-shift', {}).get('numericValue', 0),
        'fcp': audits.get('first-contentful-paint', {}).get('numericValue', 0) / 1000,
        'si': audits.get('speed-index', {}).get('numericValue', 0) / 1000,
    }


def format_metric(value, unit=''):
    if unit == 's':
        return f'{value:.2f}s'
    elif unit == 'ms':
        return f'{value:.0f}ms'
    else:
        return f'{value:.1f}'


def main():
    baseline_path = 'docs/quality/lighthouse-baseline.json'
    current_path = sys.argv[1] if len(sys.argv) > 1 else 'docs/quality/lighthouse-index.json'

    print('=' * 60)
    print('Lexend Scholar — Performance Regression Check')
    print(f'Data: {datetime.now().strftime("%Y-%m-%d %H:%M")}')
    print('=' * 60)

    # Verificar se o arquivo atual existe
    if not os.path.exists(current_path):
        print(f'ERRO: Arquivo de relatório não encontrado: {current_path}')
        print('Execute run-lighthouse.sh primeiro.')
        sys.exit(1)

    # Se não há baseline, criar com o relatório atual
    if not os.path.exists(baseline_path):
        print(f'Baseline não encontrado em {baseline_path}.')
        print('Criando baseline com os scores atuais...')
        os.makedirs(os.path.dirname(baseline_path), exist_ok=True)
        shutil.copy(current_path, baseline_path)
        print(f'Baseline criado: {baseline_path}')
        print('Rode novamente após a próxima auditoria para comparar.')
        sys.exit(0)

    # Carregar scores
    baseline = load_scores(baseline_path)
    current = load_scores(current_path)

    # Carregar métricas individuais (best-effort)
    try:
        baseline_metrics = load_key_metrics(baseline_path)
        current_metrics = load_key_metrics(current_path)
        has_metrics = True
    except Exception:
        has_metrics = False

    print('\n── Scores de Categoria ──────────────────────────────────')
    print(f'{"Categoria":<20} {"Baseline":>10} {"Atual":>10} {"Variação":>10} {"Status":>10}')
    print('-' * 62)

    exit_code = 0

    for metric, base_score in baseline.items():
        curr_score = current.get(metric, 0)
        regression = (base_score - curr_score) / base_score if base_score > 0 else 0
        variation = curr_score - base_score

        variation_str = f'+{variation:.1f}' if variation >= 0 else f'{variation:.1f}'

        if regression > BLOCK_THRESHOLD:
            status = 'BLOQUEADO'
            exit_code = 1
        elif regression > ALERT_THRESHOLD:
            status = 'ALERTA'
        elif curr_score >= base_score:
            status = 'OK'
        else:
            status = 'OK (-)'

        print(f'{metric:<20} {base_score:>10.1f} {curr_score:>10.1f} {variation_str:>10} {status:>10}')

    if has_metrics:
        print('\n── Métricas de Performance ──────────────────────────────')
        print(f'{"Métrica":<20} {"Baseline":>12} {"Atual":>12} {"Meta":>10}')
        print('-' * 56)

        metrics_display = [
            ('LCP', 'lcp', 's', '≤ 1.8s'),
            ('TBT', 'tbt', 'ms', '≤ 200ms'),
            ('CLS', 'cls', '', '≤ 0.10'),
            ('FCP', 'fcp', 's', '≤ 1.2s'),
            ('Speed Index', 'si', 's', '≤ 2.0s'),
        ]

        for name, key, unit, target in metrics_display:
            base_val = baseline_metrics.get(key, 0)
            curr_val = current_metrics.get(key, 0)
            base_str = format_metric(base_val, unit)
            curr_str = format_metric(curr_val, unit)
            print(f'{name:<20} {base_str:>12} {curr_str:>12} {target:>10}')

    print('\n' + '=' * 60)

    if exit_code == 1:
        print('RESULTADO: BLOQUEADO — regressão crítica detectada (> 25%)')
        print('Correção necessária antes do merge.')
    else:
        # Verificar alertas
        has_alerts = any(
            (base_score - current.get(m, 0)) / base_score > ALERT_THRESHOLD
            for m, base_score in baseline.items()
            if base_score > 0
        )
        if has_alerts:
            print('RESULTADO: ALERTA — regressão moderada detectada (10-25%)')
            print('Investigar antes do próximo deploy em produção.')
        else:
            print('RESULTADO: OK — sem regressões significativas')

    print('=' * 60)
    sys.exit(exit_code)


if __name__ == '__main__':
    main()
