/**
 * Lexend Scholar — Trial Gratuito de 14 dias
 *
 * Gerencia o ciclo de vida do trial:
 *   - startTrial: cria subscription Stripe com trial de 14 dias
 *   - checkTrialStatus: retorna status atual do trial
 *   - sendTrialReminder: gera objeto de email de lembrete (D-3 e D-1)
 *
 * Não exige cartão no cadastro inicial:
 *   payment_method_collection: 'if_required' na Checkout Session.
 */

import { stripe } from './stripe_client.js';

export const TRIAL_DAYS = 14;

/**
 * startTrial
 * Cria subscription no Stripe com período de trial de 14 dias.
 * Não exige cartão imediatamente (default_incomplete + if_required).
 *
 * @param {string} customerId — Stripe customer ID (cus_xxx)
 * @param {string} planId     — price ID do plano selecionado
 * @returns {Promise<Stripe.Subscription>}
 */
export async function startTrial(customerId, planId) {
  const subscription = await stripe.subscriptions.create({
    customer:         customerId,
    items:            [{ price: planId }],
    trial_period_days: TRIAL_DAYS,
    payment_behavior: 'default_incomplete',
    expand:           ['latest_invoice.payment_intent'],
    payment_settings: {
      save_default_payment_method: 'on_subscription',
    },
  });

  return subscription;
}

/**
 * checkTrialStatus
 * Retorna informações do trial a partir da subscription Stripe.
 *
 * @param {string} subscriptionId
 * @returns {Promise<{ isTrialing: boolean, daysLeft: number, endsAt: Date|null }>}
 */
export async function checkTrialStatus(subscriptionId) {
  const subscription = await stripe.subscriptions.retrieve(subscriptionId);

  const isTrialing = subscription.status === 'trialing';
  const trialEnd   = subscription.trial_end
    ? new Date(subscription.trial_end * 1000)
    : null;

  const daysLeft = trialEnd
    ? Math.max(0, Math.ceil((trialEnd - new Date()) / (1000 * 60 * 60 * 24)))
    : 0;

  return {
    isTrialing,
    daysLeft,
    endsAt: trialEnd,
  };
}

/**
 * sendTrialReminder
 * Gera objeto de email de lembrete adaptado para D-3 e D-1.
 *
 * @param {string} email
 * @param {string} schoolName
 * @param {number} daysLeft — 3 ou 1
 * @returns {{ to: string, subject: string, html: string }}
 */
export function sendTrialReminder(email, schoolName, daysLeft) {
  const urgencyMap = {
    3: {
      subject: `⚠️ Seu trial Lexend Scholar encerra em 3 dias — ${schoolName}`,
      heading: 'Faltam apenas 3 dias para o fim do seu trial!',
      body: `Aproveite os últimos dias para explorar todos os recursos do Lexend Scholar.
Assine agora e garanta continuidade sem interrupções. Planos a partir de R$ 297/mês.`,
      cta: 'Escolher meu plano',
    },
    1: {
      subject: `🚨 Último dia do seu trial Lexend Scholar — ${schoolName}`,
      heading: 'Seu trial encerra HOJE!',
      body: `Não perca o acesso ao sistema. Assine agora para continuar gerenciando
${schoolName} sem perder nenhum dado. Leva menos de 2 minutos.`,
      cta: 'Assinar agora',
    },
  };

  const content = urgencyMap[daysLeft] || urgencyMap[3];
  const appUrl  = process.env.APP_URL || 'https://app.lexendscholar.com.br';

  return {
    to:      email,
    subject: content.subject,
    html: `<!DOCTYPE html>
<html lang="pt-BR">
<body style="font-family: sans-serif; color: #1a1a1a; background: #f5f5f5; padding: 24px;">
  <div style="max-width: 560px; margin: 0 auto; background: #fff; border-radius: 8px; padding: 32px;">
    <img src="${appUrl}/logo.png" alt="Lexend Scholar" style="height: 40px; margin-bottom: 24px;" />
    <h2 style="color: #1E3A5F;">${content.heading}</h2>
    <p>Olá, equipe <strong>${schoolName}</strong>!</p>
    <p style="line-height: 1.6;">${content.body}</p>
    <a href="${appUrl}/billing/checkout"
       style="display: inline-block; margin-top: 16px; padding: 12px 24px;
              background: #1E3A5F; color: #fff; border-radius: 6px;
              text-decoration: none; font-weight: bold;">
      ${content.cta}
    </a>
    <p style="margin-top: 32px; font-size: 12px; color: #999;">
      Dúvidas? Fale conosco pelo WhatsApp ou email suporte@lexendscholar.com.br
    </p>
  </div>
</body>
</html>`,
  };
}
