# Critérios de Release por Plataforma

> Issue: LS-166 | Definir critérios de release por plataforma (iOS + web)

---

## iOS

| Gate | Critério | Responsável | Ferramenta | Critério de Bloqueio |
|------|---------|-------------|-----------|---------------------|
| Cobertura de testes | > 80% de cobertura de linhas (XCTest) | Tech Lead | `xccov` / `scripts/qa/check-coverage-ios.sh` | Cobertura < 80% bloqueia merge para main |
| Crashes P0/P1 | Zero crashes críticos nos últimos 7 dias | QA Engineer | Firebase Crashlytics | Qualquer crash P0 ou P1 aberto bloqueia release |
| Cold start | < 1.5s em iPhone SE (device mais lento suportado) | iOS Dev | Instruments → App Launch | > 1.5s bloqueia release |
| Aprovação manual | 2 approvals: tech lead + product owner | Tech Lead + PO | GitHub Pull Request | Sem 2 approvals, não faz merge |
| TestFlight beta | Mínimo 5 testers por 3 dias corridos sem crash P0 | QA Engineer | TestFlight + Crashlytics | Beta com < 3 dias ou crash P0 bloqueia |
| Checklist pré-release | 100% dos itens obrigatórios do checklist concluídos | QA Engineer | `docs/quality/checklist-pre-release.md` | Qualquer item obrigatório incompleto bloqueia |

### Classificação de Severidade (iOS)
| Nível | Definição |
|-------|-----------|
| P0 | App crasha na inicialização, perda de dados, falha em funcionalidade core sem workaround |
| P1 | Funcionalidade core com bug sem workaround (ex: não consegue registrar frequência) |
| P2 | Bug com workaround disponível ou funcionalidade secundária |
| P3 | Cosmético, nitpick de UI |

---

## Web / Website

| Gate | Critério | Responsável | Ferramenta | Critério de Bloqueio |
|------|---------|-------------|-----------|---------------------|
| Lighthouse Performance | Score ≥ 90 | Frontend Dev | Lighthouse CLI / `scripts/qa/run-lighthouse.sh` | Score < 90 bloqueia deploy |
| Lighthouse Accessibility | Score ≥ 90 | Frontend Dev | Lighthouse CLI | Score < 90 bloqueia deploy |
| Lighthouse Best Practices | Score ≥ 90 | Frontend Dev | Lighthouse CLI | Score < 90 bloqueia deploy |
| Lighthouse SEO | Score ≥ 90 | Frontend Dev | Lighthouse CLI | Score < 90 bloqueia deploy |
| WCAG 2.1 AA | Zero violations de nível A e AA | QA / Frontend | axe-core / `scripts/qa/run-accessibility-audit.sh` | Qualquer violation nível A bloqueia; nível AA gera alerta |
| Load test | 100 usuários simultâneos sem erro 5xx | Backend Dev | k6 / `scripts/qa/load-test-api.js` | Taxa de erro > 1% ou qualquer 5xx bloqueia |
| Segurança OWASP | Zero vulnerabilidades XSS e SQL Injection | Backend Dev | OWASP ZAP / checklist manual | Qualquer vuln. de nível High ou Critical bloqueia |
| Regressão de performance | Sem regressão > 25% vs. baseline | Frontend Dev | `scripts/qa/check-performance-regression.py` | Regressão > 25% bloqueia; > 10% gera alerta |

---

## Processo Go/No-Go

### Gates Sequenciais (todos devem passar)

```
[1] Testes automatizados passam no CI
    └── iOS: XCTest + cobertura > 80%
    └── Web: Lighthouse + axe-core

[2] Revisão de código (2 approvals no PR)

[3] QA Manual (checklist-pre-release.md)

[4] Beta / TestFlight / Play Beta
    └── iOS: 5 testers × 3 dias sem crash P0
    └── Android: Internal Testing sem crash P0

[5] Reunião Go/No-Go (15 min)
    └── Tech Lead apresenta métricas
    └── Product Owner aprova
    └── Decisão registrada no Linear

[6] Deploy / Submit para revisão
```

### Reunião Go/No-Go — Agenda (15 min)
1. Tech Lead apresenta dashboard de métricas (Crashlytics, Lighthouse, cobertura)
2. QA apresenta resultado do checklist manual
3. PO valida critérios de negócio
4. Decisão: Go / No-Go com justificativa registrada no Linear
5. Se No-Go: abrir issues para cada critério não atendido com prazo de correção

---

## Ambiente de Release

| Ambiente | URL / Bundle ID | Branch | Deploy |
|----------|----------------|--------|--------|
| Development | localhost / com.lexendscholar.dev | feature/* | Manual |
| Staging | staging.lexendscholar.com.br | main | Automático via CI |
| Production | lexendscholar.com.br / com.lexendscholar | tag v*.*.* | Manual após Go/No-Go |
