# Modelo de Forecasting MRR/ARR — Lexend Scholar

**Documento:** Modelo de Projeção de Receita Recorrente  
**Versão:** 1.0 — Abril/2026  
**Período projetado:** Abril/2026 a Dezembro/2027  
**Responsável:** Founders / Ops  
**Atualização:** Mensal (dia 5 de cada mês, com dados reais do Stripe)

---

## 1. Premissas do Modelo

### 1.1 Premissas Gerais

| Premissa | Pessimista | Base | Otimista |
|---|---|---|---|
| Início das primeiras vendas | Mai/26 | Mai/26 | Abr/26 |
| Taxa de crescimento de novos clientes/mês | 1-2 | 2-4 | 4-6 |
| Churn mensal médio (logo churn) | 8% | 5% | 2% |
| Taxa de conversão trial → pago | 10% | 20% | 35% |
| Mix de planos (Starter/Pro/Enterprise) | 80/15/5% | 65/25/10% | 50/35/15% |
| Ticket médio ponderado | ~R$ 360 | ~R$ 500 | ~R$ 650 |
| Upsell rate mensal | 1% | 3% | 5% |

### 1.2 Premissas por Métrica

#### Conversão de Trial
```
Taxa de conversão = Clientes que assinam ÷ Trials iniciados × 100

Pessimista: 10% — mercado difícil, ciclo longo de decisão
Base:       20% — produto competitivo, processo de vendas estruturado
Otimista:   35% — forte product-market fit, marketing eficaz
```

#### Churn Mensal
```
Churn impacta o crescimento líquido:
- Churn 8%/mês = perde ~65% dos clientes em 12 meses
- Churn 5%/mês = perde ~46% dos clientes em 12 meses
- Churn 2%/mês = perde ~21% dos clientes em 12 meses

Benchmark SaaS B2B educacional: 3-5%/mês é aceitável; < 2% é excelente
```

#### ACV — Annual Contract Value
```
ACV = MRR × 12 (por cliente)

Starter ACV:    R$ 297 × 12 = R$ 3.564
Pro ACV:        R$ 697 × 12 = R$ 8.364
Enterprise ACV: R$ 1.497 × 12 = R$ 17.964
```

#### Mix de Planos e Ticket Médio

| Cenário | Starter | Pro | Enterprise | ARPU médio |
|---|---|---|---|---|
| Pessimista | 80% | 15% | 5% | R$ 364,50 |
| Base | 65% | 25% | 10% | R$ 494,65 |
| Otimista | 50% | 35% | 15% | R$ 621,90 |

**Cálculo do ARPU médio (cenário base):**
```
ARPU = (R$297 × 65%) + (R$697 × 25%) + (R$1.497 × 10%)
ARPU = R$193,05 + R$174,25 + R$149,70 = R$517,00
```

---

## 2. Cenário Pessimista

### 2.1 Premissas Pessimistas

- Crescimento lento: 1-2 novos clientes/mês nos primeiros 6 meses
- Churn alto: 8%/mês (ciclo de venda difícil, produto ainda imaturo)
- Mix pesado em Starter: 80% Starter, 15% Pro, 5% Enterprise
- Conversão de trial: 10%
- Nenhum upsell relevante

### 2.2 Projeção Pessimista — MRR Mensal

| Mês | Novos | Churn | Clientes Ativos | MRR | ARR run rate |
|---|---|---|---|---|---|
| Abr/26 | 0 | 0 | 0 | R$ 0 | R$ 0 |
| Mai/26 | 1 | 0 | 1 | R$ 297 | R$ 3.564 |
| Jun/26 | 1 | 0 | 2 | R$ 594 | R$ 7.128 |
| Jul/26 | 2 | 0 | 4 | R$ 1.188 | R$ 14.256 |
| Ago/26 | 2 | 1 | 5 | R$ 1.485 | R$ 17.820 |
| Set/26 | 2 | 1 | 6 | R$ 1.782 | R$ 21.384 |
| Out/26 | 1 | 1 | 6 | R$ 1.782 | R$ 21.384 |
| Nov/26 | 2 | 1 | 7 | R$ 2.079 | R$ 24.948 |
| Dez/26 | 1 | 1 | 7 | R$ 2.079 | R$ 24.948 |
| Jan/27 | 2 | 1 | 8 | R$ 2.376 | R$ 28.512 |
| Fev/27 | 2 | 1 | 9 | R$ 2.673 | R$ 32.076 |
| Mar/27 | 2 | 1 | 10 | R$ 2.970 | R$ 35.640 |
| Abr/27 | 2 | 1 | 11 | R$ 3.267 | R$ 39.204 |
| Mai/27 | 2 | 2 | 11 | R$ 3.267 | R$ 39.204 |
| Jun/27 | 3 | 2 | 12 | R$ 3.564 | R$ 42.768 |
| Jul/27 | 3 | 2 | 13 | R$ 3.861 | R$ 46.332 |
| Ago/27 | 3 | 2 | 14 | R$ 4.158 | R$ 49.896 |
| Set/27 | 3 | 2 | 15 | R$ 4.455 | R$ 53.460 |
| Out/27 | 3 | 3 | 15 | R$ 4.455 | R$ 53.460 |
| Nov/27 | 3 | 3 | 15 | R$ 4.455 | R$ 53.460 |
| Dez/27 | 4 | 3 | 16 | R$ 4.752 | R$ 57.024 |

**Resumo Pessimista:**
- MRR Dez/27: **R$ 4.752** (usando ARPU Starter ~R$297)
- ARR Dez/27: **~R$ 57.024**
- Clientes Dez/27: **~16 clientes**
- Break-even: **nunca atingido** com estrutura de custo atual (~R$14k/mês)
- Ação necessária: reduzir custos drasticamente ou pivotar

### 2.3 Resultado Pessimista em 24 meses

| Indicador | Valor |
|---|---|
| Receita total acumulada (24 meses) | ~R$ 54.000 |
| Custo total estimado (24 meses) | ~R$ 336.000 |
| Resultado operacional | **-R$ 282.000** |
| Break-even estimado | Não atingido |

---

## 3. Cenário Base

### 3.1 Premissas Base

- Crescimento moderado: 2-4 novos clientes/mês
- Churn saudável: 5%/mês
- Mix equilibrado: 65% Starter, 25% Pro, 10% Enterprise
- Conversão de trial: 20%
- Upsell: 3% dos clientes/mês fazem upgrade de plano

### 3.2 Projeção Base — MRR Mensal

| Mês | Novos | Churn | Upsell | Clientes | MRR | ARR run rate |
|---|---|---|---|---|---|---|
| Abr/26 | 0 | 0 | 0 | 0 | R$ 0 | R$ 0 |
| Mai/26 | 2 | 0 | 0 | 2 | R$ 594 | R$ 7.128 |
| Jun/26 | 3 | 0 | 0 | 5 | R$ 1.885 | R$ 22.620 |
| Jul/26 | 3 | 0 | 0 | 8 | R$ 3.176 | R$ 38.112 |
| Ago/26 | 3 | 1 | 1 | 11 | R$ 4.814 | R$ 57.768 |
| Set/26 | 3 | 1 | 1 | 14 | R$ 7.255 | R$ 87.060 |
| Out/26 | 3 | 1 | 1 | 16 | R$ 8.244 | R$ 98.928 |
| Nov/26 | 3 | 1 | 1 | 18 | R$ 9.231 | R$ 110.772 |
| Dez/26 | 4 | 1 | 1 | 21 | R$ 10.220 | R$ 122.640 |
| Jan/27 | 4 | 2 | 1 | 24 | R$ 12.713 | R$ 152.556 |
| Fev/27 | 4 | 2 | 1 | 27 | R$ 14.897 | R$ 178.764 |
| Mar/27 | 4 | 2 | 2 | 30 | R$ 17.453 | R$ 209.436 |
| Abr/27 | 5 | 2 | 2 | 34 | R$ 20.647 | R$ 247.764 |
| Mai/27 | 5 | 2 | 2 | 38 | R$ 23.841 | R$ 286.092 |
| Jun/27 | 5 | 2 | 2 | 42 | R$ 26.035 | R$ 312.420 |
| Jul/27 | 5 | 3 | 2 | 46 | R$ 28.229 | R$ 338.748 |
| Ago/27 | 5 | 3 | 3 | 50 | R$ 30.423 | R$ 365.076 |
| Set/27 | 6 | 3 | 3 | 54 | R$ 33.617 | R$ 403.404 |
| Out/27 | 6 | 3 | 3 | 58 | R$ 35.811 | R$ 429.732 |
| Nov/27 | 6 | 3 | 3 | 62 | R$ 38.005 | R$ 456.060 |
| Dez/27 | 6 | 4 | 3 | 65 | R$ 40.199 | R$ 482.388 |

**Resumo Base:**
- MRR Dez/27: **~R$ 40.000**
- ARR Dez/27: **~R$ 480.000**
- Clientes Dez/27: **~65 clientes**
- Break-even: **Set/26** (~5º mês de operação) — com redução de custos no início
- Lucro operacional (Ano 2): positivo a partir de Jun/27

### 3.3 Resultado Base em 24 meses

| Indicador | Valor |
|---|---|
| Receita total acumulada (24 meses) | ~R$ 310.000 |
| Custo total estimado (24 meses) | ~R$ 336.000* |
| Resultado operacional | **-R$ 26.000** (quase break-even) |
| Break-even MRR mensal | Atingido em Set/26 |
| Lucrativo a partir de | Jan/27 (fluxo mensal positivo) |

*Custos podem ser otimizados conforme crescimento.

---

## 4. Cenário Otimista

### 4.1 Premissas Otimistas

- Crescimento acelerado: 4-6 novos clientes/mês (efeito referral + marketing)
- Churn excelente: 2%/mês (produto com alto valor percebido)
- Mix premium: 50% Starter, 35% Pro, 15% Enterprise
- Conversão de trial: 35%
- Upsell: 5% dos clientes/mês fazem upgrade de plano
- Possibilidade de rodada seed ou investimento anjo a partir de Q3/26

### 4.2 Projeção Otimista — MRR Mensal

| Mês | Novos | Churn | Upsell | Clientes | MRR | ARR run rate |
|---|---|---|---|---|---|---|
| Abr/26 | 2 | 0 | 0 | 2 | R$ 1.394 | R$ 16.728 |
| Mai/26 | 4 | 0 | 0 | 6 | R$ 4.182 | R$ 50.184 |
| Jun/26 | 5 | 0 | 1 | 12 | R$ 8.364 | R$ 100.368 |
| Jul/26 | 5 | 0 | 1 | 18 | R$ 12.546 | R$ 150.552 |
| Ago/26 | 5 | 1 | 1 | 24 | R$ 16.728 | R$ 200.736 |
| Set/26 | 6 | 1 | 2 | 31 | R$ 21.607 | R$ 259.284 |
| Out/26 | 6 | 1 | 2 | 38 | R$ 26.486 | R$ 317.832 |
| Nov/26 | 6 | 1 | 2 | 45 | R$ 31.365 | R$ 376.380 |
| Dez/26 | 6 | 1 | 3 | 52 | R$ 36.244 | R$ 434.928 |
| Jan/27 | 7 | 2 | 3 | 60 | R$ 41.820 | R$ 501.840 |
| Fev/27 | 7 | 2 | 3 | 68 | R$ 47.396 | R$ 568.752 |
| Mar/27 | 7 | 2 | 4 | 77 | R$ 53.669 | R$ 644.028 |
| Abr/27 | 8 | 2 | 4 | 87 | R$ 60.639 | R$ 727.668 |
| Mai/27 | 8 | 2 | 5 | 98 | R$ 68.306 | R$ 819.672 |
| Jun/27 | 8 | 3 | 5 | 108 | R$ 75.276 | R$ 903.312 |
| Jul/27 | 8 | 3 | 5 | 118 | R$ 82.246 | R$ 986.952 |
| Ago/27 | 9 | 3 | 6 | 130 | R$ 90.610 | R$ 1.087.320 |
| Set/27 | 9 | 3 | 6 | 142 | R$ 98.974 | R$ 1.187.688 |
| Out/27 | 9 | 3 | 7 | 155 | R$ 108.035 | R$ 1.296.420 |
| Nov/27 | 10 | 4 | 7 | 168 | R$ 117.096 | R$ 1.405.152 |
| Dez/27 | 10 | 4 | 8 | 182 | R$ 126.854 | R$ 1.522.248 |

**Resumo Otimista:**
- MRR Dez/27: **~R$ 127.000**
- ARR Dez/27: **~R$ 1.522.000**
- Clientes Dez/27: **~182 clientes**
- Break-even: **Jun/26** (~2º mês de operação)
- Lucrativo a partir de: **Jul/26**

### 4.3 Resultado Otimista em 24 meses

| Indicador | Valor |
|---|---|
| Receita total acumulada (24 meses) | ~R$ 1.100.000 |
| Custo total estimado (24 meses) | ~R$ 500.000* |
| Resultado operacional | **+R$ 600.000** |
| Break-even MRR mensal | Jun/26 (2º mês) |
| Candidato a rodada Seed | A partir de R$ 500k ARR (previsto Out/26) |

*Custos crescem com time e marketing acelerado.

---

## 5. Comparativo dos 3 Cenários

### MRR ao Final de Cada Trimestre

| Período | Pessimista | Base | Otimista |
|---|---|---|---|
| Jun/26 (T1) | R$ 594 | R$ 1.885 | R$ 8.364 |
| Set/26 (T2) | R$ 1.782 | R$ 7.255 | R$ 21.607 |
| Dez/26 (T3) | R$ 2.079 | R$ 10.220 | R$ 36.244 |
| Mar/27 (T4) | R$ 2.970 | R$ 17.453 | R$ 53.669 |
| Jun/27 (T5) | R$ 3.564 | R$ 26.035 | R$ 75.276 |
| Set/27 (T6) | R$ 4.455 | R$ 33.617 | R$ 98.974 |
| Dez/27 (T7) | R$ 4.752 | R$ 40.199 | R$ 126.854 |

### Número de Clientes ao Final do Período

| Período | Pessimista | Base | Otimista |
|---|---|---|---|
| Dez/26 | 7 | 21 | 52 |
| Jun/27 | 12 | 42 | 108 |
| Dez/27 | 16 | 65 | 182 |

---

## 6. Variáveis de Sensibilidade

As variáveis com maior impacto no MRR projetado:

| Variável | Impacto no MRR (+1 unidade) | Prioridade de gestão |
|---|---|---|
| Churn rate (-1%) | +12-18% no MRR acumulado em 12 meses | ALTA |
| Novos clientes/mês (+1) | +R$ 297-1.497 no MRR | ALTA |
| Mix de planos (shift Starter→Pro) | +R$ 400/cliente | MÉDIA |
| Upsell rate (+1%) | +R$ 50-200/mês ao MRR | MÉDIA |
| Conversão trial (+5%) | Depende do volume de trials | BAIXA* |

*Baixa prioridade inicialmente porque o volume de trials ainda é pequeno.

---

## 7. Gatilhos de Decisão por Cenário

### Indicadores de que estamos no Cenário Pessimista
- MRR < R$ 2.000 após 6 meses de operação
- Churn > 7% por 2 meses consecutivos
- < 5 novos clientes nos primeiros 4 meses

**Ações:**
- Reduzir custos: pausar marketing pago, cortar ferramentas não essenciais
- Focar em vendas diretas (founder-led sales)
- Revisar ICP (Ideal Customer Profile) e proposta de valor
- Considerar programa de co-founder/advisor comercial

### Indicadores de que estamos no Cenário Base
- MRR entre R$ 5.000 e R$ 10.000 após 6 meses
- Churn entre 3% e 6%
- 15-25 clientes ao final do 12º mês

**Ações:**
- Manter investimento atual em marketing
- Iniciar construção de equipe de Customer Success
- Começar processo de upsell estruturado
- Avaliar expansão para novos segmentos (escolas maiores)

### Indicadores de que estamos no Cenário Otimista
- MRR > R$ 15.000 após 6 meses
- Churn < 3% por 3 meses consecutivos
- > 40 clientes ao final do 12º mês

**Ações:**
- Preparar pitch para rodada de investimento (anjo ou seed)
- Contratar time de vendas dedicado
- Lançar programa de parcerias (brokers, consultores educacionais)
- Expandir para mercados adjacentes (redes de escolas, franquias)

---

## 8. Modelo de Atualização Mensal

**Todo dia 5 do mês, atualizar:**

1. Coletar dados reais do Stripe:
   - MRR atual
   - Novos clientes (New MRR)
   - Cancelamentos (Churned MRR)
   - Upgrades (Expansion MRR)
   - Downgrades (Contraction MRR)

2. Calcular desvio real vs. projetado:
```
Desvio MRR (%) = (MRR Real - MRR Projetado) ÷ MRR Projetado × 100

> +10%: próximo do cenário otimista — revisar para cima
< -10%: próximo do cenário pessimista — acionar plano de contingência
Entre -10% e +10%: cenário base — manter curso
```

3. Ajustar premissas com base nos dados reais (churn, conversão, mix de planos)

4. Re-projetar os próximos 6 meses com premissas atualizadas

---

## 9. Integração com o Dashboard Financeiro

As projeções deste modelo alimentam o dashboard financeiro (`docs/ops/dashboard-financeiro.md`):

- **Meta de MRR mensal:** conforme coluna "Base" deste modelo
- **Alertas de churn:** threshold de 5% (acima = pessimista, abaixo = base/otimista)
- **Revisão trimestral:** comparar acumulado real vs. projetado nos 3 cenários

---

*Modelo de forecasting v1.0 — Lexend Scholar. Atualizar com dados reais do Stripe mensalmente. Revisão trimestral dos cenários. Abril/2026.*
