# Políticas Financeiras do Produto — Lexend Scholar

**Versão**: 1.0
**Owner**: Founders / Financeiro
**Última atualização**: Abril 2026
**Vigência**: A partir de 1º de maio de 2026

---

## Visão Geral

Este documento define as políticas financeiras oficiais do Lexend Scholar, aplicáveis a todos os clientes (escolas). Estas políticas são incorporadas ao contrato de serviços e comunicadas no processo de onboarding.

**Princípio orientador**: Políticas claras, aplicadas de forma consistente e comunicadas com antecedência. Clientes não gostam de surpresas financeiras — nem nós.

---

## 1. Política de Preços

### 1.1 Preços vigentes

Os preços são publicados publicamente em lexendscholar.com/precos e refletem o valor para o ano letivo vigente:

| Plano | Limite de alunos | Preço Mensal | Preço Anual |
|---|---|---|---|
| Basic | Até 150 alunos | R$197/mês | R$1.970/ano (2 meses grátis) |
| Pro | Até 500 alunos | R$397/mês | R$3.970/ano (2 meses grátis) |
| Enterprise | 500+ alunos | Sob consulta | Sob consulta |

### 1.2 Reajuste de preços

**Regra**: O Lexend Scholar não pode aumentar o preço de uma assinatura **sem aviso prévio de mínimo 30 dias corridos**.

**Processo de reajuste:**
1. Comunicar via email para todos os clientes ativos com no mínimo 30 dias de antecedência
2. Detalhar na comunicação: novo preço, data de vigência, motivo do reajuste
3. Oferecer opção de cancelamento sem multa para clientes que discordarem
4. Atualizar a página de preços no website na mesma data do email

**Frequência máxima de reajuste**: Uma vez por ano.

**Reajuste máximo sem justificativa adicional**: Limitado à variação do IPCA acumulado nos últimos 12 meses + 5 pontos percentuais.

**Exceções**: Planos com contrato anual têm o preço travado pelo período do contrato — sem reajuste durante a vigência.

### 1.3 Grandfathering

Clientes que contrataram a um determinado preço têm o direito de manter esse preço enquanto mantiverem a assinatura ativa e sem downgrade. Em caso de upgrade de plano, os novos preços se aplicam integralmente.

---

## 2. Política de Reembolso

### 2.1 Garantia de 30 dias (Money-Back Guarantee)

**Regra**: Todo novo cliente tem direito a reembolso integral se cancelar nos **primeiros 30 dias corridos** após a primeira cobrança paga.

**Condições:**
- Válido apenas para o primeiro pagamento de cada cliente
- Não aplicável a renovações ou upgrades
- Reembolso processado em até 5 dias úteis
- Reembolso realizado pelo mesmo meio de pagamento original (cartão, PIX, etc.)

**Como solicitar:**
- Email para financeiro@lexendscholar.com com assunto "Reembolso — [Nome da Escola]"
- Ou via chat de suporte
- Não é necessário justificar o motivo

### 2.2 Cancelamentos após 30 dias

Após o período de garantia:
- **Planos mensais**: Cancelamento imediato sem reembolso do mês vigente. Acesso mantido até o fim do período pago.
- **Planos anuais**: Sem reembolso proporcional (exceto em casos de falha grave do serviço — ver §2.4)

### 2.3 Crédito em conta vs reembolso em dinheiro

Em situações onde o cliente não acessa o produto por problema técnico nosso (downtime confirmado > 4 horas), oferecemos crédito proporcional na próxima fatura. Este crédito não é convertível em reembolso em dinheiro.

### 2.4 Exceções ao reembolso

Reembolsos fora do período de garantia podem ser concedidos a critério dos founders nos seguintes casos:
- Downtime P0 com duração > 24 horas afetando o cliente
- Cobrança duplicada por erro técnico do sistema
- Falha grave do produto que inviabilize o uso por mais de 7 dias consecutivos

**Aprovação necessária**: Co-founders.

---

## 3. Política de Inadimplência

### 3.1 Fluxo de cobrança e inadimplência

```
Dia do vencimento: Fatura enviada automaticamente
Vencimento + 1 dia: Notificação push + email amigável
Vencimento + 3 dias: Notificação WhatsApp (se habilitado)
Vencimento + 7 dias: Email formal com valor dos juros calculados
Vencimento + 15 dias: SUSPENSÃO PARCIAL do acesso
Vencimento + 30 dias: CANCELAMENTO com preservação de dados (90 dias)
```

### 3.2 Suspensão parcial (D+15)

Após 15 dias de inadimplência, o acesso é limitado:
- **O que fica disponível**: Visualização de dados (somente leitura), exportação de histórico
- **O que é suspenso**: Lançamento de novas informações, emissão de documentos, envio de comunicados
- **Responsáveis são notificados**: Sim — eles perdem acesso ao app também

A suspensão é **automática** via webhook do Stripe (`invoice.payment_failed` + tempo decorrido).

A suspensão é **levantada automaticamente** assim que o pagamento é confirmado.

### 3.3 Cancelamento por inadimplência (D+30)

Após 30 dias sem pagamento:
- A assinatura é cancelada definitivamente
- Os dados da escola ficam preservados por **90 dias** adicionais
- A escola pode reativar pagando o valor em aberto + taxa de reativação (R$50)
- Após 90 dias sem reativação, os dados podem ser deletados (com aviso prévio de 15 dias)

### 3.4 Juros e multa

Para cobranças em atraso, aplicamos conforme Código Civil:
- **Multa**: 2% sobre o valor em atraso (aplicada no D+1)
- **Juros**: 1% ao mês (pro rata temporis)

Os juros são calculados automaticamente pelo sistema e exibidos na fatura de cobrança.

### 3.5 Negociação de dívidas

A escola pode solicitar parcelamento da dívida via email para financeiro@lexendscholar.com. Analisamos caso a caso, considerando:
- Histórico de pagamentos
- Tempo de relacionamento
- Motivo da inadimplência

**Aprovação necessária**: Co-founders.

---

## 4. Política de Descontos

### 4.1 Desconto máximo autorizado

**Regra**: O desconto máximo que pode ser concedido em qualquer negociação é de **20% sobre o preço de tabela**.

Descontos acima de 20% precisam de aprovação dos dois co-founders.

### 4.2 Tipos de desconto autorizados

| Tipo | Desconto Máximo | Duração | Aprovação |
|---|---|---|---|
| Escola piloto (early adopter) | 50% nos primeiros 6 meses | 6 meses | Fundadores |
| Desconto anual (já incluído no preço anual) | ~17% | Vigência do contrato | Automático |
| Desconto por indicação | 1 mês grátis por indicação convertida | 1 mês | Automático |
| Desconto comercial (negociação de vendas) | Até 20% | Contrato (máx 12 meses) | Vendas ou Founder |
| Desconto para ONG/escola pública | Até 50% | Anual, renovável | Co-founders |

### 4.3 O que NÃO pode ser descontado

- Taxa de reativação (R$50)
- Juros e multa de inadimplência (exceto negociação de dívida)
- Serviços de migração de dados premium

### 4.4 Documetação de descontos

Todo desconto concedido deve ser registrado:
- No CRM (HubSpot): campo "Desconto aplicado" com % e motivo
- No contrato: cláusula específica com valor, prazo e condição de manutenção
- No Stripe: configurar coupon com validade definida

---

## 5. Política de Cancelamento pelo Cliente

### 5.1 Como cancelar

O cliente pode cancelar por:
- Email para suporte@lexendscholar.com com assunto "Cancelamento — [Nome da Escola]"
- Chat de suporte no app

**Não há Customer Portal de cancelamento self-service** — o cancelamento requer contato humano (para entender o motivo e tentar recuperar o cliente).

### 5.2 Processo de cancelamento

1. Escola solicita cancelamento
2. Time de suporte confirma o recebimento em até 24h
3. Oferecer call de retenção (opcional, não forçado)
4. Processar o cancelamento no Stripe
5. Enviar email de confirmação com data de encerramento do acesso
6. Informar sobre prazo de preservação de dados (90 dias) e como exportar

### 5.3 Exportação de dados antes do cancelamento

Todo cliente que cancela tem direito a exportar todos os seus dados em formato CSV/Excel:
- Lista de alunos com todos os dados
- Histórico de frequência
- Histórico de notas
- Histórico financeiro

Solicitar via suporte — processado em até 2 dias úteis.

---

## Revisão das Políticas

- **Revisão anual**: Janeiro de cada ano
- **Revisão extraordinária**: Quando houver mudança regulatória relevante ou feedback significativo de clientes
- **Comunicação de mudanças**: Via email para todos os clientes com 30 dias de antecedência
