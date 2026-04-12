/**
 * Lexend Scholar — Stripe Webhook Handler
 * Endpoint Express POST /webhooks/stripe
 *
 * Eventos tratados:
 *   invoice.payment_succeeded          — marcar subscription ativa, gerar recibo, enviar email
 *   invoice.payment_failed             — log de falha, enviar email de alerta para escola
 *   customer.subscription.deleted      — marcar escola como churn, iniciar offboarding
 *   customer.subscription.updated      — atualizar plano no banco (starter/pro/enterprise)
 *   customer.subscription.trial_will_end — enviar lembrete 3 dias antes do trial expirar
 *   customer.subscription.created      — marcar trial como iniciado
 *
 * Idempotência: verifica tabela stripe_webhook_events(event_id) antes de processar.
 * IMPORTANTE: usar raw body parser (não JSON) para verificação da assinatura Stripe.
 */

import express from 'express';
import { createClient } from '@supabase/supabase-js';
import { stripe } from './stripe_client.js';
import { generateReceipt, sendReceiptEmail } from './invoice.js';
import { sendTrialReminder } from './trial.js';

const router = express.Router();

function getSupabase() {
  return createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY
  );
}

// ---------------------------------------------------------------------------
// POST /webhooks/stripe
// ---------------------------------------------------------------------------
router.post('/', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  // 1. Verificar assinatura Stripe
  try {
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.error('[Webhook] Assinatura inválida:', err.message);
    return res.status(400).json({ error: `Webhook Error: ${err.message}` });
  }

  const supabase = getSupabase();

  // 2. Idempotência: checar se evento já foi processado
  const { data: existing } = await supabase
    .from('stripe_webhook_events')
    .select('id, processed')
    .eq('event_id', event.id)
    .maybeSingle();

  if (existing?.processed) {
    return res.status(200).json({ received: true, skipped: true });
  }

  // 3. Registrar evento no banco
  if (!existing) {
    await supabase.from('stripe_webhook_events').insert({
      event_id:   event.id,
      event_type: event.type,
      payload:    event,
      processed:  false,
    });
  }

  let processingError = null;

  try {
    await routeEvent(event, supabase);
  } catch (err) {
    console.error(`[Webhook] Erro ao processar ${event.type}:`, err);
    processingError = err.message;
  }

  // 4. Marcar como processado
  await supabase
    .from('stripe_webhook_events')
    .update({ processed: true, error: processingError })
    .eq('event_id', event.id);

  return res.status(200).json({ received: true });
});

// ---------------------------------------------------------------------------
// routeEvent — despacha para handlers específicos
// ---------------------------------------------------------------------------
async function routeEvent(event, supabase) {
  const data = event.data.object;

  switch (event.type) {
    // Pagamento bem-sucedido: ativar subscription, gerar recibo e enviar email
    case 'invoice.payment_succeeded':
      await handlePaymentSucceeded(data, supabase);
      break;

    // Falha no pagamento: log + email de alerta com link do portal
    case 'invoice.payment_failed':
      await handlePaymentFailed(data, supabase);
      break;

    // Subscription cancelada: marcar escola como churn + offboarding
    case 'customer.subscription.deleted':
      await handleSubscriptionDeleted(data, supabase);
      break;

    // Plano atualizado: atualizar starter/pro/enterprise no banco
    case 'customer.subscription.updated':
      await handleSubscriptionUpdated(data, supabase);
      break;

    // Trial prestes a expirar: enviar lembrete 3 dias antes
    case 'customer.subscription.trial_will_end':
      await handleTrialWillEnd(data, supabase);
      break;

    // Nova subscription criada: marcar trial como iniciado
    case 'customer.subscription.created':
      await handleSubscriptionCreated(data, supabase);
      break;

    default:
      console.log(`[Webhook] Evento não tratado: ${event.type}`);
  }
}

// ---------------------------------------------------------------------------
// Handlers individuais
// ---------------------------------------------------------------------------

async function handlePaymentSucceeded(invoice, supabase) {
  // Buscar escola pelo stripe_customer_id
  const { data: school } = await supabase
    .from('schools')
    .select('id, name, email, plan, subscription_status')
    .eq('stripe_customer_id', invoice.customer)
    .single();

  if (!school) {
    console.warn(`[Webhook] handlePaymentSucceeded: escola não encontrada para customer ${invoice.customer}`);
    return;
  }

  // Marcar subscription como ativa
  await supabase.from('schools').update({
    subscription_status: 'active',
    updated_at: new Date().toISOString(),
  }).eq('id', school.id);

  // Registrar invoice no banco
  await supabase.from('billing_invoices').upsert({
    school_id:             school.id,
    stripe_invoice_id:     invoice.id,
    stripe_payment_intent: invoice.payment_intent,
    amount_due:            invoice.amount_due,
    amount_paid:           invoice.amount_paid,
    currency:              invoice.currency,
    status:                'paid',
    invoice_url:           invoice.hosted_invoice_url || null,
    invoice_pdf:           invoice.invoice_pdf || null,
    period_start:          invoice.period_start
      ? new Date(invoice.period_start * 1000).toISOString() : null,
    period_end:            invoice.period_end
      ? new Date(invoice.period_end * 1000).toISOString() : null,
    paid_at:               new Date().toISOString(),
    updated_at:            new Date().toISOString(),
  }, { onConflict: 'stripe_invoice_id' });

  // Gerar recibo e enviar email
  if (invoice.payment_intent) {
    try {
      const paymentIntent = await stripe.paymentIntents.retrieve(
        typeof invoice.payment_intent === 'string'
          ? invoice.payment_intent
          : invoice.payment_intent.id,
        { expand: ['customer', 'invoice.subscription'] }
      );

      const receipt = generateReceipt(paymentIntent);
      const emailData = sendReceiptEmail(school.email, receipt);

      // TODO: enviar via provedor SMTP/SES configurado
      console.log(`[Webhook] Recibo gerado para ${school.name}:`, emailData.subject);
    } catch (err) {
      console.error('[Webhook] Erro ao gerar recibo:', err.message);
    }
  }

  console.log(`[Webhook] Pagamento confirmado — escola: ${school.name}, invoice: ${invoice.id}`);
}

async function handlePaymentFailed(invoice, supabase) {
  console.error(`[Webhook] Falha de pagamento — invoice: ${invoice.id}, customer: ${invoice.customer}`);

  const { data: school } = await supabase
    .from('schools')
    .select('id, name, email, stripe_customer_id')
    .eq('stripe_customer_id', invoice.customer)
    .single();

  if (!school) return;

  await supabase.from('schools').update({
    subscription_status: 'past_due',
    updated_at: new Date().toISOString(),
  }).eq('id', school.id);

  // Gerar link do portal Stripe para regularização
  const appUrl = process.env.APP_URL || 'https://app.lexendscholar.com.br';

  // TODO: enviar email de alerta
  console.log(`[Webhook] Email de alerta para ${school.email} — regularizar pagamento em ${appUrl}/billing`);
}

async function handleSubscriptionDeleted(subscription, supabase) {
  const { data: school } = await supabase
    .from('schools')
    .select('id, name, email')
    .eq('stripe_customer_id', subscription.customer)
    .single();

  if (!school) return;

  // Marcar como churn
  await supabase.from('schools').update({
    subscription_status:    'canceled',
    stripe_subscription_id: null,
    updated_at:             new Date().toISOString(),
  }).eq('id', school.id);

  // Iniciar fluxo de offboarding — email com link para exportar dados
  const appUrl = process.env.APP_URL || 'https://app.lexendscholar.com.br';

  // TODO: enviar email de offboarding
  console.log(`[Webhook] Churn registrado — escola: ${school.name}. Offboarding email para ${school.email}, exportar dados em ${appUrl}/export`);
}

async function handleSubscriptionUpdated(subscription, supabase) {
  const priceId = subscription.items?.data?.[0]?.price?.id;
  const plan    = getPlanFromPriceId(priceId);

  const { data: school } = await supabase
    .from('schools')
    .select('id')
    .eq('stripe_customer_id', subscription.customer)
    .single();

  if (!school) return;

  await supabase.from('schools').update({
    plan,
    stripe_price_id:        priceId,
    subscription_status:    subscription.status,
    current_period_start:   new Date(subscription.current_period_start * 1000).toISOString(),
    current_period_end:     new Date(subscription.current_period_end * 1000).toISOString(),
    updated_at:             new Date().toISOString(),
  }).eq('id', school.id);

  console.log(`[Webhook] Subscription atualizada — escola: ${school.id}, plano: ${plan}`);
}

async function handleTrialWillEnd(subscription, supabase) {
  const { data: school } = await supabase
    .from('schools')
    .select('id, name, email')
    .eq('stripe_customer_id', subscription.customer)
    .single();

  if (!school) return;

  // Trial encerra em 3 dias — enviar lembrete
  const reminder = sendTrialReminder(school.email, school.name, 3);

  // TODO: enviar via provedor SMTP/SES
  console.log(`[Webhook] Lembrete de trial para ${school.email}:`, reminder.subject);
}

async function handleSubscriptionCreated(subscription, supabase) {
  const { data: school } = await supabase
    .from('schools')
    .select('id')
    .eq('stripe_customer_id', subscription.customer)
    .single();

  if (!school) return;

  const isTrialing = subscription.status === 'trialing';

  await supabase.from('schools').update({
    stripe_subscription_id: subscription.id,
    subscription_status:    subscription.status,
    trial_ends_at: isTrialing && subscription.trial_end
      ? new Date(subscription.trial_end * 1000).toISOString()
      : null,
    current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
    current_period_end:   new Date(subscription.current_period_end * 1000).toISOString(),
    updated_at:           new Date().toISOString(),
  }).eq('id', school.id);

  console.log(`[Webhook] Subscription criada para escola ${school.id} — trial: ${isTrialing}`);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function getPlanFromPriceId(priceId) {
  if (priceId === process.env.ENTERPRISE_PRICE_ID) return 'enterprise';
  if (priceId === process.env.PRO_PRICE_ID)        return 'pro';
  return 'starter';
}

export default router;
