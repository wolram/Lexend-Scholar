/**
 * Lexend Scholar — API endpoint: POST /api/billing/create-checkout
 *
 * Cria uma Stripe Checkout Session para a escola autenticada.
 * Framework-agnostic: exporta um handler que recebe (req, res).
 * Compatível com Express, Next.js API routes, Vercel Functions.
 */

import { createOrRetrieveCustomer, createCheckoutSession, PLANS } from './stripe_client.js';
import { createClient } from '@supabase/supabase-js';

function getSupabase() {
  return createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);
}

/**
 * POST /api/billing/create-checkout
 * Body: { plan: 'starter' | 'pro' | 'enterprise' }
 * Returns: { url: string } — URL da Stripe Checkout Session
 */
export async function createCheckoutHandler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // Obtém escola autenticada da sessão (adaptar conforme auth layer)
  const schoolId = req.session?.schoolId || req.headers['x-school-id'];
  if (!schoolId) {
    return res.status(401).json({ error: 'Não autenticado' });
  }

  const { plan } = req.body;
  if (!plan || !PLANS[plan]) {
    return res.status(400).json({ error: 'Plano inválido. Use: starter, pro ou enterprise' });
  }

  const supabase = getSupabase();

  // Busca dados da escola
  const { data: school, error: schoolErr } = await supabase
    .from('schools')
    .select('id, name, email, stripe_customer_id')
    .eq('id', schoolId)
    .single();

  if (schoolErr || !school) {
    return res.status(404).json({ error: 'Escola não encontrada' });
  }

  try {
    // Cria ou recupera customer no Stripe
    const customer = await createOrRetrieveCustomer({
      supabase,
      schoolId: school.id,
      email: school.email,
      name: school.name,
    });

    const baseUrl = process.env.APP_URL || 'https://app.lexendscholar.com.br';

    // Cria Checkout Session com 14 dias de trial
    const session = await createCheckoutSession({
      customerId: customer.id,
      priceId: PLANS[plan].stripePriceId,
      schoolId: school.id,
      successUrl: `${baseUrl}/billing/success?session_id={CHECKOUT_SESSION_ID}`,
      cancelUrl: `${baseUrl}/billing/checkout`,
      trialDays: 14,
    });

    return res.status(200).json({ url: session.url });
  } catch (err) {
    console.error('[Billing] createCheckout error:', err);
    return res.status(500).json({ error: 'Erro interno ao criar checkout' });
  }
}

/**
 * POST /api/billing/portal
 * Redireciona para o portal Stripe para gerenciar assinatura.
 */
export async function billingPortalHandler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const schoolId = req.session?.schoolId || req.headers['x-school-id'];
  if (!schoolId) return res.status(401).json({ error: 'Não autenticado' });

  const supabase = getSupabase();
  const { data: school } = await supabase
    .from('schools')
    .select('stripe_customer_id')
    .eq('id', schoolId)
    .single();

  if (!school?.stripe_customer_id) {
    return res.status(400).json({ error: 'Escola sem customer Stripe' });
  }

  const { createBillingPortalSession } = await import('./stripe_client.js');
  const baseUrl = process.env.APP_URL || 'https://app.lexendscholar.com.br';

  const portal = await createBillingPortalSession({
    customerId: school.stripe_customer_id,
    returnUrl: `${baseUrl}/settings/billing`,
  });

  return res.status(200).json({ url: portal.url });
}
