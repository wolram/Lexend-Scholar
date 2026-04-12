/**
 * Lexend Scholar — Trial Gratuito de 14 dias
 *
 * Gerencia o ciclo de vida do trial:
 *   - Ativação automática ao criar escola
 *   - Verificação de trial ativo
 *   - Notificações de expiração (D-7, D-3, D-1)
 *   - Bloqueio após expiração sem assinatura
 *
 * As colunas usadas em `schools`:
 *   subscription_status   ENUM trialing|active|past_due|canceled|unpaid
 *   trial_ends_at         TIMESTAMPTZ
 *   stripe_subscription_id TEXT
 */

import { createClient } from '@supabase/supabase-js';

function getSupabase() {
  return createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY
  );
}

export const TRIAL_DAYS = 14;

// ---------------------------------------------------------------------------
// activateTrial
// Chamado ao registrar uma nova escola. Define trial_ends_at e status trialing.
// ---------------------------------------------------------------------------
export async function activateTrial(schoolId) {
  const supabase = getSupabase();

  const trialEndsAt = new Date();
  trialEndsAt.setDate(trialEndsAt.getDate() + TRIAL_DAYS);

  const { data, error } = await supabase
    .from('schools')
    .update({
      subscription_status: 'trialing',
      trial_ends_at: trialEndsAt.toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', schoolId)
    .select('id, name, email, trial_ends_at')
    .single();

  if (error) throw new Error(`activateTrial failed: ${error.message}`);
  return data;
}

// ---------------------------------------------------------------------------
// getTrialStatus
// Retorna informações do trial para exibir no dashboard.
// ---------------------------------------------------------------------------
export async function getTrialStatus(schoolId) {
  const supabase = getSupabase();

  const { data: school, error } = await supabase
    .from('schools')
    .select('subscription_status, trial_ends_at, stripe_subscription_id, plan')
    .eq('id', schoolId)
    .single();

  if (error || !school) throw new Error('Escola não encontrada');

  const now = new Date();
  const trialEnd = school.trial_ends_at ? new Date(school.trial_ends_at) : null;

  const isTrialing = school.subscription_status === 'trialing';
  const hasSubscription = !!school.stripe_subscription_id;
  const isExpired = trialEnd ? now > trialEnd : false;
  const daysRemaining = trialEnd
    ? Math.max(0, Math.ceil((trialEnd - now) / (1000 * 60 * 60 * 24)))
    : 0;

  return {
    status: school.subscription_status,
    plan: school.plan,
    isTrialing,
    hasSubscription,
    isExpired: isTrialing && isExpired,
    trialEndsAt: trialEnd,
    daysRemaining,
    // Urgency level for UI banners
    urgency: daysRemaining <= 1 ? 'critical' : daysRemaining <= 3 ? 'high' : daysRemaining <= 7 ? 'medium' : 'low',
  };
}

// ---------------------------------------------------------------------------
// checkTrialAccess
// Middleware helper: retorna true se escola pode usar o sistema.
// Bloqueia apenas se trial expirou E não tem assinatura ativa.
// ---------------------------------------------------------------------------
export async function checkTrialAccess(schoolId) {
  const trial = await getTrialStatus(schoolId);

  if (trial.status === 'active') return { allowed: true, trial };
  if (trial.isTrialing && !trial.isExpired) return { allowed: true, trial };

  // Trial expirado sem assinatura
  if (trial.isExpired || trial.status === 'canceled' || trial.status === 'unpaid') {
    return {
      allowed: false,
      trial,
      reason: 'trial_expired',
      message: 'Seu período de teste encerrou. Assine um plano para continuar.',
    };
  }

  return { allowed: true, trial };
}

// ---------------------------------------------------------------------------
// expireTrials (cron job — executar diariamente via Supabase pg_cron ou Edge Function)
// Atualiza escolas cujo trial expirou sem assinatura.
// ---------------------------------------------------------------------------
export async function expireTrials() {
  const supabase = getSupabase();

  const { data, error } = await supabase
    .from('schools')
    .update({
      subscription_status: 'canceled',
      updated_at: new Date().toISOString(),
    })
    .eq('subscription_status', 'trialing')
    .is('stripe_subscription_id', null)
    .lt('trial_ends_at', new Date().toISOString())
    .select('id, name, email');

  if (error) throw new Error(`expireTrials failed: ${error.message}`);

  console.log(`[Trial] Expired ${data?.length || 0} trial(s)`);
  return data || [];
}

// ---------------------------------------------------------------------------
// getSchoolsNearTrialEnd
// Retorna escolas que expiram em N dias (para envio de e-mails de lembrete).
// ---------------------------------------------------------------------------
export async function getSchoolsNearTrialEnd(daysAhead = 7) {
  const supabase = getSupabase();

  const fromDate = new Date();
  const toDate = new Date();
  toDate.setDate(toDate.getDate() + daysAhead);

  const { data, error } = await supabase
    .from('schools')
    .select('id, name, email, trial_ends_at, plan')
    .eq('subscription_status', 'trialing')
    .is('stripe_subscription_id', null)
    .gte('trial_ends_at', fromDate.toISOString())
    .lte('trial_ends_at', toDate.toISOString())
    .order('trial_ends_at', { ascending: true });

  if (error) throw new Error(`getSchoolsNearTrialEnd failed: ${error.message}`);
  return data || [];
}

// ---------------------------------------------------------------------------
// TrialBanner component data — usado pelo frontend para mostrar banner no app
// ---------------------------------------------------------------------------
export function getTrialBannerData(trialStatus) {
  if (!trialStatus.isTrialing) return null;

  const { daysRemaining, urgency, trialEndsAt } = trialStatus;
  const formattedDate = trialEndsAt
    ? trialEndsAt.toLocaleDateString('pt-BR', { day: '2-digit', month: 'long' })
    : '';

  const messages = {
    critical: `Seu trial encerra hoje! Assine agora para não perder o acesso.`,
    high: `Restam ${daysRemaining} dia(s) no seu trial (até ${formattedDate}). Assine para continuar.`,
    medium: `Você tem ${daysRemaining} dias de trial restantes. Experimente todos os recursos!`,
    low: `Trial ativo — ${daysRemaining} dias restantes.`,
  };

  const colors = {
    critical: 'bg-red-50 border-red-300 text-red-800',
    high: 'bg-orange-50 border-orange-300 text-orange-800',
    medium: 'bg-yellow-50 border-yellow-300 text-yellow-800',
    low: 'bg-blue-50 border-blue-200 text-blue-700',
  };

  return {
    show: true,
    urgency,
    message: messages[urgency],
    colorClass: colors[urgency],
    ctaText: urgency === 'critical' || urgency === 'high' ? 'Assinar agora' : 'Ver planos',
    ctaUrl: '/billing/checkout',
  };
}
