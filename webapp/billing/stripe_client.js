/**
 * Lexend Scholar — Stripe Client
 * Inicialização da instância Stripe com a secret key via variável de ambiente.
 *
 * Dependências: stripe npm package (stripe@^14)
 * Variáveis de ambiente necessárias:
 *   STRIPE_SECRET_KEY        — sk_live_... ou sk_test_...
 *   STARTER_PRICE_ID         — price_... do plano Starter
 *   PRO_PRICE_ID             — price_... do plano Pro
 *   ENTERPRISE_PRICE_ID      — price_... do plano Enterprise
 *   STRIPE_WEBHOOK_SECRET    — whsec_...
 */

import Stripe from 'stripe';

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: '2024-06-20',
});

export default stripe;
