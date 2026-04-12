/**
 * Lexend Scholar — Modelo de Pricing por Número de Alunos
 *
 * Regras de negócio:
 *   - Starter:    até 100 alunos  → R$ 297/mês
 *   - Pro:        até 500 alunos  → R$ 697/mês
 *   - Enterprise: ilimitado       → R$ 1.497/mês
 *
 * Funcionalidades:
 *   - Recomendação automática de plano por contagem de alunos
 *   - Verificação de limite ao cadastrar aluno
 *   - Cálculo de custo por aluno (benchmarking comercial)
 *   - Projeção de custos para upgrade
 */

export const PRICING_PLANS = [
  {
    id: 'starter',
    name: 'Starter',
    maxStudents: 100,
    priceMonthly: 297.00,         // BRL
    priceAnnual: 267.30,          // 10% desconto anual
    features: [
      'Gestão de alunos e turmas',
      'Controle de frequência',
      'Boletim digital',
      'Comunicados para responsáveis',
      'Suporte por e-mail',
    ],
    stripePriceIdMonthly: process.env.STRIPE_PRICE_STARTER,
    highlight: false,
    badge: null,
  },
  {
    id: 'pro',
    name: 'Pro',
    maxStudents: 500,
    priceMonthly: 697.00,
    priceAnnual: 627.30,          // 10% desconto anual
    features: [
      'Tudo do Starter',
      'Relatórios avançados (frequência, boletim, inadimplência)',
      'Export de dados em XLSX',
      'Push notifications para responsáveis',
      'Dashboard de analytics',
      'Suporte prioritário',
    ],
    stripePriceIdMonthly: process.env.STRIPE_PRICE_PRO,
    highlight: true,
    badge: 'Mais popular',
  },
  {
    id: 'enterprise',
    name: 'Enterprise',
    maxStudents: null,            // unlimited
    priceMonthly: 1497.00,
    priceAnnual: 1347.30,        // 10% desconto anual
    features: [
      'Tudo do Pro',
      'Alunos ilimitados',
      'Multi-unidades (várias filiais)',
      'SLA 99,9% uptime',
      'Onboarding e treinamento dedicado',
      'Acesso à API REST',
      'Relatório personalizado sob demanda',
    ],
    stripePriceIdMonthly: process.env.STRIPE_PRICE_ENTERPRISE,
    highlight: false,
    badge: 'Enterprise',
  },
];

// ---------------------------------------------------------------------------
// recommendPlan
// Dado o número atual de alunos, retorna o plano mínimo adequado.
// ---------------------------------------------------------------------------
export function recommendPlan(studentCount) {
  if (studentCount <= 100) return PRICING_PLANS[0]; // starter
  if (studentCount <= 500) return PRICING_PLANS[1]; // pro
  return PRICING_PLANS[2];                           // enterprise
}

// ---------------------------------------------------------------------------
// canAddStudent
// Verifica se a escola pode cadastrar mais um aluno no plano atual.
// ---------------------------------------------------------------------------
export async function canAddStudent(supabase, schoolId) {
  const { data: school } = await supabase
    .from('schools')
    .select('plan, max_students, subscription_status')
    .eq('id', schoolId)
    .single();

  if (!school) throw new Error('Escola não encontrada');

  // Verifica se assinatura está ativa ou em trial
  const allowedStatuses = ['active', 'trialing'];
  if (!allowedStatuses.includes(school.subscription_status)) {
    return {
      allowed: false,
      reason: 'subscription_inactive',
      message: 'Assinatura inativa. Renove seu plano para adicionar alunos.',
    };
  }

  // Enterprise = ilimitado
  if (!school.max_students) return { allowed: true };

  const { count } = await supabase
    .from('students')
    .select('id', { count: 'exact', head: true })
    .eq('school_id', schoolId)
    .eq('active', true);

  const currentCount = count || 0;

  if (currentCount >= school.max_students) {
    const nextPlan = recommendPlan(currentCount + 1);
    return {
      allowed: false,
      reason: 'limit_reached',
      currentCount,
      limit: school.max_students,
      message: `Limite de ${school.max_students} alunos atingido no plano ${school.plan.charAt(0).toUpperCase() + school.plan.slice(1)}.`,
      upgradeTo: nextPlan.id,
      upgradeMessage: `Faça upgrade para o plano ${nextPlan.name} (até ${nextPlan.maxStudents ?? 'ilimitados'} alunos por R$${nextPlan.priceMonthly.toFixed(0)}/mês).`,
    };
  }

  return {
    allowed: true,
    currentCount,
    limit: school.max_students,
    remaining: school.max_students - currentCount,
  };
}

// ---------------------------------------------------------------------------
// getPricingComparison
// Retorna tabela comparativa de planos para exibição em /pricing.
// ---------------------------------------------------------------------------
export function getPricingComparison() {
  return PRICING_PLANS.map(plan => ({
    ...plan,
    pricePerStudent: plan.maxStudents
      ? (plan.priceMonthly / plan.maxStudents).toFixed(2)
      : null,                  // enterprise: null (ilimitado)
    priceMonthlyFormatted: formatBRL(plan.priceMonthly),
    priceAnnualFormatted: formatBRL(plan.priceAnnual),
    annualSavings: formatBRL((plan.priceMonthly - plan.priceAnnual) * 12),
  }));
}

// ---------------------------------------------------------------------------
// getUsageSummary
// Para exibição no dashboard da escola: uso atual vs limite.
// ---------------------------------------------------------------------------
export async function getUsageSummary(supabase, schoolId) {
  const { data: school } = await supabase
    .from('schools')
    .select('plan, max_students, subscription_status, trial_ends_at, current_period_end')
    .eq('id', schoolId)
    .single();

  if (!school) throw new Error('Escola não encontrada');

  const { count: activeStudents } = await supabase
    .from('students')
    .select('id', { count: 'exact', head: true })
    .eq('school_id', schoolId)
    .eq('active', true);

  const usage = activeStudents || 0;
  const limit = school.max_students;
  const percentage = limit ? Math.round((usage / limit) * 100) : 0;

  return {
    plan: school.plan,
    subscriptionStatus: school.subscription_status,
    activeStudents: usage,
    studentLimit: limit,
    usagePercentage: percentage,
    isNearLimit: percentage >= 80,
    isAtLimit: limit ? usage >= limit : false,
    recommendedPlan: percentage >= 80 ? recommendPlan(limit ? limit + 1 : usage) : null,
    trialEndsAt: school.trial_ends_at,
    currentPeriodEnd: school.current_period_end,
  };
}

function formatBRL(value) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value);
}
