/**
 * Lexend Scholar — Stripe Billing Client
 * Gerencia customers, subscriptions e checkout sessions via Stripe API.
 *
 * Dependências: stripe npm package (stripe@^14)
 * Variáveis de ambiente necessárias:
 *   STRIPE_SECRET_KEY       — sk_live_... ou sk_test_...
 *   STRIPE_WEBHOOK_SECRET   — whsec_...
 *   SUPABASE_URL
 *   SUPABASE_SERVICE_KEY
 */

import Stripe from 'stripe';

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: '2024-04-10',
});

// ---------------------------------------------------------------------------
// Planos Lexend Scholar — Price IDs devem ser criados no Stripe Dashboard
// e configurados como variáveis de ambiente.
// ---------------------------------------------------------------------------
export const PLANS = {
  starter: {
    name: 'Starter',
    maxStudents: 100,
    priceMonthly: 29700,            // R$ 297,00 em centavos
    stripePriceId: process.env.STRIPE_PRICE_STARTER,
  },
  pro: {
    name: 'Pro',
    maxStudents: 500,
    priceMonthly: 69700,            // R$ 697,00
    stripePriceId: process.env.STRIPE_PRICE_PRO,
  },
  enterprise: {
    name: 'Enterprise',
    maxStudents: null,              // ilimitado
    priceMonthly: 149700,          // R$ 1.497,00
    stripePriceId: process.env.STRIPE_PRICE_ENTERPRISE,
  },
};

// ---------------------------------------------------------------------------
// createOrRetrieveCustomer
// Cria um Customer no Stripe para a escola e persiste no Supabase.
// ---------------------------------------------------------------------------
export async function createOrRetrieveCustomer({ supabase, schoolId, email, name }) {
  // Verifica se já existe customer
  const { data: school } = await supabase
    .from('schools')
    .select('stripe_customer_id')
    .eq('id', schoolId)
    .single();

  if (school?.stripe_customer_id) {
    return await stripe.customers.retrieve(school.stripe_customer_id);
  }

  // Cria novo customer no Stripe
  const customer = await stripe.customers.create({
    email,
    name,
    metadata: { school_id: schoolId },
  });

  // Persiste stripe_customer_id no Supabase
  await supabase
    .from('schools')
    .update({ stripe_customer_id: customer.id, updated_at: new Date().toISOString() })
    .eq('id', schoolId);

  return customer;
}

// ---------------------------------------------------------------------------
// createCheckoutSession
// Cria uma Checkout Session do Stripe com trial de 14 dias.
// ---------------------------------------------------------------------------
export async function createCheckoutSession({
  customerId,
  priceId,
  schoolId,
  successUrl,
  cancelUrl,
  trialDays = 14,
}) {
  const session = await stripe.checkout.sessions.create({
    customer: customerId,
    mode: 'subscription',
    payment_method_types: ['card'],
    line_items: [{ price: priceId, quantity: 1 }],
    subscription_data: {
      trial_period_days: trialDays,
      metadata: { school_id: schoolId },
    },
    success_url: successUrl,
    cancel_url: cancelUrl,
    locale: 'pt-BR',
    currency: 'brl',
    allow_promotion_codes: true,
    billing_address_collection: 'required',
    metadata: { school_id: schoolId },
  });

  return session;
}

// ---------------------------------------------------------------------------
// createBillingPortalSession
// Redireciona cliente ao portal Stripe para gerenciar assinatura.
// ---------------------------------------------------------------------------
export async function createBillingPortalSession({ customerId, returnUrl }) {
  const session = await stripe.billingPortal.sessions.create({
    customer: customerId,
    return_url: returnUrl,
  });
  return session;
}

// ---------------------------------------------------------------------------
// getSubscription
// Retorna dados completos da subscription.
// ---------------------------------------------------------------------------
export async function getSubscription(subscriptionId) {
  return await stripe.subscriptions.retrieve(subscriptionId, {
    expand: ['latest_invoice', 'customer'],
  });
}

// ---------------------------------------------------------------------------
// cancelSubscription
// Cancela ao fim do período atual (cancel_at_period_end = true).
// ---------------------------------------------------------------------------
export async function cancelSubscription(subscriptionId) {
  return await stripe.subscriptions.update(subscriptionId, {
    cancel_at_period_end: true,
  });
}
