# Configuração do Stripe para SaaS B2B — Lexend Scholar

**Versão**: 1.0
**Owner**: Engenharia / Financeiro
**Última atualização**: Abril 2026

---

## Visão Geral

Este documento descreve a configuração completa do Stripe para assinaturas B2B do Lexend Scholar. O modelo é: escola assina um plano mensal (SaaS) baseado no número de alunos, pago via cartão de crédito, boleto ou PIX.

**Stack de pagamentos:**
- **Stripe**: Cartão de crédito, Link, assinaturas recorrentes
- **Boleto/PIX**: Via Stripe (suporte nativo a boleto BR e PIX desde 2022)
- **NFS-e**: Via NFE.io com webhook do Stripe (ver `contabilidade-nfe.md`)

---

## Passo 1: Criar Conta e Configurar Conta Stripe

### 1.1 Criar conta
1. Acesse [stripe.com/br](https://stripe.com/br)
2. Criar conta com email corporativo (@lexendscholar.com)
3. Ativar conta para produção: submeter documentos da empresa (CNPJ, endereço, dados dos sócios)
4. Aguardar aprovação (normalmente 1-3 dias úteis)

### 1.2 Configurações básicas da conta
Em **Settings → Business settings**:

- **Nome do negócio**: Lexend Scholar Ltda.
- **URL do negócio**: lexendscholar.com
- **Descrição**: Software de gestão escolar SaaS
- **Categoria do negócio**: Software as a Service (NAICS: 511210)
- **Moeda padrão**: BRL (Real Brasileiro)

Em **Settings → Customer emails**:
- Ativar: "Send emails for successful payments"
- Ativar: "Send emails for failed payments"
- Personalizar with logo e cores da marca

---

## Passo 2: Criar Produtos e Preços

### 2.1 Produto: Lexend Scholar Basic

```bash
# Via Stripe CLI:
stripe products create \
  --name="Lexend Scholar Basic" \
  --description="Gestão escolar para até 150 alunos. Módulos: Acadêmico, Frequência, Comunicação, Secretaria." \
  --metadata[tier]="basic" \
  --metadata[max_students]="150"

# Criar preço mensal:
stripe prices create \
  --product=prod_XXXX \
  --unit-amount=19700 \
  --currency=brl \
  --recurring[interval]=month \
  --nickname="Basic Mensal"

# Criar preço anual (2 meses grátis):
stripe prices create \
  --product=prod_XXXX \
  --unit-amount=197000 \
  --currency=brl \
  --recurring[interval]=year \
  --nickname="Basic Anual"
```

### 2.2 Produto: Lexend Scholar Pro

```bash
stripe products create \
  --name="Lexend Scholar Pro" \
  --description="Gestão escolar completa para até 500 alunos. Inclui módulo financeiro, relatórios avançados e suporte prioritário." \
  --metadata[tier]="pro" \
  --metadata[max_students]="500"

stripe prices create \
  --product=prod_XXXX \
  --unit-amount=39700 \
  --currency=brl \
  --recurring[interval]=month \
  --nickname="Pro Mensal"

stripe prices create \
  --product=prod_XXXX \
  --unit-amount=397000 \
  --currency=brl \
  --recurring[interval]=year \
  --nickname="Pro Anual"
```

### 2.3 Produto: Lexend Scholar Enterprise

```bash
stripe products create \
  --name="Lexend Scholar Enterprise" \
  --description="Para redes de ensino com 500+ alunos. Preço customizado, CSM dedicado, SLA garantido." \
  --metadata[tier]="enterprise"

# Enterprise: preço customizado por cotação
# Criar price manualmente para cada cliente via API
```

### 2.4 Add-on: Usuários Adicionais

```bash
# Cobrado por usuário acima do limite do plano
stripe prices create \
  --product=prod_addon_users \
  --unit-amount=1990 \
  --currency=brl \
  --recurring[interval]=month \
  --recurring[usage_type]=licensed \
  --nickname="Usuário Adicional"
```

---

## Passo 3: Configurar Métodos de Pagamento

### 3.1 Habilitar PIX e Boleto
Em **Settings → Payment methods**:
1. Habilitar **PIX** (exige CNPJ brasileiro e conta bancária BR verificada)
2. Habilitar **Boleto Bancário**
3. Manter **Cartões de crédito/débito** ativo

### 3.2 Configurar PIX
- **Expiration**: 24 horas (padrão)
- **Statement descriptor**: LEXEND SCHOLAR

### 3.3 Configurar Boleto
- **Expiration**: 7 dias úteis (recomendado para B2B)
- Habilitar notificação de vencimento próximo

---

## Passo 4: Configurar Webhook Endpoint

### 4.1 Criar endpoint de webhook

```bash
# Via Stripe CLI em desenvolvimento:
stripe listen --forward-to localhost:3000/api/webhooks/stripe

# Em produção, criar via dashboard ou API:
stripe webhook_endpoints create \
  --url="https://api.lexendscholar.com/api/webhooks/stripe" \
  --enabled_events="checkout.session.completed,customer.subscription.created,customer.subscription.updated,customer.subscription.deleted,invoice.payment_succeeded,invoice.payment_failed,invoice.finalized"
```

### 4.2 Eventos para escutar

| Evento | Ação no sistema |
|---|---|
| `checkout.session.completed` | Criar escola, ativar assinatura |
| `customer.subscription.created` | Registrar assinatura, enviar email de boas-vindas |
| `customer.subscription.updated` | Atualizar plano da escola (upgrade/downgrade) |
| `customer.subscription.deleted` | Suspender acesso da escola |
| `invoice.payment_succeeded` | Registrar pagamento, emitir NFS-e via NFE.io |
| `invoice.payment_failed` | Iniciar fluxo de inadimplência, notificar cliente |
| `invoice.finalized` | Registrar invoice no sistema |

### 4.3 Handler de webhook (Next.js / Node.js)

```typescript
// app/api/webhooks/stripe/route.ts
import { NextRequest, NextResponse } from 'next/server';
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!;

export async function POST(req: NextRequest) {
  const body = await req.text();
  const signature = req.headers.get('stripe-signature')!;

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err);
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  try {
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session;
        await handleCheckoutCompleted(session);
        break;
      }
      case 'customer.subscription.deleted': {
        const subscription = event.data.object as Stripe.Subscription;
        await handleSubscriptionCanceled(subscription);
        break;
      }
      case 'invoice.payment_succeeded': {
        const invoice = event.data.object as Stripe.Invoice;
        await handlePaymentSucceeded(invoice);
        break;
      }
      case 'invoice.payment_failed': {
        const invoice = event.data.object as Stripe.Invoice;
        await handlePaymentFailed(invoice);
        break;
      }
    }
  } catch (err) {
    console.error('Error processing webhook:', err);
    return NextResponse.json({ error: 'Processing error' }, { status: 500 });
  }

  return NextResponse.json({ received: true });
}

async function handlePaymentSucceeded(invoice: Stripe.Invoice) {
  const schoolId = invoice.metadata?.school_id;
  if (!schoolId) return;

  // Registrar pagamento no banco
  await db.payments.create({
    schoolId,
    stripeInvoiceId: invoice.id,
    amount: invoice.amount_paid / 100, // converter de centavos
    currency: invoice.currency.toUpperCase(),
    paidAt: new Date(invoice.status_transitions.paid_at! * 1000),
    status: 'paid'
  });

  // Emitir NFS-e via NFE.io
  await emitNFSe(schoolId, invoice);
}
```

---

## Passo 5: Testar com Stripe CLI

### 5.1 Instalar Stripe CLI

```bash
# macOS com Homebrew
brew install stripe/stripe-cli/stripe

# Login
stripe login

# Verificar versão
stripe version
```

### 5.2 Teste de fluxo completo

```bash
# Terminal 1: Escutar webhooks localmente
stripe listen --forward-to localhost:3000/api/webhooks/stripe

# Terminal 2: Simular eventos

# Simular pagamento bem-sucedido
stripe trigger invoice.payment_succeeded

# Simular falha de pagamento
stripe trigger invoice.payment_failed

# Simular cancelamento de assinatura
stripe trigger customer.subscription.deleted

# Simular checkout completo
stripe trigger checkout.session.completed
```

### 5.3 Cartões de teste

| Cenário | Número do Cartão |
|---|---|
| Pagamento aprovado | 4242 4242 4242 4242 |
| Cartão recusado | 4000 0000 0000 0002 |
| Autenticação necessária | 4000 0025 0000 3155 |
| Insuficiente saldo | 4000 0000 0000 9995 |

Use qualquer CVV (3 dígitos) e data futura.

---

## Passo 6: Configurar Customer Portal

O Customer Portal permite que escolas gerenciem a assinatura de forma self-service.

### 6.1 Configurar no dashboard

Em **Settings → Billing → Customer portal**:

- **Permitir cancelamento**: Não (requer contato com suporte — reduz churn)
- **Permitir upgrade/downgrade de plano**: Sim
- **Permitir atualizar método de pagamento**: Sim
- **Permitir download de faturas**: Sim
- **URL de retorno após o portal**: `https://app.lexendscholar.com/configuracoes/plano`
- **Headline**: "Gerenciar sua assinatura Lexend Scholar"

### 6.2 Criar link para o portal

```typescript
// Endpoint para redirecionar para o Customer Portal
async function createPortalSession(customerId: string) {
  const session = await stripe.billingPortal.sessions.create({
    customer: customerId,
    return_url: 'https://app.lexendscholar.com/configuracoes/plano',
  });
  return session.url;
}
```

---

## Passo 7: Configurar Trial Gratuito

Para o trial de 14 dias sem cartão de crédito:

```typescript
// Criar assinatura com trial
const subscription = await stripe.subscriptions.create({
  customer: customerId,
  items: [{ price: priceId }],
  trial_period_days: 14,
  trial_settings: {
    end_behavior: {
      missing_payment_method: 'cancel' // cancela se não cadastrar cartão
    }
  },
  payment_settings: {
    save_default_payment_method: 'on_subscription',
    payment_method_types: ['card', 'boleto', 'pix']
  }
});
```

---

## Variáveis de Ambiente Necessárias

```env
# .env.local (desenvolvimento)
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Stripe Product/Price IDs
STRIPE_PRICE_BASIC_MONTHLY=price_...
STRIPE_PRICE_BASIC_ANNUAL=price_...
STRIPE_PRICE_PRO_MONTHLY=price_...
STRIPE_PRICE_PRO_ANNUAL=price_...

# .env.production
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

---

## Checklist de Go-Live

- [ ] Conta Stripe verificada e ativa para produção
- [ ] PIX e Boleto habilitados e testados
- [ ] Produtos e preços criados em produção
- [ ] Webhook endpoint configurado em produção com eventos corretos
- [ ] Handler de webhook testado com Stripe CLI em staging
- [ ] Customer Portal configurado e testado
- [ ] Trial de 14 dias funcionando corretamente
- [ ] Notificações de pagamento enviadas aos clientes
- [ ] Integração com NFE.io para emissão de NFS-e testada
- [ ] Dashboard financeiro interno mostrando dados do Stripe
