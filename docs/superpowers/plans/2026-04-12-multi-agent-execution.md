# Multi-Agent Execution — Lexend Scholar

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Executar os 50 issues do backlog Lexend Scholar em paralelo usando 5 agentes Claude Code independentes, cada um responsável por um domínio de negócio.

**Architecture:** Cada agente roda em um worktree git isolado (branch própria), lê os detalhes dos seus issues via Linear API, executa o trabalho (código ou documentos) e atualiza o status no Linear. O orquestrador (esta sessão) monitora o progresso e faz merge das branches em ordem de dependência.

**Tech Stack:** Claude Code Agent tool (isolation: worktree), Linear GraphQL API, Swift 6/SwiftUI (iOS), Kotlin/Jetpack Compose (Android), HTML/Tailwind (Web), Markdown (docs)

---

## Mapa de Domínios

| Agente | Branch | Issues |
|--------|--------|--------|
| iOS/Android | feat/ios-android | LS-152, LS-153, LS-154, LS-155, LS-156, LS-157, LS-159 |
| Store & Quality | feat/store-quality | LS-158, LS-160, LS-162, LS-164, LS-166, LS-167, LS-168, LS-169, LS-170, LS-171, LS-172, LS-173, LS-174, LS-175, LS-176, LS-178 |
| Web/Infra | feat/web-infra | LS-137, LS-138, LS-139, LS-140, LS-144, LS-145, LS-161, LS-163, LS-165, LS-177, LS-180, LS-188, LS-189 |
| Growth/Sales | feat/growth-sales | LS-141, LS-146, LS-147, LS-148, LS-179, LS-182, LS-183, LS-186 |
| Legal/Ops | feat/legal-ops | LS-149, LS-150, LS-151, LS-181, LS-184, LS-185 |

---

## Task 1: Verificar estado do repositório

**Files:**
- Read: docs/superpowers/specs/2026-04-12-multi-agent-execution-design.md

- [ ] **Step 1: Confirmar branch main limpa**

```bash
git status
git branch
```

Expected: branch main, nothing to commit.

- [ ] **Step 2: Confirmar os 50 issues no Linear**

```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: lin_api_owdsl43rZHedxr70pC2OXqAmSxR6plRPZpeyVyrU" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ team(id: \"740589b4-a4b2-47e9-9807-7065c4377fa1\") { issues { nodes { identifier state { name } } } } }"}' \
  | python3 -c "
import json,sys
d=json.load(sys.stdin)
issues=d['data']['team']['issues']['nodes']
print(f'Total: {len(issues)}')
from collections import defaultdict
by_state=defaultdict(list)
for i in issues:
    by_state[i['state']['name']].append(i['identifier'])
for s,ids in sorted(by_state.items()):
    print(f'  {s}: {len(ids)}')
"
```

Expected: Total: 50, Backlog: 50.

---

## Task 2: Buscar IDs dos estados do Linear

- [ ] **Step 1: Buscar UUIDs dos estados**

```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: lin_api_owdsl43rZHedxr70pC2OXqAmSxR6plRPZpeyVyrU" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ team(id: \"740589b4-a4b2-47e9-9807-7065c4377fa1\") { states { nodes { id name } } } }"}' \
  | python3 -c "
import json,sys
d=json.load(sys.stdin)
for s in d['data']['team']['states']['nodes']:
    print(f\"{s['name']}: {s['id']}\")
"
```

Expected: lista com Backlog, In Progress, Done e seus UUIDs.

- [ ] **Step 2: Anotar os IDs**

Substitua nos prompts das Tasks 3-7:
- `[STATE_IN_PROGRESS]` → UUID do estado "In Progress"
- `[STATE_DONE]` → UUID do estado "Done"

---

## Task 3: Dispatch — Agente iOS/Android (7 issues)

**Files:**
- Create: android/ (novo diretório)
- Modify: app/ (SwiftUI existente)

- [ ] **Step 1: Disparar agente via Agent tool com isolation: worktree**

Prompt para o agente:

```
Você é o agente iOS/Android do projeto Lexend Scholar.

CONTEXTO DO PROJETO:
- Stack iOS: Swift 6, SwiftUI, iOS 18+, XcodeGen (project.yml na raiz)
- Stack Android: Kotlin, Jetpack Compose
- Pasta iOS existente: app/
- Pasta Android: criar em android/
- Linear API: https://api.linear.app/graphql
- Auth: Authorization: lin_api_owdsl43rZHedxr70pC2OXqAmSxR6plRPZpeyVyrU
- State "In Progress": [STATE_IN_PROGRESS]
- State "Done": [STATE_DONE]

SEUS ISSUES (execute nesta ordem):
- LS-152 (p2): Configurar projeto Android com Kotlin e Jetpack Compose
- LS-153 (p2): Integrar Supabase Android SDK para autenticação
- LS-154 (p2): Implementar módulo acadêmico básico (alunos, frequência, notas)
- LS-155 (p3): Implementar offline support com WorkManager
- LS-156 (p3): Implementar adaptive layouts com WindowSizeClass
- LS-157 (p3): Criar multi-pane layouts para tablet (lista + detalhe)
- LS-159 (p4): Adicionar suporte a foldable devices

PROTOCOLO POR ISSUE:
1. Buscar UUID do issue:
   curl -s -X POST https://api.linear.app/graphql \
     -H "Authorization: lin_api_owdsl43rZHedxr70pC2OXqAmSxR6plRPZpeyVyrU" \
     -H "Content-Type: application/json" \
     -d '{"query": "{ team(id: \"740589b4-a4b2-47e9-9807-7065c4377fa1\") { issues(filter: { identifier: { eq: \"LS-XXX\" } }) { nodes { id title description } } } }"}'

2. Marcar In Progress:
   curl -s -X POST https://api.linear.app/graphql \
     -H "Authorization: lin_api_owdsl43rZHedxr70pC2OXqAmSxR6plRPZpeyVyrU" \
     -H "Content-Type: application/json" \
     -d '{"query": "mutation { issueUpdate(id: \"ISSUE_UUID\", input: { stateId: \"[STATE_IN_PROGRESS]\" }) { success } }"}'

3. Implementar conforme a descrição do issue.

4. Commit:
   git add <arquivos>
   git commit -m "feat: LS-XXX <título>"

5. Marcar Done:
   curl -s -X POST https://api.linear.app/graphql \
     -H "Authorization: lin_api_owdsl43rZHedxr70pC2OXqAmSxR6plRPZpeyVyrU" \
     -H "Content-Type: application/json" \
     -d '{"query": "mutation { issueUpdate(id: \"ISSUE_UUID\", input: { stateId: \"[STATE_DONE]\" }) { success } }"}'

REGRAS:
- Código Android vai em android/
- Código iOS vai em app/
- Docs vão em docs/android/ ou docs/ios/
- Não toque em outros diretórios
- Um commit por issue
```

- [ ] **Step 2: Confirmar que o agente iniciou por LS-152**

---

## Task 4: Dispatch — Agente Store & Quality (16 issues)

**Files:**
- Create: docs/store/, docs/quality/, scripts/qa/

- [ ] **Step 1: Disparar agente via Agent tool com isolation: worktree**

```
Você é o agente Store & Quality do projeto Lexend Scholar.

CONTEXTO DO PROJETO:
- Stack Web: HTML/Tailwind em website/
- Stack iOS: SwiftUI em app/
- Linear API: https://api.linear.app/graphql
- Auth: Authorization: lin_api_owdsl43rZHedxr70pC2OXqAmSxR6plRPZpeyVyrU
- State "In Progress": [STATE_IN_PROGRESS]
- State "Done": [STATE_DONE]

SEUS ISSUES (execute nesta ordem):
App Store Optimization:
- LS-169 (p2): Pesquisar palavras-chave no App Store (categoria Education)
- LS-172 (p2): Escrever título e subtítulo otimizados para App Store
- LS-174 (p2): Criar screenshots otimizados para conversão (iPhone 6.7" + iPad)
- LS-176 (p3): Produzir preview video do app (15-30 segundos)
- LS-178 (p3): Criar estratégia de gestão de avaliações e reviews

Play Store Readiness:
- LS-170 (p2): Criar Play Store listing em português
- LS-173 (p2): Preencher Data Safety section (dados de alunos menores)
- LS-175 (p3): Configurar internal testing track + closed testing

Quality Gates:
- LS-166 (p2): Definir critérios de release por plataforma (iOS + web)
- LS-167 (p2): Implementar verificação automática de cobertura (meta: > 80%)
- LS-168 (p3): Realizar testes de acessibilidade WCAG 2.1 AA no website
- LS-171 (p3): Criar checklist de validação manual pré-release

Performance & QA:
- LS-160 (p2): Executar auditoria Lighthouse no website (meta: score > 90)
- LS-158 (p3): Definir baseline de performance iOS (tempo de abertura, memória)
- LS-162 (p3): Criar load test para API: 100 alunos simultâneos
- LS-164 (p3): Configurar monitoring de performance contínua no CI

PROTOCOLO POR ISSUE: [mesmo da Task 3]

REGRAS:
- Docs de store vão em docs/store/
- Docs de quality vão em docs/quality/
- Scripts de teste vão em scripts/qa/
- Não toque em app/ ou android/
- Para issues com ferramentas externas (Lighthouse, k6), documente comandos e resultados esperados em markdown
- Um commit por issue, conteúdo real sem placeholders
```

---

## Task 5: Dispatch — Agente Web/Infra (13 issues)

**Files:**
- Modify: webapp/, website/
- Create: docs/billing/, docs/web/, sql/

- [ ] **Step 1: Disparar agente via Agent tool com isolation: worktree**

```
Você é o agente Web/Infra do projeto Lexend Scholar.

CONTEXTO DO PROJETO:
- Stack Web: HTML/Tailwind em website/ e webapp/
- Database schema: database_schema.sql na raiz (PostgreSQL/Supabase)
- Linear API: https://api.linear.app/graphql
- Auth: Authorization: lin_api_owdsl43rZHedxr70pC2OXqAmSxR6plRPZpeyVyrU
- State "In Progress": [STATE_IN_PROGRESS]
- State "Done": [STATE_DONE]

SEUS ISSUES (execute nesta ordem):
Billing System Stripe:
- LS-137 (p2): Integrar Stripe Billing para assinaturas recorrentes
- LS-138 (p2): Implementar trial gratuito de 14 dias
- LS-139 (p2): Implementar geração automática de invoice/recibo
- LS-140 (p2): Implementar webhook Stripe para eventos de assinatura

Pricing e Planos:
- LS-144 (p2): Definir modelo de pricing por número de alunos
- LS-145 (p3): Criar proposta comercial e contrato de serviços

Google Ecosystem:
- LS-161 (p2): Configurar push notifications via Firebase Cloud Messaging
- LS-163 (p3): Implementar in-app billing com Play Billing Library 6+
- LS-165 (p4): Criar App Widgets com Glance para resumo escolar

Relatórios e Analytics:
- LS-177 (p2): Implementar relatório de inadimplência financeira
- LS-188 (p2): Implementar geração de boletim escolar em PDF
- LS-189 (p2): Implementar relatório de frequência por aluno, turma e período
- LS-180 (p3): Implementar export de dados XLSX para secretaria

PROTOCOLO POR ISSUE: [mesmo da Task 3]

REGRAS:
- Código de billing/API vai em webapp/
- SQL queries vão em sql/ (referenciando database_schema.sql)
- Docs vão em docs/billing/ ou docs/web/
- Não toque em app/ (iOS) ou android/
- Um commit por issue
```

---

## Task 6: Dispatch — Agente Growth/Sales (8 issues)

**Files:**
- Create: docs/growth/, docs/sales/, docs/adr/

- [ ] **Step 1: Disparar agente via Agent tool com isolation: worktree**

```
Você é o agente Growth/Sales do projeto Lexend Scholar.

CONTEXTO DO PROJETO:
- Produto: SaaS B2B de gestão escolar para escolas privadas brasileiras
- Pricing: Starter (até 100 alunos, R$297/mês), Pro (até 500, R$697/mês), Enterprise (ilimitado, R$1.497/mês)
- Linear API: https://api.linear.app/graphql
- Auth: Authorization: lin_api_owdsl43rZHedxr70pC2OXqAmSxR6plRPZpeyVyrU
- State "In Progress": [STATE_IN_PROGRESS]
- State "Done": [STATE_DONE]

SEUS ISSUES (execute nesta ordem):
Growth e Aquisição:
- LS-179 (p2): Configurar email marketing (ConvertKit ou MailerLite)
- LS-182 (p2): Criar sequência de email onboarding para novas escolas
- LS-183 (p3): Criar campanha Google Ads para software de gestão escolar
- LS-186 (p3): Criar programa de indicação escola-para-escola

Sales Infrastructure CRM:
- LS-146 (p3): Configurar HubSpot CRM gratuito
- LS-147 (p3): Criar script de demo do Lexend Scholar
- LS-148 (p3): Criar deck de vendas do Lexend Scholar

Documentation Hub:
- LS-141 (p3): Criar ADRs para decisões técnicas principais

PROTOCOLO POR ISSUE: [mesmo da Task 3]

REGRAS:
- Emails vão em docs/growth/emails/ (um .md por email)
- ADRs vão em docs/adr/ADR-00N-titulo.md
- Scripts e decks vão em docs/sales/
- Conteúdo em português brasileiro, sem placeholders
- Um commit por issue
```

---

## Task 7: Dispatch — Agente Legal/Ops (6 issues)

**Files:**
- Create: docs/legal/, docs/ops/

- [ ] **Step 1: Disparar agente via Agent tool com isolation: worktree**

```
Você é o agente Legal/Ops do projeto Lexend Scholar.

CONTEXTO DO PROJETO:
- Empresa: Lexend Scholar — SaaS B2B de gestão escolar, Brasil
- Pricing: Starter R$297/mês, Pro R$697/mês, Enterprise R$1.497/mês
- Linear API: https://api.linear.app/graphql
- Auth: Authorization: lin_api_owdsl43rZHedxr70pC2OXqAmSxR6plRPZpeyVyrU
- State "In Progress": [STATE_IN_PROGRESS]
- State "Done": [STATE_DONE]

SEUS ISSUES (execute nesta ordem):
IP e Contratos:
- LS-181 (p2): Verificar disponibilidade e registrar marca Lexend Scholar no INPI
- LS-184 (p2): Criar templates de contrato de prestação de serviços
- LS-185 (p3): Criar templates de NDA e acordos de IP para colaboradores

Budget e Planejamento:
- LS-149 (p3): Criar budget anual com centros de custo
- LS-151 (p3): Configurar dashboard financeiro (MRR, ARR, churn, LTV)
- LS-150 (p4): Criar modelo de forecasting MRR/ARR

PROTOCOLO POR ISSUE: [mesmo da Task 3]

REGRAS:
- Contratos e NDAs vão em docs/legal/
- INPI: documentar processo em docs/legal/inpi-registro.md
- Budget e financeiro vão em docs/ops/
- Conteúdo em português com terminologia jurídica adequada
- Sem placeholders — rascunhos reais e utilizáveis
- Um commit por issue
```

---

## Task 8: Monitorar progresso

- [ ] **Step 1: Checar progresso periodicamente**

```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: lin_api_owdsl43rZHedxr70pC2OXqAmSxR6plRPZpeyVyrU" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ team(id: \"740589b4-a4b2-47e9-9807-7065c4377fa1\") { issues { nodes { identifier state { name } } } } }"}' \
  | python3 -c "
import json,sys
from collections import defaultdict
d=json.load(sys.stdin)
issues=d['data']['team']['issues']['nodes']
by_state=defaultdict(list)
for i in issues:
    by_state[i['state']['name']].append(i['identifier'])
for s,ids in sorted(by_state.items()):
    print(f'{s} ({len(ids)}): {chr(10)}  ' + chr(10)+'  '.join(sorted(ids)))
"
```

Expected final: Done: 50 issues.

---

## Task 9: Merge em main

- [ ] **Step 1: Merge Legal/Ops**

```bash
git merge feat/legal-ops --no-ff -m "merge: legal/ops domain (LS-149, LS-150, LS-151, LS-181, LS-184, LS-185)"
```

- [ ] **Step 2: Merge Growth/Sales**

```bash
git merge feat/growth-sales --no-ff -m "merge: growth/sales domain (LS-141, LS-146, LS-147, LS-148, LS-179, LS-182, LS-183, LS-186)"
```

- [ ] **Step 3: Merge iOS/Android**

```bash
git merge feat/ios-android --no-ff -m "merge: ios/android domain (LS-152, LS-153, LS-154, LS-155, LS-156, LS-157, LS-159)"
```

- [ ] **Step 4: Merge Web/Infra**

```bash
git merge feat/web-infra --no-ff -m "merge: web/infra domain (LS-137, LS-138, LS-139, LS-140, LS-144, LS-145, LS-161, LS-163, LS-165, LS-177, LS-180, LS-188, LS-189)"
```

- [ ] **Step 5: Merge Store & Quality**

```bash
git merge feat/store-quality --no-ff -m "merge: store/quality domain (LS-158, LS-160, LS-162, LS-164, LS-166, LS-167, LS-168, LS-169, LS-170, LS-171, LS-172, LS-173, LS-174, LS-175, LS-176, LS-178)"
```

- [ ] **Step 6: Verificar resultado**

```bash
git log --oneline -10
git status
```

Expected: 5 merges em main, working tree limpa.

---

## Notas de Execução

- Tasks 3, 4, 5, 6 e 7 podem ser disparadas em paralelo na mesma mensagem do Agent tool.
- O merge da Task 9 Step 5 (Store & Quality) aguarda iOS/Android estar completo — os demais são independentes.
- Issues de código Android que exigem Android Studio (LS-163, LS-165) podem entregar estrutura de arquivos + docs se o ambiente não tiver o SDK configurado.
