# SLA Tiers e Regras de Roteamento — Lexend Scholar

## Visão Geral

O Lexend Scholar opera com 3 tiers de SLA alinhados aos planos de assinatura. Os tiers definem tempos de resposta, canais disponíveis e regras de escalação.

---

## Tiers de SLA

### Tier 1 — Basic

**Perfil**: Escolas pequenas, até 150 alunos.
**Plano correspondente**: Basic (R$197/mês)

| Métrica | SLA |
|---|---|
| Primeira resposta | 24 horas úteis |
| Resolução de bugs críticos (P0) | 72 horas úteis |
| Resolução de bugs altos (P1) | 5 dias úteis |
| Resolução de bugs médios (P2) | 15 dias úteis |
| Resolução de melhorias (P3) | Sem comprometimento |
| Uptime garantido | 99% |

**Canais disponíveis**:
- Chat via widget no app (horário comercial)
- Help Center (autoatendimento 24/7)
- Email (suporte@lexendscholar.com)

---

### Tier 2 — Pro

**Perfil**: Escolas médias, até 500 alunos.
**Plano correspondente**: Pro (R$397/mês)

| Métrica | SLA |
|---|---|
| Primeira resposta | 8 horas úteis |
| Resolução de bugs críticos (P0) | 24 horas úteis |
| Resolução de bugs altos (P1) | 3 dias úteis |
| Resolução de bugs médios (P2) | 7 dias úteis |
| Resolução de melhorias (P3) | Backlog priorizado |
| Uptime garantido | 99,5% |

**Canais disponíveis**:
- Chat com prioridade (resposta mais rápida)
- Email com SLA
- Help Center
- Acesso a webinars mensais de treinamento

---

### Tier 3 — Enterprise

**Perfil**: Redes de ensino, grupos escolares, 500+ alunos.
**Plano correspondente**: Enterprise (preço negociado, a partir de R$997/mês)

| Métrica | SLA |
|---|---|
| Primeira resposta | 2 horas úteis |
| Resolução de bugs críticos (P0) | 4 horas (incluindo fora do horário comercial) |
| Resolução de bugs altos (P1) | 24 horas úteis |
| Resolução de bugs médios (P2) | 3 dias úteis |
| Resolução de melhorias (P3) | Revisão mensal com CSM |
| Uptime garantido | 99,9% |

**Canais disponíveis**:
- Canal dedicado no WhatsApp (CSM designado)
- Chat prioritário
- Email com SLA
- Videoconferência mensal com Customer Success Manager
- Help Center
- Early access a novas features

---

## Classificação de Severidades de Bugs

| Severidade | Descrição | Exemplos |
|---|---|---|
| **P0 — Crítico** | Sistema inacessível ou perda de dados em produção | App não abre para todos os usuários da escola; dados de alunos inacessíveis; falha de pagamento em cascata |
| **P1 — Alto** | Feature principal inoperante, afetando workflow diário | Não é possível lançar frequência; notas não salvam; relatórios não geram |
| **P2 — Médio** | Degradação de funcionalidade, workaround possível | Filtros com comportamento incorreto; PDF com formatação errada; notificações atrasadas |
| **P3 — Baixo** | Problema cosmético ou de UX, sem impacto funcional | Texto com erro tipográfico; botão com cor errada; tooltip ausente |

---

## Regras de Roteamento

### Roteamento Automático (via Crisp)

```
SE tag = "bug" E tier = "enterprise"   → assignar para Suporte Técnico Senior + notificar Slack #oncall
SE tag = "bug" E tier = "pro"          → assignar para Suporte Técnico
SE tag = "bug" E tier = "basic"        → assignar para fila Suporte Técnico (FIFO)
SE tag = "comercial" OU "upgrade"      → assignar para Comercial
SE tag = "financeiro" OU "cobrança"    → assignar para Financeiro
SE tag = "onboarding" E tier = "enterprise" → assignar para CSM designado
SE fora do horário E tier = "enterprise" → notificar oncall via PagerDuty
```

### Identificação do Tier
O tier do cliente é enviado automaticamente pelo SDK iOS no início da sessão:
```swift
Crisp.setSessionString("plan", "pro")  // basic | pro | enterprise
Crisp.setSessionString("school_id", schoolId)
Crisp.setSessionString("students_count", "\(school.studentsCount)")
```

---

## Regras de Escalação

### Escalação por Tempo Sem Resposta

| Tier | Sem resposta por | Ação |
|---|---|---|
| Basic | 36h úteis | Alerta no Slack #suporte |
| Pro | 10h úteis | Alerta no Slack + email para agente responsável |
| Enterprise | 3h úteis | Alerta no Slack #oncall + notificação push para CSM |

### Escalação por Severidade

**P0 em qualquer tier**:
1. Criar issue no Linear com label `P0` e `Bug` imediatamente
2. Notificar canal Slack `#incidentes`
3. Co-fundadores notificados via WhatsApp
4. Comunicação proativa para cliente em até 30 minutos
5. Atualizações a cada 1 hora até resolução

**P1 em Enterprise**:
1. Criar issue no Linear com label `P1`
2. CSM do cliente notificado imediatamente
3. Engineer atribuído em até 2 horas

### Escalação para Co-fundadores
Escalar obrigatoriamente quando:
- Qualquer P0
- Cliente Enterprise com P1 sem resolução em 12h
- Reclamação formal de churn por cliente Pro ou Enterprise
- Ameaça legal ou menção à LGPD

---

## Horários de Atendimento

| Canal | Horário |
|---|---|
| Chat (Basic/Pro) | Seg-Sex 9h-18h BRT |
| Chat (Enterprise) | Seg-Sex 8h-20h BRT |
| On-call P0 | 24/7 (todos os tiers) |
| Email | Respondido em horário comercial |
| WhatsApp CSM (Enterprise) | Seg-Sex 8h-20h BRT |

---

## Métricas de Qualidade (Meta)

| Métrica | Meta |
|---|---|
| CSAT (satisfação pós-atendimento) | ≥ 4.5/5.0 |
| First Contact Resolution (FCR) | ≥ 70% |
| Tempo médio de primeira resposta | ≤ SLA do tier |
| Ticket reaberto (resolve incorreto) | ≤ 5% |
| NPS de suporte | ≥ 40 |
