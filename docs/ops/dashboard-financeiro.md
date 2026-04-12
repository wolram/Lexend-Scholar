# Dashboard Financeiro — Lexend Scholar

**Documento:** Definição de Métricas, Fórmulas e Configuração do Dashboard SaaS  
**Versão:** 1.0 — Abril/2026  
**Ferramentas:** Stripe + ChartMogul (ou ProfitWell)  
**Responsável:** Founders / Ops  
**Revisão:** Mensal (todo dia 5 do mês seguinte)

---

## 1. Visão Geral do Dashboard

O dashboard financeiro da Lexend Scholar centraliza as métricas essenciais de saúde do negócio SaaS, permitindo decisões baseadas em dados sobre crescimento, retenção e sustentabilidade financeira.

### Ferramentas recomendadas

| Ferramenta | Função | Custo | Link |
|---|---|---|---|
| **Stripe** | Gateway de pagamento + dados brutos de assinaturas | 2,9% + R$0,30/tx | stripe.com |
| **ChartMogul** | Dashboard SaaS completo integrado ao Stripe | Free até US$10k MRR | chartmogul.com |
| **ProfitWell** | Alternativa gratuita ao ChartMogul | Gratuito | profitwell.com |
| **Google Sheets** | Modelo backup/manual para acompanhamento | Gratuito | sheets.google.com |
| **Metabase** | Self-hosted BI para análises avançadas | Gratuito (self-hosted) | metabase.com |

**Configuração mínima viável:** Stripe + ProfitWell (ambos gratuitos) + Planilha de controle manual.  
**Configuração ideal:** Stripe + ChartMogul (após atingir US$10k MRR começa a cobrar).

---

## 2. Métricas e Fórmulas

### 2.1 MRR — Monthly Recurring Revenue (Receita Recorrente Mensal)

**Definição:** Soma de todas as receitas de assinaturas recorrentes em um mês, normalizada para valor mensal.

**Fórmula:**
```
MRR = Σ (Valor mensal de cada assinatura ativa)

Para planos anuais: MRR = Valor anual ÷ 12
```

**Exemplo com dados reais (Setembro/2026 — cenário base):**

| Plano | Clientes | Preço/mês | Subtotal |
|---|---|---|---|
| Starter | 10 | R$ 297,00 | R$ 2.970,00 |
| Pro | 4 | R$ 697,00 | R$ 2.788,00 |
| Enterprise | 1 | R$ 1.497,00 | R$ 1.497,00 |
| **MRR Total** | **15** | | **R$ 7.255,00** |

**Componentes do MRR (para análise de crescimento):**

| Componente | Definição | Exemplo |
|---|---|---|
| **New MRR** | Receita de novos clientes no mês | +R$ 1.188 (4 novos Starter) |
| **Expansion MRR** | Upsell de clientes existentes | +R$ 400 (1 upgrade Starter→Pro) |
| **Contraction MRR** | Downgrade de clientes | -R$ 200 (1 downgrade Pro→Starter) |
| **Churned MRR** | Receita de clientes cancelados | -R$ 297 (1 cancelamento Starter) |
| **Net New MRR** | New + Expansion - Contraction - Churned | +R$ 1.091 |
| **MRR Final** | MRR anterior + Net New MRR | R$ 6.164 + R$1.091 = R$7.255 |

### 2.2 ARR — Annual Recurring Revenue (Receita Anual Recorrente)

**Definição:** Projeção anualizada do MRR atual. Representa a receita que a empresa geraria nos próximos 12 meses mantendo o MRR constante.

**Fórmula:**
```
ARR = MRR × 12
```

**Exemplo:**
```
ARR (Set/26) = R$ 7.255 × 12 = R$ 87.060,00
```

**Nota:** ARR NÃO é a receita acumulada dos últimos 12 meses — é uma projeção prospectiva.

### 2.3 Churn Rate — Taxa de Cancelamento

**Definição:** Percentual de clientes (ou receita) perdidos em um período.

#### Churn de Clientes (Logo Churn)
```
Churn Rate (%) = (Clientes cancelados no mês ÷ Clientes ativos no início do mês) × 100
```

**Exemplo (Agosto/2026):**
```
Clientes início do mês: 12
Cancelamentos no mês: 1
Churn Rate = (1 ÷ 12) × 100 = 8,3%

Meta Lexend Scholar: < 5% ao mês (< 3% é excelente para SaaS B2B)
```

#### Revenue Churn (MRR Churn)
```
MRR Churn Rate (%) = (MRR perdido por cancelamentos + downgrades) ÷ MRR início do mês × 100
```

**Exemplo:**
```
MRR início: R$ 6.164
Churned MRR: R$ 297 (1 cancelamento Starter)
Contraction MRR: R$ 200 (1 downgrade)
MRR Churn Rate = (R$297 + R$200) ÷ R$6.164 × 100 = 8,1%
```

#### Net Revenue Retention (NRR) — Retenção Líquida de Receita
```
NRR (%) = (MRR início + Expansion MRR - Contraction MRR - Churned MRR) ÷ MRR início × 100
```

**Exemplo:**
```
NRR = (R$6.164 + R$400 - R$200 - R$297) ÷ R$6.164 × 100 = 98,4%

Meta Lexend Scholar: > 100% (expansão maior que churn = crescimento sem novos clientes)
Referência de mercado: NRR > 120% = excelente; NRR > 100% = saudável
```

### 2.4 LTV — Customer Lifetime Value (Valor Vitalício do Cliente)

**Definição:** Receita total esperada de um cliente durante todo o seu ciclo de vida.

**Fórmula básica:**
```
LTV = ARPU ÷ Churn Rate mensal

Onde:
ARPU = Average Revenue Per User (Receita Média por Usuário/cliente)
```

**Fórmula detalhada com margem:**
```
LTV = (ARPU × Margem Bruta) ÷ Churn Rate mensal
```

**Exemplo por plano:**

| Plano | ARPU/mês | Margem Bruta* | Churn mensal | LTV |
|---|---|---|---|---|
| Starter | R$ 297,00 | 75% | 5% | R$ 4.455,00 |
| Pro | R$ 697,00 | 80% | 3% | R$ 18.587,00 |
| Enterprise | R$ 1.497,00 | 85% | 2% | R$ 63.622,00 |

*Margem bruta estimada: receita menos custos de infraestrutura e suporte diretamente atribuíveis.

**Cálculo detalhado (Starter, margem 75%, churn 5%):**
```
LTV Starter = (R$297 × 75%) ÷ 5% = R$222,75 ÷ 0,05 = R$ 4.455,00
```

**Tempo médio de vida do cliente:**
```
Vida média = 1 ÷ Churn Rate mensal

Starter: 1 ÷ 5% = 20 meses
Pro: 1 ÷ 3% = 33 meses
Enterprise: 1 ÷ 2% = 50 meses
```

### 2.5 CAC — Customer Acquisition Cost (Custo de Aquisição)

**Definição:** Custo total para adquirir um novo cliente pagante.

**Fórmula:**
```
CAC = Total de gastos em Vendas e Marketing ÷ Número de novos clientes no período
```

**Exemplo (mensal):**
```
Gastos em Marketing (Abr/26): R$ 1.360,00
Novos clientes no mês: 3
CAC = R$ 1.360 ÷ 3 = R$ 453,33
```

**Meta:** CAC < LTV ÷ 3 (recuperar o CAC em menos de 1/3 do ciclo de vida)

### 2.6 Payback Period (Período de Recuperação do CAC)

**Definição:** Tempo necessário para recuperar o custo de aquisição de um cliente.

**Fórmula:**
```
Payback Period (meses) = CAC ÷ (ARPU × Margem Bruta)
```

**Exemplo por plano:**

| Plano | CAC | ARPU | Margem | Payback |
|---|---|---|---|---|
| Starter | R$ 453 | R$ 297 | 75% | 2,0 meses |
| Pro | R$ 453 | R$ 697 | 80% | 0,8 meses |
| Enterprise | R$ 1.000* | R$ 1.497 | 85% | 0,8 meses |

*Enterprise geralmente tem CAC maior por envolver ciclo de venda consultivo.

**Meta Lexend Scholar:** Payback < 12 meses (quanto menor, melhor).

### 2.7 LTV/CAC Ratio

**Definição:** Relação entre o valor vitalício do cliente e o custo de aquisição. Principal indicador de eficiência do negócio.

**Fórmula:**
```
LTV/CAC = LTV ÷ CAC
```

**Benchmarks:**

| LTV/CAC | Interpretação |
|---|---|
| < 1x | Negócio insustentável (perde dinheiro em cada cliente) |
| 1x a 3x | Marginal — melhorar aquisição ou retenção |
| 3x a 5x | Saudável |
| > 5x | Excelente — possível accelerar investimento em marketing |
| > 10x | Investindo pouco em marketing — pode crescer mais |

**Exemplo Lexend Scholar (Starter):**
```
LTV/CAC = R$ 4.455 ÷ R$ 453 = 9,8x  ✓ Excelente
```

---

## 3. Configuração do Dashboard no ChartMogul/ProfitWell

### 3.1 Integração com Stripe

**ChartMogul:**
1. Acesse app.chartmogul.com → Settings → Integrations
2. Adicione Stripe como fonte de dados
3. Insira a Stripe API Key (Restricted Key com permissão read-only)
4. Aguarde sincronização histórica (até 24h)
5. Configure moeda: BRL (Real Brasileiro)

**ProfitWell (alternativa gratuita):**
1. Acesse app.profitwell.com → Integrations → Stripe
2. Conecte via OAuth
3. Configure métricas e segmentos por plano

### 3.2 Segmentação por Plano

Configurar grupos/segmentos no ChartMogul:
- **Segment 1:** Starter (filtro: `plan_name = "Starter"` ou `amount = 297`)
- **Segment 2:** Pro (filtro: `plan_name = "Pro"` ou `amount = 697`)
- **Segment 3:** Enterprise (filtro: `plan_name = "Enterprise"` ou `amount = 1497`)

### 3.3 Widgets do Dashboard Principal

| Widget | Métrica | Período | Alerta |
|---|---|---|---|
| MRR atual | R$ valor | Mês corrente | < R$10k = amarelo |
| MRR Growth | % variação M/M | Mês corrente | < 10% = amarelo |
| ARR | R$ valor | Run rate atual | — |
| Churn Rate | % | Mês anterior | > 5% = vermelho |
| NRR | % | Mês anterior | < 100% = vermelho |
| Novos clientes | Número | Mês corrente | < 3 = amarelo |
| LTV médio | R$ valor | Calculado | — |
| CAC | R$ valor | Mês anterior | > LTV/3 = vermelho |
| LTV/CAC | Ratio | Calculado | < 3x = vermelho |
| Payback | Meses | Calculado | > 12m = vermelho |

---

## 4. Planilha de Acompanhamento Manual (Google Sheets)

Enquanto o ChartMogul não é configurado, manter planilha com as seguintes abas:

### Aba 1: Clientes Ativos
| Coluna | Descrição |
|---|---|
| ID Cliente | Identificador único |
| Nome da Escola | Razão social |
| Plano | Starter / Pro / Enterprise |
| MRR | Valor mensal |
| Data início | Início da assinatura |
| Status | Ativo / Em atraso / Cancelado |
| Data cancelamento | Se aplicável |

### Aba 2: MRR Mensal
| Coluna | Descrição |
|---|---|
| Mês | Referência |
| MRR início | Saldo inicial |
| New MRR | Novos clientes |
| Expansion MRR | Upgrades |
| Contraction MRR | Downgrades |
| Churned MRR | Cancelamentos |
| MRR final | Saldo final |
| Growth % | Variação M/M |

### Aba 3: Métricas Consolidadas
Cálculo automático de: ARR, Churn Rate, NRR, LTV por plano, CAC, Payback, LTV/CAC.

---

## 5. Calendário de Revisão Mensal

**Dia 5 de cada mês — Revisão Financeira:**

- [ ] Exportar relatório do Stripe (período anterior)
- [ ] Atualizar planilha de clientes ativos
- [ ] Calcular MRR final do mês anterior
- [ ] Registrar novos clientes, upgrades, downgrades e cancelamentos
- [ ] Calcular churn rate e NRR
- [ ] Atualizar ARR
- [ ] Comparar com metas do budget
- [ ] Registrar observações e ações corretivas
- [ ] Apresentar resultados para todos os founders

**Alertas de ação imediata:**
- Churn > 5%: investigar motivos, acionar CS
- MRR growth < 5%: revisar pipeline de vendas
- NRR < 95%: urgência em expansão e redução de churn
- Runway < 4 meses: iniciar captação ou reduzir custos

---

## 6. Metas de Métricas — Ano 1

| Métrica | Mês 3 (Jun/26) | Mês 6 (Set/26) | Mês 12 (Mar/27) |
|---|---|---|---|
| MRR | R$ 1.885 | R$ 7.255 | R$ 13.409 |
| ARR | R$ 22.620 | R$ 87.060 | R$ 160.908 |
| Clientes ativos | 5 | 15 | 25 |
| Churn mensal | < 8% | < 5% | < 3% |
| NRR | > 90% | > 95% | > 100% |
| LTV/CAC | > 3x | > 5x | > 7x |
| Payback | < 6m | < 3m | < 2m |

---

*Dashboard financeiro v1.0 — Lexend Scholar. Revisar métricas mensalmente todo dia 5. Abril/2026.*
