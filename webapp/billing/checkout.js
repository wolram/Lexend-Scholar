/**
 * Lexend Scholar — Checkout
 * Funções para criar sessões de checkout, customers, subscriptions e cancelamentos.
 *
 * Variáveis de ambiente:
 *   STARTER_PRICE_ID         — price_... do plano Starter
 *   PRO_PRICE_ID             — price_... do plano Pro
 *   ENTERPRISE_PRICE_ID      — price_... do plano Enterprise
 *   APP_URL                  — URL base da aplicação
 */

import { stripe } from './stripe_client.js';

const PRICE_IDS = {
  starter:    process.env.STARTER_PRICE_ID,
  pro:        process.env.PRO_PRICE_ID,
  enterprise: process.env.ENTERPRISE_PRICE_ID,
};

/**
 * createCheckoutSession
 * Cria uma Stripe Checkout Session para o plano selecionado.
 *
 * @param {string} schoolId — UUID da escola
 * @param {string} planId   — 'starter' | 'pro' | 'enterprise'
 * @returns {Promise<Stripe.Checkout.Session>}
 */
export async function createCheckoutSession(schoolId, planId) {
  const priceId = PRICE_IDS[planId];
  if (!priceId) {
    throw new Error(`Plano inválido: ${planId}. Use starter, pro ou enterprise.`);
  }

  const baseUrl = process.env.APP_URL || 'https://app.lexendscholar.com.br';

  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    payment_method_types: ['card'],
    payment_method_collection: 'if_required',
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: `${baseUrl}/billing/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url:  `${baseUrl}/billing/checkout`,
    locale: 'pt-BR',
    currency: 'brl',
    allow_promotion_codes: true,
    billing_address_collection: 'required',
    metadata: { school_id: schoolId },
    subscription_data: {
      metadata: { school_id: schoolId },
    },
  });

  return session;
}

/**
 * createCustomer
 * Cria um Customer no Stripe para a escola.
 *
 * @param {{ id: string, email: string, name: string }} school
 * @returns {Promise<Stripe.Customer>}
 */
export async function createCustomer(school) {
  const customer = await stripe.customers.create({
    email: school.email,
    name:  school.name,
    metadata: { school_id: school.id },
  });

  return customer;
}

/**
 * getSubscription
 * Busca subscription com latest_invoice expandido.
 *
 * @param {string} subscriptionId
 * @returns {Promise<Stripe.Subscription>}
 */
export async function getSubscription(subscriptionId) {
  return await stripe.subscriptions.retrieve(subscriptionId, {
    expand: ['latest_invoice'],
  });
}

/**
 * cancelSubscription
 * Cancela a subscription ao fim do período corrente.
 *
 * @param {string} subscriptionId
 * @returns {Promise<Stripe.Subscription>}
 */
export async function cancelSubscription(subscriptionId) {
  return await stripe.subscriptions.update(subscriptionId, {
    cancel_at_period_end: true,
  });
}
