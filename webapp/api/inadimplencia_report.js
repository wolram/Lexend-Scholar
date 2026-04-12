/**
 * Lexend Scholar — API: Relatório de Inadimplência Financeira
 * GET /api/reports/inadimplencia
 *
 * Query params:
 *   min_days  — dias mínimos de atraso (default: 1)
 *   format    — 'json' (default) | 'html'
 *
 * Tabelas: financial_records, students, guardians (database_schema.sql)
 */

import { createClient } from '@supabase/supabase-js';

function getSupabase() {
  return createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);
}

export async function inadimplenciaReportHandler(req, res) {
  if (req.method !== 'GET') return res.status(405).end();

  const schoolId = req.session?.schoolId || req.headers['x-school-id'];
  if (!schoolId) return res.status(401).json({ error: 'Não autenticado' });

  const minDays = parseInt(req.query?.min_days || '1', 10);
  const format = req.query?.format || 'json';

  const supabase = getSupabase();
  const today = new Date().toISOString().split('T')[0];

  try {
    // ---------------------------------------------------------------------------
    // 1. Resumo por faixas de atraso
    // ---------------------------------------------------------------------------
    const { data: overdue } = await supabase
      .from('financial_records')
      .select(`
        id, amount, due_date, description,
        student:students(id, enrollment_code, full_name, email)
      `)
      .eq('school_id', schoolId)
      .eq('payment_status', 'pending')
      .lt('due_date', today)
      .order('due_date', { ascending: true });

    if (!overdue) return res.status(500).json({ error: 'Erro ao buscar dados' });

    // Filter by min_days
    const filtered = overdue.filter(r => {
      const days = Math.floor((new Date(today) - new Date(r.due_date)) / 86400000);
      return days >= minDays;
    });

    // Group by faixa
    const faixas = { '1-30 dias': [], '31-60 dias': [], '61-90 dias': [], 'Mais de 90 dias': [] };
    let totalGeral = 0;
    const studentMap = {};

    filtered.forEach(r => {
      const days = Math.floor((new Date(today) - new Date(r.due_date)) / 86400000);
      const student = r.student;
      const amount = parseFloat(r.amount);
      totalGeral += amount;

      const faixa = days <= 30 ? '1-30 dias'
        : days <= 60 ? '31-60 dias'
        : days <= 90 ? '61-90 dias'
        : 'Mais de 90 dias';

      faixas[faixa].push({ ...r, days });

      // Aggregate by student
      const sid = student?.id;
      if (sid) {
        if (!studentMap[sid]) {
          studentMap[sid] = {
            studentId: sid,
            enrollment_code: student.enrollment_code,
            full_name: student.full_name,
            email: student.email,
            parcelas: 0,
            total: 0,
            maxDays: 0,
          };
        }
        studentMap[sid].parcelas++;
        studentMap[sid].total += amount;
        if (days > studentMap[sid].maxDays) studentMap[sid].maxDays = days;
      }
    });

    const summary = Object.entries(faixas).map(([faixa, records]) => ({
      faixa,
      num_parcelas: records.length,
      num_alunos: new Set(records.map(r => r.student?.id).filter(Boolean)).size,
      total_em_aberto: records.reduce((s, r) => s + parseFloat(r.amount), 0),
    }));

    // Top debtors
    const topDebtors = Object.values(studentMap)
      .sort((a, b) => b.total - a.total)
      .slice(0, 20);

    const result = {
      generated_at: new Date().toISOString(),
      school_id: schoolId,
      reference_date: today,
      min_days_filter: minDays,
      total_records: filtered.length,
      total_inadimplente: totalGeral,
      summary_by_faixa: summary,
      top_debtors: topDebtors,
      detail: filtered.map(r => ({
        matricula: r.student?.enrollment_code,
        aluno: r.student?.full_name,
        descricao: r.description,
        valor: parseFloat(r.amount),
        vencimento: r.due_date,
        dias_atraso: Math.floor((new Date(today) - new Date(r.due_date)) / 86400000),
        risco: getRisco(Math.floor((new Date(today) - new Date(r.due_date)) / 86400000)),
      })),
    };

    if (format === 'html') {
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.status(200).send(generateInadimplenciaHtml(result));
    }

    return res.status(200).json(result);
  } catch (err) {
    console.error('[Report] inadimplencia error:', err);
    return res.status(500).json({ error: 'Erro interno' });
  }
}

function getRisco(days) {
  if (days <= 30) return 'Baixo';
  if (days <= 60) return 'Médio';
  if (days <= 90) return 'Alto';
  return 'Crítico';
}

function getRiscoColor(risco) {
  return { 'Baixo': '#fef3c7', 'Médio': '#fed7aa', 'Alto': '#fecaca', 'Crítico': '#fca5a5' }[risco] || '#f3f4f6';
}

function formatBRL(v) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v);
}

function generateInadimplenciaHtml(data) {
  const rows = data.detail.map(r => `
    <tr>
      <td>${r.matricula || '—'}</td>
      <td>${r.aluno || '—'}</td>
      <td>${r.descricao}</td>
      <td style="text-align:right">${formatBRL(r.valor)}</td>
      <td>${new Date(r.vencimento).toLocaleDateString('pt-BR')}</td>
      <td style="text-align:center"><strong>${r.dias_atraso}</strong></td>
      <td style="background:${getRiscoColor(r.risco)};text-align:center;font-weight:600">${r.risco}</td>
    </tr>`).join('');

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="UTF-8"/><title>Relatório de Inadimplência — Lexend Scholar</title>
<style>
  body{font-family:Arial,sans-serif;font-size:13px;color:#111418;padding:40px}
  h1{color:#137fec;font-size:22px;margin-bottom:4px}
  .meta{color:#617589;font-size:12px;margin-bottom:24px}
  .summary{display:flex;gap:16px;margin-bottom:24px}
  .card{background:#f1f3fd;border-radius:10px;padding:16px 20px;min-width:140px}
  .card-val{font-size:22px;font-weight:700;color:#137fec}
  .card-lbl{font-size:11px;color:#617589;margin-top:2px}
  table{width:100%;border-collapse:collapse;margin-top:16px}
  th{background:#f1f3fd;padding:8px 12px;text-align:left;font-size:11px;text-transform:uppercase;border:1px solid #e5e7eb}
  td{padding:8px 12px;border:1px solid #e5e7eb;vertical-align:middle}
  tr:hover td{background:#f9fafb}
</style>
</head>
<body>
<h1>Relatório de Inadimplência Financeira</h1>
<div class="meta">Gerado em ${new Date(data.generated_at).toLocaleString('pt-BR')} · Referência: ${new Date(data.reference_date).toLocaleDateString('pt-BR')}</div>
<div class="summary">
  <div class="card"><div class="card-val">${data.total_records}</div><div class="card-lbl">Parcelas em atraso</div></div>
  <div class="card"><div class="card-val">${formatBRL(data.total_inadimplente)}</div><div class="card-lbl">Total inadimplente</div></div>
  ${data.summary_by_faixa.map(f => `<div class="card"><div class="card-val">${f.num_alunos}</div><div class="card-lbl">${f.faixa}</div></div>`).join('')}
</div>
<table>
  <thead><tr><th>Matrícula</th><th>Aluno</th><th>Descrição</th><th>Valor</th><th>Vencimento</th><th>Dias</th><th>Risco</th></tr></thead>
  <tbody>${rows}</tbody>
</table>
</body></html>`;
}
