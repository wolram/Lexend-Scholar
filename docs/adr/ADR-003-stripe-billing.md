# ADR-003 — Pagamentos e Assinaturas: Stripe Billing

| Campo      | Valor                       |
|------------|-----------------------------|
| **Status** | Aceito                      |
| **Data**   | 2026-04-12                  |
| **Autores** | Marlow Sousa               |
| **Issue**  | LS-141                      |

---

## Contexto

O Lexend Scholar é um produto SaaS B2B com modelo de assinatura recorrente mensal. Os requisitos de billing são:

- **Assinaturas recorrentes** mensais em BRL (Real Brasileiro)
- **Múltiplos planos** com preços diferentes (Starter, Pro, Enterprise)
- **Trial de 14 dias** sem cartão de crédito
- **Dunning automático** — retentativas de cobrança para cartões recusados com emails automáticos
- **Portal do cliente** — a escola precisa trocar cartão, ver faturas e cancelar sem depender do suporte
- **Webhooks confiáveis** para sincronizar status de assinatura com o banco interno
- **Cupons e descontos** para campanhas de aquisição (ex: TRIAL20)
- **Suporte a Pix** — método de pagamento crescente no mercado brasileiro

---

## Decisão

Adotar **Stripe Billing** como plataforma de pagamentos e gestão de assinaturas.

### Componentes Stripe Utilizados

| Componente               | Uso no Lexend Scholar                                    |
|--------------------------|----------------------------------------------------------|
| Stripe Checkout          | Tela de pagamento hosted — sem PCI compliance próprio    |
| Stripe Billing           | Assinaturas recorrentes, faturas, dunning automático     |
| Stripe Customer Portal   | Autoatendimento para troca de cartão, cancelamento       |
| Stripe Webhooks          | Sincronização de eventos com Supabase                    |
| Stripe Coupons           | Cupons de desconto (TRIAL20, parcerias)                  |
| Stripe Tax               | Cálculo automático de impostos (futuro)                  |

### Eventos Webhook Monitorados

```typescript
// Principais eventos a processar:
'customer.subscription.created'     // Trial iniciado
'customer.subscription.updated'     // Mudança de plano
'customer.subscription.deleted'     // Cancelamento / churn
'invoice.payment_succeeded'         // Pagamento confirmado
'invoice.payment_failed'            // Falha no pagamento (dunning)
'checkout.session.completed'        // Checkout finalizado
```

### Configuração de Dunning

No painel Stripe → Billing → Revenue Recovery:
- Retentativa 1: 3 dias após falha
- Retentativa 2: 7 dias após falha
- Retentativa 3: 15 dias após falha
- Email automático após cada falha (template customizado com branding Lexend Scholar)
- Suspender acesso após 21 dias de inadimplência (via webhook + flag no banco)

---

## Alternativas Consideradas e Descartadas

| Alternativa | Motivo de Descarte |
|-------------|-------------------|
| **Iugu** | Solução brasileira nativa com suporte robusto a Pix e boleto. API menos madura que a Stripe — documentação inconsistente, SDKs menos mantidos. Sem subscription management nativo comparável ao Stripe Billing. Customer Portal inexistente. |
| **Pagar.me** | Boa cobertura de meios de pagamento BR (Pix, boleto, cartão). Não tem subscription management nativo robusto — requer implementação manual de dunning e retentativas. Webhooks menos confiáveis historicamente. |
| **Mercado Pago** | Excelente para e-commerce, mas o produto de assinaturas recorrentes (Mercado Pago Subscriptions) tem limitações de customização e dunning menos sofisticado. Checkout tem menor taxa de conversão para B2B. |
| **Asaas** | Focado em cobranças avulsas e boleto. Sem checkout hosted completo para SaaS. |
| **Implementação própria** | Requer PCI compliance, manutenção de integrações com múltiplas adquirentes, gestão de retentativas — completamente fora do escopo do estágio atual. |

---

## Consequências

### Positivas

- **Dunning automático configurável:** recuperação passiva de receita sem código adicional.
- **Customer Portal pronto:** a escola gerencia sua assinatura de forma autônoma — reduz carga do suporte.
- **Webhooks confiáveis:** retry automático com backoff exponencial, log completo de eventos no painel Stripe.
- **Checkout hosted:** sem necessidade de PCI compliance próprio — Stripe assume a responsabilidade.
- **Ecossistema:** Stripe Radar (prevenção de fraude), Stripe Tax, Stripe Sigma (analytics) disponíveis quando necessário.

### Negativas / Riscos

- **Taxas:** ~3,4% + R$ 0,60 por transação com cartão nacional no plano padrão Stripe Brasil. Para um ticket de R$ 297 (Starter), isso representa ~R$ 10,70 por transação (~3,6%). Monitorar impacto nas margens.
- **Pix via Stripe:** o suporte a Pix no Stripe Brasil está em evolução. Considerar fallback via Iugu ou integração direta com banco para Pix enquanto o suporte não for completo.
- **Restrições de volume:** em alguns cenários, Stripe pode solicitar documentação adicional para volumes maiores. Manter documentos da empresa atualizados.

---

## Planos Configurados no Stripe

```
Produto: Lexend Scholar Starter
  Preço recorrente: R$ 297,00/mês (BRL)
  Trial: 14 dias

Produto: Lexend Scholar Pro
  Preço recorrente: R$ 697,00/mês (BRL)
  Trial: 14 dias

Produto: Lexend Scholar Enterprise
  Preço recorrente: R$ 1.497,00/mês (BRL)
  Trial: 14 dias
```

---

## Revisão

Esta decisão será reavaliada se:
- O volume de transações tornar as taxas da Stripe significativamente mais caras que alternativas BR
- Pix se tornar o método principal de pagamento e a Stripe não oferecer suporte adequado
- Regulamentações brasileiras exigirem processador nacional certificado pelo Banco Central
