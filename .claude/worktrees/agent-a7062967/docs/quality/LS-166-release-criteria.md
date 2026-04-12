# LS-166 — Critérios de Release por Plataforma (iOS + Web)

## Visão Geral

Este documento define os critérios obrigatórios que devem ser atendidos antes de
qualquer release do Lexend Scholar nas plataformas iOS e Web. Nenhuma versão pode
ser promovida para produção sem que todos os gates estejam verdes.

---

## Release Gates — iOS (App Store)

### Gate 1: Qualidade de Código

| Critério | Meta | Ferramenta | Bloqueante |
|----------|------|-----------|-----------|
| Cobertura de testes unitários | ≥ 80% | XCTest + Xcode Coverage | Sim |
| Zero warnings de compilação | 0 warnings | Xcode Build | Sim |
| SwiftLint violations críticas | 0 | SwiftLint | Sim |
| SwiftLint violations de aviso | ≤ 10 | SwiftLint | Não |

### Gate 2: Estabilidade

| Critério | Meta | Ferramenta | Bloqueante |
|----------|------|-----------|-----------|
| Crash-free rate | ≥ 99,5% | Firebase Crashlytics | Sim |
| Crash rate em testes de fumaça | 0 crashes | Manual | Sim |
| ANR (App Not Responding) | 0 | Instruments | Sim |
| Memory leak em fluxos críticos | 0 | Instruments Leak | Sim |

### Gate 3: Performance (Baseline — LS-158)

| Critério | Meta | Ferramenta | Bloqueante |
|----------|------|-----------|-----------|
| Cold start time | ≤ 2,0 segundos | XCTest measure | Sim |
| Warm start time | ≤ 0,8 segundos | XCTest measure | Não |
| Uso de memória (navegação normal) | ≤ 150 MB | Instruments | Não |
| Uso de memória (pico) | ≤ 250 MB | Instruments | Sim |
| Frame rate durante scroll | ≥ 55 fps | Core Animation | Não |

### Gate 4: Bugs por Severidade

| Severidade | Critério | Bloqueante |
|-----------|----------|-----------|
| P0 — Bloqueador total (app crashar, dados perdidos) | Zero abertos | Sim |
| P1 — Crítico (funcionalidade principal quebrada) | Zero abertos | Sim |
| P2 — Alto (funcionalidade degradada com workaround) | ≤ 2 abertos | Sim |
| P3 — Médio (problema menor, não impacta fluxo principal) | ≤ 5 abertos | Não |
| P4 — Baixo (cosmético, melhoria) | Sem limite | Não |

### Gate 5: Aprovação Manual

| Critério | Responsável | Bloqueante |
|----------|-------------|-----------|
| Smoke test manual executado (LS-171) | QA Lead | Sim |
| Product Owner aprovou as features do release | PO | Sim |
| Review de segurança (dados de alunos) | Tech Lead | Sim |
| App Store Connect metadata atualizado | Marketing | Sim (novo major) |

---

## Release Gates — Web (Website + Webapp)

### Gate 1: Lighthouse Score

| Página | Performance | Accessibility | Best Practices | SEO | Bloqueante |
|--------|-------------|--------------|----------------|-----|-----------|
| Home | ≥ 90 | ≥ 90 | ≥ 90 | ≥ 90 | Sim |
| Pricing | ≥ 85 | ≥ 90 | ≥ 90 | ≥ 90 | Não |
| About | ≥ 85 | ≥ 90 | ≥ 90 | ≥ 85 | Não |
| Blog | ≥ 80 | ≥ 90 | ≥ 90 | ≥ 90 | Não |
| Contact | ≥ 90 | ≥ 90 | ≥ 90 | ≥ 85 | Não |

### Gate 2: Acessibilidade (LS-168)

| Critério | Meta | Ferramenta | Bloqueante |
|----------|------|-----------|-----------|
| Violations WCAG 2.1 Level A | Zero | axe-core | Sim |
| Violations WCAG 2.1 Level AA | Zero | axe-core | Sim |
| Navegação por teclado | Funcional em todos os fluxos | Manual | Sim |
| Contraste de cor | ≥ 4.5:1 (texto normal) | axe-core | Sim |

### Gate 3: Qualidade de Código Web

| Critério | Meta | Ferramenta | Bloqueante |
|----------|------|-----------|-----------|
| Links quebrados | Zero | linkchecker | Sim |
| HTML válido (W3C) | Zero erros críticos | W3C Validator | Não |
| Imagens sem atributo alt | Zero | axe-core | Sim |
| Console errors no browser | Zero erros | DevTools | Sim |

### Gate 4: Load Test (LS-162)

| Critério | Meta | Ferramenta | Bloqueante |
|----------|------|-----------|-----------|
| p95 latência — 100 usuários simultâneos | ≤ 500ms | k6 | Sim |
| Taxa de erro sob carga | ≤ 1% | k6 | Sim |
| Throughput mínimo | ≥ 50 req/s | k6 | Não |

---

## Processo de Release

### Fluxo de Aprovação

```
Feature Branch → PR Review → Merge main → CI/CD Pipeline
                                              ↓
                                    [Todos os gates automatizados]
                                              ↓
                                    ✓ Gate 1: Testes e cobertura
                                    ✓ Gate 2: Performance baseline
                                    ✓ Gate 3: Lighthouse (web)
                                    ✓ Gate 4: Load test (API)
                                              ↓
                                    [Smoke test manual — QA]
                                              ↓
                                    [Aprovação PO]
                                              ↓
                                    Deploy para Produção / Submit App Store
```

### Responsabilidades

| Papel | Responsabilidade |
|-------|-----------------|
| Engenheiro | Garantir gates 1, 2, 3 antes do PR |
| QA Lead | Executar smoke test e gates de acessibilidade |
| Tech Lead | Gate de segurança e revisão de dados de alunos |
| Product Owner | Aprovação final de feature e UX |
| DevOps | Garantir que CI/CD execute todos os gates automáticos |
| Marketing | Atualizar metadata de store antes do release |

### Ciclo de Release

| Tipo | Frequência | Aprovação necessária |
|------|-----------|---------------------|
| Patch (bug fix) | Semanal ou sob demanda | QA + Tech Lead |
| Minor (nova feature) | Quinzenal (a cada sprint) | QA + Tech Lead + PO |
| Major (breaking change) | Trimestral | Todos + Diretoria |

---

## Exceções e Rollback

### Quando Abrir Exceção

Um gate pode ser temporariamente ignorado se:
1. Existe workaround documentado para o usuário
2. Tech Lead e PO aprovam por escrito (Linear comment)
3. Bug fix já está planejado para a próxima release

**Exceções devem ser documentadas no Linear com:**
- Justificativa
- Issue de follow-up criada
- Aprovação explícita de Tech Lead e PO

### Plano de Rollback

| Plataforma | Mecanismo de Rollback | Tempo estimado |
|-----------|----------------------|----------------|
| iOS | Retornar versão anterior via App Store Connect (Phased Release) | 1–2h |
| Web (Vercel) | `vercel rollback [deployment-id]` | < 5 minutos |
| API | Feature flag desabilitada via configuração | < 1 minuto |

---

## Histórico de Releases

| Versão | Data | iOS | Web | Status |
|--------|------|-----|-----|--------|
| 1.0.0 | — | — | — | Planejada |

---

## Referências

- [Performance Baseline iOS — LS-158](./LS-158-baseline-performance-ios.md)
- [Load Test API — LS-162](./LS-162-load-test-api.md)
- [Lighthouse — LS-160](./LS-160-lighthouse-audit.md)
- [Acessibilidade — LS-168](./LS-168-acessibilidade-wcag.md)
- [Smoke Test — LS-171](./LS-171-checklist-validacao-manual.md)
- [Coverage — LS-167](./LS-167-cobertura-automatica.md)
