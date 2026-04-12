/**
 * MetricsCards.js
 * Lexend Scholar — Dashboard metrics cards component + data-fetching helpers.
 *
 * Exports:
 *  - fetchDashboardMetrics(schoolId, supabase)  — server-side data fetcher
 *  - MetricsCards({ metrics })                  — React component (client)
 *  - METRIC_CONFIGS                             — card definitions (labels, icons, colors)
 *
 * Each card shows: value, label, percentage change vs previous period, and a trend arrow.
 * Uses the school_id from the authenticated session for multi-tenant isolation.
 */

'use client';

import { useEffect, useState } from 'react';

// ---------------------------------------------------------------------------
// Card configuration
// ---------------------------------------------------------------------------

/**
 * @typedef {Object} MetricConfig
 * @property {string} key         — key in the metrics object
 * @property {string} label       — display label
 * @property {string} description — subtitle / context
 * @property {string} icon        — inline SVG path data
 * @property {string} color       — Tailwind color class prefix (e.g. 'blue', 'green')
 * @property {string} format      — 'number' | 'currency' | 'percent'
 */

/** @type {MetricConfig[]} */
export const METRIC_CONFIGS = [
  {
    key: 'total_students',
    label: 'Alunos Matriculados',
    description: 'Total de alunos ativos',
    color: 'blue',
    format: 'number',
    icon: `<path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0"/>`,
  },
  {
    key: 'attendance_rate',
    label: 'Taxa de Frequência',
    description: 'Média dos últimos 30 dias',
    color: 'green',
    format: 'percent',
    icon: `<path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/>`,
  },
  {
    key: 'pending_payments',
    label: 'Mensalidades Pendentes',
    description: 'Valor total em aberto',
    color: 'amber',
    format: 'currency',
    icon: `<path stroke-linecap="round" stroke-linejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>`,
  },
  {
    key: 'open_occurrences',
    label: 'Ocorrências Abertas',
    description: 'Pendentes de resolução',
    color: 'red',
    format: 'number',
    icon: `<path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>`,
  },
  {
    key: 'average_grade',
    label: 'Média Geral',
    description: 'Todas as turmas e disciplinas',
    color: 'purple',
    format: 'number',
    icon: `<path stroke-linecap="round" stroke-linejoin="round" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>`,
  },
  {
    key: 'unread_messages',
    label: 'Mensagens Não Lidas',
    description: 'De responsáveis e alunos',
    color: 'indigo',
    format: 'number',
    icon: `<path stroke-linecap="round" stroke-linejoin="round" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"/>`,
  },
];

// ---------------------------------------------------------------------------
// Color map — Tailwind classes can't be dynamically constructed, so we map them
// ---------------------------------------------------------------------------
const COLOR_MAP = {
  blue:   { bg: 'bg-blue-50',   icon: 'text-blue-600',   badge: 'bg-blue-100 text-blue-700' },
  green:  { bg: 'bg-green-50',  icon: 'text-green-600',  badge: 'bg-green-100 text-green-700' },
  amber:  { bg: 'bg-amber-50',  icon: 'text-amber-600',  badge: 'bg-amber-100 text-amber-700' },
  red:    { bg: 'bg-red-50',    icon: 'text-red-600',    badge: 'bg-red-100 text-red-700' },
  purple: { bg: 'bg-purple-50', icon: 'text-purple-600', badge: 'bg-purple-100 text-purple-700' },
  indigo: { bg: 'bg-indigo-50', icon: 'text-indigo-600', badge: 'bg-indigo-100 text-indigo-700' },
};

// ---------------------------------------------------------------------------
// Data fetcher — runs server-side (or via API route)
// ---------------------------------------------------------------------------

/**
 * Fetches all dashboard metrics for a school in a single pass.
 * Designed to run server-side (Node.js) with the Supabase service-role client.
 *
 * @param {string} schoolId
 * @param {import('@supabase/supabase-js').SupabaseClient} supabase
 * @returns {Promise<DashboardMetrics>}
 *
 * @typedef {Object} DashboardMetrics
 * @property {number} total_students
 * @property {number} attendance_rate         — 0–100
 * @property {number} pending_payments        — total amount in BRL
 * @property {number} open_occurrences
 * @property {number} average_grade           — 0–10
 * @property {number} unread_messages
 * @property {Record<string, number>} change  — percent change per metric vs previous period
 */
export async function fetchDashboardMetrics(schoolId, supabase) {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const thirtyDaysAgoISO = thirtyDaysAgo.toISOString().slice(0, 10);

  const sixtyDaysAgo = new Date();
  sixtyDaysAgo.setDate(sixtyDaysAgo.getDate() - 60);
  const sixtyDaysAgoISO = sixtyDaysAgo.toISOString().slice(0, 10);

  // Run all queries concurrently
  const [
    studentsResult,
    attendanceCurrent,
    attendancePrevious,
    paymentsResult,
    occurrencesResult,
    gradesResult,
    messagesResult,
  ] = await Promise.all([
    // 1. Total active students
    supabase
      .from('students')
      .select('id', { count: 'exact', head: true })
      .eq('school_id', schoolId)
      .eq('active', true),

    // 2. Attendance rate — current 30 days
    supabase
      .from('attendance_records')
      .select('status')
      .eq('school_id', schoolId)
      .gte('date', thirtyDaysAgoISO),

    // 3. Attendance rate — previous 30 days (for trend)
    supabase
      .from('attendance_records')
      .select('status')
      .eq('school_id', schoolId)
      .gte('date', sixtyDaysAgoISO)
      .lt('date', thirtyDaysAgoISO),

    // 4. Pending payments total amount
    supabase
      .from('financial_records')
      .select('amount')
      .eq('school_id', schoolId)
      .eq('payment_status', 'pending'),

    // 5. Open occurrences (not resolved)
    supabase
      .from('occurrences')
      .select('id', { count: 'exact', head: true })
      .eq('school_id', schoolId)
      .eq('resolved', false),

    // 6. Average grade (current academic year)
    supabase
      .from('grade_records')
      .select('score, max_score')
      .eq('school_id', schoolId)
      .not('score', 'is', null),

    // 7. Unread messages
    supabase
      .from('messages')
      .select('id', { count: 'exact', head: true })
      .eq('school_id', schoolId)
      .eq('read', false),
  ]);

  // --- Compute attendance rate ---
  function computeAttendanceRate(records) {
    if (!records || records.length === 0) return 0;
    const present = records.filter((r) => r.status === 'present' || r.status === 'late').length;
    return Math.round((present / records.length) * 100);
  }

  const attendanceRateCurrent = computeAttendanceRate(attendanceCurrent.data);
  const attendanceRatePrevious = computeAttendanceRate(attendancePrevious.data);

  // --- Compute pending payments sum ---
  const pendingPayments = (paymentsResult.data || []).reduce(
    (sum, r) => sum + Number(r.amount),
    0
  );

  // --- Compute average grade (normalized to 10) ---
  const gradeData = gradesResult.data || [];
  const avgGrade = gradeData.length > 0
    ? gradeData.reduce((sum, r) => sum + (Number(r.score) / Number(r.max_score)) * 10, 0) / gradeData.length
    : 0;

  // --- Compute % change helpers ---
  function pctChange(current, previous) {
    if (previous === 0) return 0;
    return Math.round(((current - previous) / previous) * 100);
  }

  const totalStudents = studentsResult.count || 0;
  const openOccurrences = occurrencesResult.count || 0;
  const unreadMessages = messagesResult.count || 0;

  return {
    total_students:    totalStudents,
    attendance_rate:   attendanceRateCurrent,
    pending_payments:  pendingPayments,
    open_occurrences:  openOccurrences,
    average_grade:     Math.round(avgGrade * 10) / 10,
    unread_messages:   unreadMessages,
    change: {
      attendance_rate: pctChange(attendanceRateCurrent, attendanceRatePrevious),
    },
  };
}

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

/**
 * Formats a metric value according to its type.
 * @param {number} value
 * @param {'number'|'currency'|'percent'} format
 * @returns {string}
 */
function formatValue(value, format) {
  if (format === 'currency') {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
      maximumFractionDigits: 0,
    }).format(value);
  }
  if (format === 'percent') {
    return `${value}%`;
  }
  return new Intl.NumberFormat('pt-BR').format(value);
}

// ---------------------------------------------------------------------------
// Skeleton card (loading state)
// ---------------------------------------------------------------------------
function MetricCardSkeleton() {
  return (
    <div className="rounded-xl border border-gray-100 bg-white p-5 shadow-sm animate-pulse">
      <div className="flex items-start justify-between">
        <div className="h-10 w-10 rounded-lg bg-gray-200" />
        <div className="h-5 w-16 rounded-full bg-gray-200" />
      </div>
      <div className="mt-4 h-8 w-24 rounded bg-gray-200" />
      <div className="mt-2 h-4 w-32 rounded bg-gray-100" />
    </div>
  );
}

// ---------------------------------------------------------------------------
// Single metric card
// ---------------------------------------------------------------------------
/**
 * @param {{
 *   config: MetricConfig,
 *   value: number,
 *   change?: number
 * }} props
 */
function MetricCard({ config, value, change }) {
  const colors = COLOR_MAP[config.color] || COLOR_MAP.blue;
  const isPositive = change >= 0;
  const showChange = change !== undefined && change !== null && change !== 0;

  return (
    <div className="rounded-xl border border-gray-100 bg-white p-5 shadow-sm hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between">
        {/* Icon */}
        <div className={`flex h-10 w-10 items-center justify-center rounded-lg ${colors.bg}`}>
          <svg
            className={`h-5 w-5 ${colors.icon}`}
            fill="none"
            stroke="currentColor"
            strokeWidth={2}
            viewBox="0 0 24 24"
            dangerouslySetInnerHTML={{ __html: config.icon }}
          />
        </div>

        {/* Trend badge */}
        {showChange && (
          <span
            className={`flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium ${
              isPositive ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
            }`}
          >
            {isPositive ? (
              <svg className="h-3 w-3" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 10.5L12 3m0 0l7.5 7.5M12 3v18" />
              </svg>
            ) : (
              <svg className="h-3 w-3" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 13.5L12 21m0 0l-7.5-7.5M12 21V3" />
              </svg>
            )}
            {Math.abs(change)}%
          </span>
        )}
      </div>

      {/* Value */}
      <p className="mt-4 text-2xl font-bold text-gray-900 tabular-nums">
        {formatValue(value, config.format)}
      </p>

      {/* Label + description */}
      <p className="mt-0.5 text-sm font-medium text-gray-700">{config.label}</p>
      <p className="text-xs text-gray-400">{config.description}</p>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Main exported component
// ---------------------------------------------------------------------------

/**
 * MetricsCards — renders the dashboard metrics grid.
 *
 * Can be used in two modes:
 *  1. Pass `metrics` directly (server-fetched, SSR)
 *  2. Pass `schoolId` to fetch client-side via /api/dashboard/metrics
 *
 * @param {{
 *   metrics?: import('./MetricsCards').DashboardMetrics,
 *   schoolId?: string,
 *   className?: string
 * }} props
 */
export default function MetricsCards({ metrics: initialMetrics, schoolId, className = '' }) {
  const [metrics, setMetrics] = useState(initialMetrics || null);
  const [loading, setLoading] = useState(!initialMetrics);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (initialMetrics || !schoolId) return;

    async function load() {
      try {
        setLoading(true);
        const res = await fetch(`/api/dashboard/metrics?school_id=${schoolId}`, {
          headers: { 'Content-Type': 'application/json' },
          credentials: 'include',
        });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const json = await res.json();
        setMetrics(json.data);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    }

    load();
  }, [schoolId, initialMetrics]);

  if (error) {
    return (
      <div className={`rounded-xl border border-red-100 bg-red-50 p-6 text-center ${className}`}>
        <p className="text-sm text-red-600">Erro ao carregar métricas: {error}</p>
        <button
          className="mt-2 text-xs text-red-500 underline"
          onClick={() => { setError(null); setLoading(true); }}
        >
          Tentar novamente
        </button>
      </div>
    );
  }

  return (
    <div className={`grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3 ${className}`}>
      {METRIC_CONFIGS.map((config) => {
        if (loading || !metrics) {
          return <MetricCardSkeleton key={config.key} />;
        }
        return (
          <MetricCard
            key={config.key}
            config={config}
            value={metrics[config.key] ?? 0}
            change={metrics.change?.[config.key]}
          />
        );
      })}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Usage example (in a Next.js page):
// ---------------------------------------------------------------------------
//
// import { fetchDashboardMetrics } from '@/webapp/components/MetricsCards';
// import MetricsCards from '@/webapp/components/MetricsCards';
// import { supabase } from '@/webapp/api/_supabase';
//
// // Server Component
// export default async function DashboardPage() {
//   const session = await getServerSession();
//   const metrics = await fetchDashboardMetrics(session.school_id, supabase);
//   return (
//     <div>
//       <h1 className="text-2xl font-bold text-gray-900 mb-6">Dashboard</h1>
//       <MetricsCards metrics={metrics} />
//     </div>
//   );
// }
