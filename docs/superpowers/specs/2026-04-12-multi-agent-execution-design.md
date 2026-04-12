# Design: Execução Multi-Agente — Lexend Scholar

**Data:** 2026-04-12  
**Status:** Aprovado  
**Abordagem escolhida:** B — Por domínio (5-6 agentes)

---

## Contexto

O projeto Lexend Scholar tem 50 issues no Linear (todos em Backlog), distribuídos em 15 epics, cobrindo iOS, Android, Web, Billing, Growth, Legal, Quality e mais. A metodologia MSS define 15 times com responsabilidades, dependências e milestones. O objetivo é executar todo o backlog em paralelo usando múltiplos agentes Claude Code, cada um responsável por um domínio.

---

## Arquitetura de Orquestração

Cada agente roda como subagente Claude Code com worktree isolado, em uma branch git própria. O progresso é rastreado no Linear — cada agente atualiza o status dos seus issues de Backlog → In Progress → Done.

```
Orquestrador (você)
  ├── Agent: iOS/Android       → branch feat/ios-android
  ├── Agent: Store & Quality   → branch feat/store-quality
  ├── Agent: Web/Infra         → branch feat/web-infra
  ├── Agent: Growth/Sales      → branch feat/growth-sales
  └── Agent: Legal/Ops         → branch feat/legal-ops
```

---

## Divisão de Domínios

| Agente | Epics | Issues | Tipo de entrega |
|--------|-------|--------|-----------------|
| iOS/Android | Android App Core, Android Tablet Optimization | LS-152..LS-159 (7 issues) | Código Swift/Kotlin |
| Store & Quality | App Store Optimization, Play Store Readiness, Quality Gates | LS-166..LS-178 (12 issues) | Configs, checklists, scripts |
| Web/Infra | Billing System Stripe, Google Ecosystem, Relatórios e Analytics, Pricing e Planos | LS-137..LS-145, LS-161..LS-165, LS-180, LS-189 (13 issues) | Código web, configs de integração |
| Growth/Sales | Growth e Aquisição, Sales Infrastructure CRM, Documentation Hub | LS-141, LS-146..LS-148, LS-179..LS-183, LS-186 (8 issues) | Documentos markdown, templates |
| Legal/Ops | IP e Contratos, Budget e Planejamento | LS-149..LS-151, LS-181..LS-185 (6 issues) | Documentos markdown, templates |
| Spillover | Issues sem projeto | LS-158, LS-160, LS-163, LS-164 (4 issues) | A definir por issue |

---

## Briefing Padrão dos Agentes

Cada agente recebe:

```
Você é o agente [DOMÍNIO] do projeto Lexend Scholar.

Seu escopo são os seguintes issues do Linear:
- LS-XXX: [título]
...

Para cada issue:
1. Leia o issue no Linear via API para pegar a descrição completa
2. Execute o trabalho (código, documento, configuração, pesquisa)
3. Atualize o status no Linear: Backlog → In Progress → Done
4. Faça commit referenciando o identifier (ex: "feat: LS-138 setup Stripe billing")

Contexto do projeto:
- Stack iOS: SwiftUI, iOS 18, Swift 6
- Stack Web: HTML/Tailwind CDN
- Linear API: https://api.linear.app/graphql
- Trabalhe em ordem de prioridade (priority 1=urgente, 4=baixo)
- Não toque em arquivos fora do seu domínio
```

Agentes de Growth/Sales e Legal/Ops entregam documentos markdown em docs/<domínio>/, não código.

---

## Dependências e Ordem de Merge

```
1. Legal/Ops          → sem dependência de código, merge primeiro
2. Growth/Sales       → sem dependência de código
3. iOS/Android        → independente de Web/Infra
4. Web/Infra          → independente na prática (sem APIs compartilhadas com iOS)
5. Store & Quality    → merge após iOS/Android estável
```

Agentes 1-4 podem rodar e fazer merge em qualquer ordem entre si. O agente Store & Quality deve aguardar iOS/Android para validar build e qualidade.

---

## Critérios de Aceite

Por agente:
- Todos os issues do seu domínio marcados como Done no Linear
- Um commit por issue, com o identifier no título (ex: feat: LS-138 ...)
- Sem conflitos de merge com main
- Agentes de código: arquivos compilam sem erros
- Agentes de docs: documentos em docs/<domínio>/ com conteúdo real (sem placeholders)

---

## Stack de Referência

- iOS: Swift 6, SwiftUI, iOS 18+, XcodeGen (project.yml)
- Web/Website: HTML, Tailwind CDN (migrar para build local é parte do backlog)
- Banco: database_schema.sql na raiz
- Linear API: GraphQL em https://api.linear.app/graphql
- Repo: branch main como base, worktree por agente
