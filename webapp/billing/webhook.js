/**
 * Lexend Scholar — Stripe Webhook Handler
 * POST /api/billing/webhook
 *
 * Eventos tratados:
 *   checkout.session.completed      — subscription iniciada (trial ou paga)
 *   customer.subscription.updated   — upgrade/downgrade de plano ou mudança de status
 *   customer.subscription.deleted   — cancelamento efetivado
 *   invoice.paid                    — pagamento bem-sucedido
 *   invoice.payment_failed          — falha no pagamento
 *   invoice.created                 — nova invoice gerada
 *
 * Idempotência: cada evento é registrado em stripe_webhook_events.
 * Se event_id já existe e processed=true, o evento é ignorado.
 */

import Stripe from 'stripe';
import { createClient } from '@supabase/supabase-js';
import { syncInvoiceFromStripe } from './invoice.js';
import { PLANS } from './stripe_client.js';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, { apiVersion: '2024-04-10' });

function getSupabase() {
  return createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);
}

// ---------------------------------------------------------------------------
// webhookHandler — entry point
// Express/Next.js: use raw body parser (NOT json) for Stripe signature verification.
// ---------------------------------------------------------------------------
export async function webhookHandler(req, res) {
  if (req.method !== 'POST') return res.status(405).end();

  const sig = req.headers['stripe-signature'];
  let event;

  try {
    // req.body must be raw Buffer for signature verification
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.error('[Webhook] Signature verification failed:', err.message);
    return res.status(400).json({ error: `Webhook Error: ${err.message}` });
  }

  const supabase = getSupabase();

  // --- Idempotency check ---
  const { data: existing } = await supabase
    .from('stripe_webhook_events')
    .select('id, processed')
    .eq('event_id', event.id)
    .maybeSingle();

  if (existing?.processed) {
    return res.status(200).json({ received: true, skipped: true });
  }

  // --- Log event ---
  if (!existing) {
    await supabase.from('stripe_webhook_events').insert({
      event_id: event.id,
      event_type: event.type,
      payload: event,
      processed: false,
    });
  }

  let processingError = null;

  try {
    await routeEvent(event, supabase);
  } catch (err) {
    console.error(`[Webhook] Error processing ${event.type}:`, err);
    processingError = err.message;
  }

  // Mark as processed (even if error — to avoid infinite retries on bad data)
  await supabase
    .from('stripe_webhook_events')
    .update({ processed: true, error: processingError })
    .eq('event_id', event.id);

  if (processingError) {
    return res.status(200).json({ received: true, error: processingError });
  }

  return res.status(200).json({ received: true });
}

// ---------------------------------------------------------------------------
// routeEvent — dispatches to specific handlers
// ---------------------------------------------------------------------------
async function routeEvent(event, supabase) {
  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckoutCompleted(event.data.object, supabase);
      break;

    case 'customer.subscription.updated':
      await handleSubscriptionUpdated(event.data.object, supabase);
      break;

    case 'customer.subscription.deleted':
      await handleSubscriptionDeleted(event.data.object, supabase);
      break;

    case 'invoice.paid':
      await handleInvoicePaid(event.data.object, supabase);
      break;

    case 'invoice.payment_failed':
      await handleInvoicePaymentFailed(event.data.object, supabase);
      break;

    case 'invoice.created':
      await syncInvoiceFromStripe(event.data.object);
      break;

    default:
      console.log(`[Webhook] Unhandled event type: ${event.type}`);
  }
}

// ---------------------------------------------------------------------------
// handleCheckoutCompleted
// Atualiza escola com subscription_id, status e plano.
// ---------------------------------------------------------------------------
async function handleCheckoutCompleted(session, supabase) {
  if (session.mode !== 'subscription') return;

  const schoolId = session.metadata?.school_id;
  if (!schoolId) throw new Error('checkout.session.completed: missing school_id in metadata');

  const subscription = await stripe.subscriptions.retrieve(session.subscription);
  const priceId = subscription.items.data[0]?.price?.id;
  const plan = getPlanFromPriceId(priceId);

  await supabase.from('schools').update({
    stripe_subscription_id: subscription.id,
    stripe_price_id: priceId,
    plan,
    max_students: PLANS[plan]?.maxStudents ?? 100,
    subscription_status: subscription.status,
    current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
    current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
    trial_ends_at: subscription.trial_end
      ? new Date(subscription.trial_end * 1000).toISOString()
      : null,
    updated_at: new Date().toISOString(),
  }).eq('id', schoolId);

  console.log(`[Webhook] Checkout completed for school ${schoolId}, plan ${plan}`);
}

// ---------------------------------------------------------------------------
// handleSubscriptionUpdated
// ---------------------------------------------------------------------------
async function handleSubscriptionUpdated(subscription, supabase) {
  const customerId = subscription.customer;
  const { data: school } = await supabase
    .from('schools')
    .select('id')
    .eq('stripe_customer_id', customerId)
    .single();

  if (!school) throw new Error(`No school for customer ${customerId}`);

  const priceId = subscription.items.data[0]?.price?.id;
  const plan = getPlanFromPriceId(priceId);

  await supabase.from('schools').update({
    stripe_subscription_id: subscription.id,
    stripe_price_id: priceId,
    plan,
    max_students: PLANS[plan]?.maxStudents ?? 100,
    subscription_status: subscription.status,
    current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
    current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
    trial_ends_at: subscription.trial_end
      ? new Date(subscription.trial_end * 1000).toISOString()
      : null,
    updated_at: new Date().toISOString(),
  }).eq('id', school.id);

  console.log(`[Webhook] Subscription updated for school ${school.id}, status ${subscription.status}`);
}

// ---------------------------------------------------------------------------
// handleSubscriptionDeleted
// ---------------------------------------------------------------------------
async function handleSubscriptionDeleted(subscription, supabase) {
  const customerId = subscription.customer;
  const { data: school } = await supabase
    .from('schools')
    .select('id')
    .eq('stripe_customer_id', customerId)
    .single();

  if (!school) throw new Error(`No school for customer ${customerId}`);

  await supabase.from('schools').update({
    subscription_status: 'canceled',
    stripe_subscription_id: null,
    updated_at: new Date().toISOString(),
  }).eq('id', school.id);

  console.log(`[Webhook] Subscription canceled for school ${school.id}`);
}

// ---------------------------------------------------------------------------
// handleInvoicePaid
// ---------------------------------------------------------------------------
async function handleInvoicePaid(invoice, supabase) {
  // Sync invoice data to Supabase
  await syncInvoiceFromStripe(invoice);

  // If the invoice is for a subscription, ensure school status is 'active'
  if (invoice.subscription) {
    const { data: school } = await supabase
      .from('schools')
      .select('id, subscription_status')
      .eq('stripe_customer_id', invoice.customer)
      .single();

    if (school && school.subscription_status !== 'active') {
      await supabase.from('schools').update({
        subscription_status: 'active',
        updated_at: new Date().toISOString(),
      }).eq('id', school.id);
    }
  }

  console.log(`[Webhook] Invoice paid: ${invoice.id}`);
}

// ---------------------------------------------------------------------------
// handleInvoicePaymentFailed
// ---------------------------------------------------------------------------
async function handleInvoicePaymentFailed(invoice, supabase) {
  await syncInvoiceFromStripe(invoice);

  const { data: school } = await supabase
    .from('schools')
    .select('id')
    .eq('stripe_customer_id', invoice.customer)
    .single();

  if (school) {
    await supabase.from('schools').update({
      subscription_status: 'past_due',
      updated_at: new Date().toISOString(),
    }).eq('id', school.id);
  }

  console.warn(`[Webhook] Invoice payment FAILED: ${invoice.id} for customer ${invoice.customer}`);
}

// ---------------------------------------------------------------------------
// getPlanFromPriceId — mapeia price_id Stripe → plano interno
// ---------------------------------------------------------------------------
function getPlanFromPriceId(priceId) {
  const { STRIPE_PRICE_STARTER, STRIPE_PRICE_PRO, STRIPE_PRICE_ENTERPRISE } = process.env;
  if (priceId === STRIPE_PRICE_ENTERPRISE) return 'enterprise';
  if (priceId === STRIPE_PRICE_PRO) return 'pro';
  return 'starter';
}
