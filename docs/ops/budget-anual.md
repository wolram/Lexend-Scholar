# Budget Anual — Lexend Scholar 2026

**Documento:** Planejamento Financeiro e Centros de Custo  
**Período:** Abril/2026 a Março/2027  
**Versão:** 1.0 — Abril/2026  
**Responsável:** Founders / Ops  
**Status:** Rascunho para aprovação

---

## 1. Premissas e Contexto

### Modelo de Receita

| Plano | Preço/mês | Alunos | Alvo de clientes (ano 1) |
|---|---|---|---|
| Starter | R$ 297,00 | até 100 | 15 escolas |
| Pro | R$ 697,00 | até 500 | 8 escolas |
| Enterprise | R$ 1.497,00 | ilimitado | 2 escolas |

**MRR alvo ao final do ano 1:** R$ 13.789,00  
(15 × R$297 + 8 × R$697 + 2 × R$1.497 = R$4.455 + R$5.576 + R$2.994 = R$13.025)

**ARR alvo:** ~R$ 156.300,00

### Forma Jurídica
- **PJ SLU (Sociedade Limitada Unipessoal)** — recomendada para Simples Nacional
- Regime tributário: Simples Nacional (alíquota inicial ~6% sobre receita bruta para serviços de tecnologia — Anexo III/V)

---

## 2. Centros de Custo — Detalhamento Mensal

### 2.1 Infraestrutura (INFRA)

| Item | Fornecedor | Custo Mensal | Custo Anual |
|---|---|---|---|
| Banco de dados + Backend | Supabase (Pro) | R$ 150,00 | R$ 1.800,00 |
| Hospedagem / Deploy | Vercel (Pro) | R$ 100,00 | R$ 1.200,00 |
| Domínio (.com.br + .com) | Registro.br / Namecheap | R$ 15,00 | R$ 180,00 |
| E-mail transacional | Resend / SendGrid | R$ 30,00 | R$ 360,00 |
| CDN e assets | Cloudflare (Free/Pro) | R$ 20,00 | R$ 240,00 |
| Monitoramento / Observabilidade | Sentry (Team) | R$ 30,00 | R$ 360,00 |
| Backup adicional | Backblaze B2 | R$ 10,00 | R$ 120,00 |
| **Total INFRA** | | **R$ 355,00** | **R$ 4.260,00** |

### 2.2 Ferramentas e SaaS (TOOLS)

| Item | Fornecedor | Custo Mensal | Custo Anual |
|---|---|---|---|
| Gestão de projetos | Linear (Standard) | R$ 50,00 | R$ 600,00 |
| Suporte ao cliente | Crisp (Pro) | R$ 50,00 | R$ 600,00 |
| E-mail marketing | ConvertKit (Creator) | R$ 100,00 | R$ 1.200,00 |
| Design | Figma (Professional) | R$ 50,00 | R$ 600,00 |
| Analytics | Mixpanel / Posthog (Free) | R$ 0,00 | R$ 0,00 |
| Pagamentos | Stripe (2,9% + R$0,30 por tx) | R$ 50,00* | R$ 600,00* |
| Assinatura eletrônica | DocuSign / ZapSign | R$ 50,00 | R$ 600,00 |
| Senha e segurança | 1Password Teams | R$ 30,00 | R$ 360,00 |
| Video/gravação (suporte) | Loom (Business) | R$ 20,00 | R$ 240,00 |
| **Total TOOLS** | | **R$ 400,00** | **R$ 4.800,00** |

*Stripe: valor estimado com base em volume inicial de transações. Cresce proporcionalmente à receita.

### 2.3 Marketing e Aquisição (MKTG)

| Item | Descrição | Custo Mensal | Custo Anual |
|---|---|---|---|
| Google Ads | Campanhas para busca ("software gestão escolar") | R$ 500,00 | R$ 6.000,00 |
| LinkedIn Ads | Alcance a gestores de escolas (Q3 e Q4) | R$ 200,00 | R$ 1.200,00* |
| Produção de conteúdo | Blog posts, materiais educativos (freelancer) | R$ 300,00 | R$ 3.600,00 |
| SEO e ferramentas | Ahrefs / Semrush (Lite) | R$ 60,00 | R$ 720,00 |
| Materiais de venda | Pitchdecks, one-pagers, demos | R$ 100,00 | R$ 600,00 |
| Eventos e feiras | Presença em eventos do setor educacional | R$ 200,00 | R$ 1.200,00* |
| **Total MKTG** | | **R$ 1.360,00** | **R$ 13.320,00** |

*LinkedIn Ads e eventos: concentrados em Q3 (out-dez/2026) — valor mensal pode variar.

### 2.4 Legal e Compliance (LEGAL)

| Item | Descrição | Custo | Período |
|---|---|---|---|
| Constituição PJ (SLU) | Abertura empresa, contabilidade inicial | R$ 1.500,00 | Único (Abr/26) |
| Advogado LGPD | Políticas, DPO, contratos iniciais | R$ 2.000,00 | Único (Mai/26) |
| Registro de marca INPI | 2 marcas × 2 classes (NCL 41 e 42) | R$ 1.420,00 | Único (Mai/26) |
| Contador / Contabilidade | Simples Nacional, folha, obrigações acessórias | R$ 400,00 | Mensal |
| Advogado retainer (suporte) | Consultoria mensal jurídica | R$ 500,00 | Mensal |
| **Total LEGAL — Recorrente** | | **R$ 900,00/mês** | **R$ 10.800,00/ano** |
| **Total LEGAL — Custos únicos** | | **R$ 4.920,00** | Ano 1 apenas |

### 2.5 Pessoal e Operações (PESSOAL)

| Item | Descrição | Custo Mensal | Custo Anual |
|---|---|---|---|
| Founder(s) — pro-labore | Retirada mínima até break-even | R$ 3.000,00* | R$ 36.000,00 |
| Desenvolvedor freelancer | Suporte técnico / features (40h/mês) | R$ 4.000,00 | R$ 48.000,00 |
| Designer freelancer | UI/UX (20h/mês) | R$ 2.000,00 | R$ 24.000,00 |
| Customer Success (part-time) | Onboarding e retenção (20h/mês) | R$ 1.500,00 | R$ 18.000,00 |
| **Total PESSOAL** | | **R$ 10.500,00** | **R$ 126.000,00** |

*Pro-labore founder: ajustável conforme geração de caixa. Pode ser zero nas primeiras semanas.

### 2.6 Outros Custos Operacionais (OUTROS)

| Item | Descrição | Custo Mensal | Custo Anual |
|---|---|---|---|
| Escritório / coworking | Plano básico ou home-office | R$ 500,00 | R$ 6.000,00 |
| Equipamentos | Amortização Mac, monitores, headsets | R$ 200,00 | R$ 2.400,00 |
| Telefone / Internet | Plano corporativo | R$ 150,00 | R$ 1.800,00 |
| Cursos e treinamentos | Desenvolvimento da equipe | R$ 100,00 | R$ 1.200,00 |
| Reserva para imprevistos | Fundo de contingência (5% dos custos) | R$ 600,00 | R$ 7.200,00 |
| **Total OUTROS** | | **R$ 1.550,00** | **R$ 18.600,00** |

---

## 3. Resumo Consolidado de Custos

### 3.1 Custos Mensais Recorrentes

| Centro de Custo | Custo/Mês | % do Total |
|---|---|---|
| INFRA | R$ 355,00 | 2,5% |
| TOOLS | R$ 400,00 | 2,8% |
| MKTG | R$ 1.360,00 | 9,6% |
| LEGAL (recorrente) | R$ 900,00 | 6,4% |
| PESSOAL | R$ 10.500,00 | 74,2% |
| OUTROS | R$ 550,00 | 3,9% |
| **TOTAL MENSAL** | **R$ 14.065,00** | **100%** |

*OUTROS sem reserva de contingência: R$550/mês

### 3.2 Custos Totais Anuais (Ano 1)

| Centro de Custo | Custo Anual | Notas |
|---|---|---|
| INFRA | R$ 4.260,00 | Recorrente |
| TOOLS | R$ 4.800,00 | Recorrente |
| MKTG | R$ 13.320,00 | Cresce com receita |
| LEGAL | R$ 15.720,00 | R$10.800 recorrente + R$4.920 único |
| PESSOAL | R$ 126.000,00 | Principal custo |
| OUTROS | R$ 18.600,00 | Inclui contingência |
| **TOTAL ANO 1** | **R$ 182.700,00** | |

---

## 4. Projeção de Receita — 12 Meses

| Mês | Clientes Starter | Clientes Pro | Clientes Enterprise | MRR | Receita Acum. |
|---|---|---|---|---|---|
| Abr/26 | 0 | 0 | 0 | R$ 0 | R$ 0 |
| Mai/26 | 2 | 0 | 0 | R$ 594 | R$ 594 |
| Jun/26 | 4 | 1 | 0 | R$ 1.885 | R$ 2.479 |
| Jul/26 | 6 | 2 | 0 | R$ 3.176 | R$ 5.655 |
| Ago/26 | 8 | 3 | 0 | R$ 4.467 | R$ 10.122 |
| Set/26 | 10 | 4 | 1 | R$ 7.255 | R$ 17.377 |
| Out/26 | 11 | 5 | 1 | R$ 8.244 | R$ 25.621 |
| Nov/26 | 12 | 6 | 1 | R$ 9.231 | R$ 34.852 |
| Dez/26 | 13 | 7 | 1 | R$ 10.220 | R$ 45.072 |
| Jan/27 | 14 | 7 | 2 | R$ 12.713 | R$ 57.785 |
| Fev/27 | 14 | 8 | 2 | R$ 13.409 | R$ 71.194 |
| Mar/27 | 15 | 8 | 2 | R$ 13.409 | R$ 84.603 |

**Receita total projetada (Ano 1):** ~R$ 84.603,00  
**MRR ao final do Ano 1:** R$ 13.409,00  
**ARR run rate ao final do Ano 1:** ~R$ 160.908,00

---

## 5. Break-Even Analysis

### 5.1 Ponto de Equilíbrio Mensal

Custo mensal operacional (sem pro-labore founder): **~R$ 11.065,00**  
Custo mensal completo (com pro-labore R$3.000): **~R$ 14.065,00**

| Cenário de break-even | MRR necessário | Clientes equivalentes (mix médio ~R$450/cliente) |
|---|---|---|
| Custos operacionais (sem pro-labore) | R$ 11.065 | ~25 clientes |
| Custos totais (com pro-labore R$3.000) | R$ 14.065 | ~31 clientes |

**Projeção de break-even:** entre Q3 e Q4/2026 (7º a 9º mês)

### 5.2 Runway Atual

| Item | Valor |
|---|---|
| Caixa inicial disponível | R$ _____________ |
| Burn rate mensal médio | ~R$ 13.000,00 |
| Runway estimado | _____ meses |

*Preencher com dados reais do caixa atual.*

### 5.3 CAC e LTV estimados

| Métrica | Cálculo | Valor |
|---|---|---|
| CAC (Custo de Aquisição) | Custo MKTG / Novos clientes/mês | ~R$ 1.360 / 3 clientes = ~R$ 453 |
| LTV Starter (12 meses) | R$297 × 12 × (1 - 5% churn) | ~R$ 3.381 |
| LTV Pro (12 meses) | R$697 × 12 × (1 - 3% churn) | ~R$ 8.104 |
| LTV/CAC Starter | | ~7,5x (meta: >3x) |
| Payback period Starter | CAC / (MRR × margem ~70%) | ~2,2 meses |

---

## 6. Controles e Revisão

### 6.1 Calendário de revisão orçamentária

| Frequência | Atividade | Responsável |
|---|---|---|
| Semanal | Revisão de caixa e despesas | Founder/Ops |
| Mensal | Comparativo orçado vs. realizado | Contador + Founders |
| Trimestral | Revisão de metas e reforecast | Founders |
| Anual | Planejamento do próximo exercício | Founders + Conselho |

### 6.2 Limites de aprovação

| Valor | Aprovador |
|---|---|
| Até R$ 500,00 | Founder operacional |
| R$ 501,00 a R$ 5.000,00 | Qualquer founder (maioria) |
| Acima de R$ 5.000,00 | Reunião formal de founders |
| Contratações | Founders em conjunto |

---

## 7. Ferramentas de Controle Recomendadas

| Finalidade | Ferramenta | Status |
|---|---|---|
| Contabilidade | Conta Azul / Omie | A contratar |
| Controle de caixa | Planilha Google Sheets / Notion | Imediato |
| Dashboard SaaS | ChartMogul / ProfitWell | A implementar |
| Banco PJ | Nubank PJ / Banco Inter PJ | A abrir |
| Cartão corporativo | Nubank PJ | A solicitar |

---

*Budget anual v1.0 — Lexend Scholar. Elaborado em Abril/2026. Revisar mensalmente conforme dados reais do Stripe e contabilidade.*
