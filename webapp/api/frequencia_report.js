/**
 * Lexend Scholar — API: Relatório de Frequência
 * GET /api/reports/frequencia
 *
 * Query params:
 *   mode         — 'aluno' | 'turma' | 'criticos' (default: 'turma')
 *   student_id   — UUID do aluno (mode=aluno)
 *   class_id     — UUID da turma (filtra)
 *   date_start   — YYYY-MM-DD (default: início do ano letivo atual)
 *   date_end     — YYYY-MM-DD (default: hoje)
 *   format       — 'json' | 'html' (default: json)
 *
 * Tabelas: attendance_records, students, classes, grades, subjects
 */

import { createClient } from '@supabase/supabase-js';

function getSupabase() {
  return createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);
}

export async function frequenciaReportHandler(req, res) {
  if (req.method !== 'GET') return res.status(405).end();

  const schoolId = req.session?.schoolId || req.headers['x-school-id'];
  if (!schoolId) return res.status(401).json({ error: 'Não autenticado' });

  const mode = req.query?.mode || 'turma';
  const studentId = req.query?.student_id || null;
  const classId = req.query?.class_id || null;
  const format = req.query?.format || 'json';

  // Default date range: current year
  const today = new Date().toISOString().split('T')[0];
  const yearStart = `${today.slice(0, 4)}-01-01`;
  const dateStart = req.query?.date_start || yearStart;
  const dateEnd = req.query?.date_end || today;

  const supabase = getSupabase();

  try {
    let data;

    if (mode === 'aluno' && studentId) {
      data = await getFrequenciaByAluno(supabase, schoolId, studentId, dateStart, dateEnd);
    } else if (mode === 'criticos') {
      data = await getAlunosCriticos(supabase, schoolId, dateStart, dateEnd, classId);
    } else {
      data = await getFrequenciaByTurma(supabase, schoolId, classId, dateStart, dateEnd);
    }

    if (format === 'html') {
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.status(200).send(generateFrequenciaHtml(data, mode, dateStart, dateEnd));
    }

    return res.status(200).json({ mode, dateStart, dateEnd, data });
  } catch (err) {
    console.error('[Frequência] error:', err);
    return res.status(500).json({ error: 'Erro interno ao gerar relatório de frequência' });
  }
}

// ---------------------------------------------------------------------------
// getFrequenciaByAluno — frequência por disciplina de um aluno
// ---------------------------------------------------------------------------
async function getFrequenciaByAluno(supabase, schoolId, studentId, dateStart, dateEnd) {
  const { data: student } = await supabase
    .from('students')
    .select('full_name, enrollment_code')
    .eq('id', studentId)
    .eq('school_id', schoolId)
    .single();

  const { data: records } = await supabase
    .from('attendance_records')
    .select('status, date, subject:subjects(id, name)')
    .eq('school_id', schoolId)
    .eq('student_id', studentId)
    .gte('date', dateStart)
    .lte('date', dateEnd)
    .order('date');

  // Group by subject
  const subjectMap = {};
  (records || []).forEach(r => {
    const key = r.subject?.id;
    if (!key) return;
    if (!subjectMap[key]) subjectMap[key] = { name: r.subject?.name, total: 0, present: 0, absent: 0, late: 0, excused: 0, dates: [] };
    subjectMap[key].total++;
    if (r.status === 'present') subjectMap[key].present++;
    if (r.status === 'absent')  subjectMap[key].absent++;
    if (r.status === 'late')    { subjectMap[key].present++; subjectMap[key].late++; }
    if (r.status === 'excused') subjectMap[key].excused++;
    subjectMap[key].dates.push({ date: r.date, status: r.status });
  });

  const subjects = Object.values(subjectMap).map(s => ({
    ...s,
    pct: s.total > 0 ? +((s.present / s.total) * 100).toFixed(1) : 0,
    status: getStatusLabel(s.total > 0 ? s.present / s.total : 1),
  })).sort((a, b) => a.pct - b.pct);

  const totalAulas = subjects.reduce((s, r) => s + r.total, 0);
  const totalPresente = subjects.reduce((s, r) => s + r.present, 0);

  return {
    student,
    subjects,
    geral: {
      total: totalAulas,
      present: totalPresente,
      pct: totalAulas > 0 ? +((totalPresente / totalAulas) * 100).toFixed(1) : 0,
    },
  };
}

// ---------------------------------------------------------------------------
// getFrequenciaByTurma — frequência agregada por turma
// ---------------------------------------------------------------------------
async function getFrequenciaByTurma(supabase, schoolId, classId, dateStart, dateEnd) {
  let enrollQuery = supabase
    .from('student_class_enrollments')
    .select(`
      student:students(id, full_name, enrollment_code, active),
      class:classes(id, name, grade:grades(name))
    `)
    .eq('active', true);

  if (classId) enrollQuery = enrollQuery.eq('class_id', classId);

  const { data: enrollments } = await enrollQuery;

  const studentIds = [...new Set(enrollments?.map(e => e.student?.id).filter(Boolean) || [])];
  const classIds = [...new Set(enrollments?.map(e => e.class?.id).filter(Boolean) || [])];

  if (!studentIds.length) return [];

  let arQuery = supabase
    .from('attendance_records')
    .select('student_id, class_id, status')
    .eq('school_id', schoolId)
    .in('student_id', studentIds)
    .gte('date', dateStart)
    .lte('date', dateEnd);

  if (classIds.length) arQuery = arQuery.in('class_id', classIds);

  const { data: records } = await arQuery;

  // Map student → attendance
  const attMap = {};
  (records || []).forEach(r => {
    if (!attMap[r.student_id]) attMap[r.student_id] = { total: 0, present: 0 };
    attMap[r.student_id].total++;
    if (r.status === 'present' || r.status === 'late') attMap[r.student_id].present++;
  });

  // Build rows
  const rows = (enrollments || [])
    .filter(e => e.student?.active)
    .map(e => {
      const sid = e.student?.id;
      const att = attMap[sid] || { total: 0, present: 0 };
      const pct = att.total > 0 ? +((att.present / att.total) * 100).toFixed(1) : null;
      return {
        matricula: e.student?.enrollment_code,
        aluno: e.student?.full_name,
        turma: e.class?.name,
        serie: e.class?.grade?.name,
        total: att.total,
        presencas: att.present,
        faltas: att.total - att.present,
        pct,
        status: pct !== null ? getStatusLabel(att.present / att.total) : 'Sem registro',
      };
    })
    .sort((a, b) => (a.pct ?? 100) - (b.pct ?? 100));

  return rows;
}

// ---------------------------------------------------------------------------
// getAlunosCriticos — alunos com frequência abaixo de 60%
// ---------------------------------------------------------------------------
async function getAlunosCriticos(supabase, schoolId, dateStart, dateEnd, classId) {
  const todos = await getFrequenciaByTurma(supabase, schoolId, classId, dateStart, dateEnd);
  return todos.filter(r => r.pct !== null && r.pct < 60);
}

function getStatusLabel(ratio) {
  if (ratio >= 0.75) return 'Regular';
  if (ratio >= 0.60) return 'Atenção';
  return 'Crítico';
}

function getStatusColor(status) {
  return { 'Regular': '#dcfce7', 'Atenção': '#fef3c7', 'Crítico': '#fecaca', 'Sem registro': '#f3f4f6' }[status] || '#f3f4f6';
}

function formatBRL(v) { return v != null ? v.toFixed(1) + '%' : '—'; }

// ---------------------------------------------------------------------------
// generateFrequenciaHtml
// ---------------------------------------------------------------------------
function generateFrequenciaHtml(data, mode, dateStart, dateEnd) {
  const fmtDate = d => new Date(d + 'T12:00:00').toLocaleDateString('pt-BR');
  const esc = s => String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

  const modeTitle = { aluno: 'por Aluno', turma: 'por Turma', criticos: '— Alunos em Risco' }[mode] || '';

  let tableHtml = '';
  if (mode === 'aluno' && data.subjects) {
    tableHtml = `
      <p style="margin-bottom:12px"><strong>${esc(data.student?.full_name)}</strong> — Matrícula: ${esc(data.student?.enrollment_code)}</p>
      <p style="margin-bottom:16px;color:#617589">Frequência geral: <strong style="color:${data.geral?.pct >= 75 ? '#16a34a' : '#dc2626'}">${formatBRL(data.geral?.pct)}</strong>  (${data.geral?.present}/${data.geral?.total} aulas)</p>
      <table>
        <thead><tr><th>Disciplina</th><th>Total</th><th>Presenças</th><th>Faltas</th><th>Frequência</th><th>Status</th></tr></thead>
        <tbody>${(data.subjects || []).map(s => `
          <tr>
            <td>${esc(s.name)}</td>
            <td style="text-align:center">${s.total}</td>
            <td style="text-align:center">${s.present}</td>
            <td style="text-align:center;${s.absent > 0 ? 'color:#dc2626;font-weight:600' : ''}">${s.absent}</td>
            <td style="text-align:center;font-weight:700;${s.pct >= 75 ? 'color:#16a34a' : 'color:#dc2626'}">${formatBRL(s.pct)}</td>
            <td style="background:${getStatusColor(s.status)};text-align:center;font-size:11px;font-weight:600">${s.status}</td>
          </tr>`).join('')}
        </tbody>
      </table>`;
  } else {
    const rows = Array.isArray(data) ? data : [];
    tableHtml = `
      <table>
        <thead><tr><th>Matrícula</th><th>Aluno</th><th>Turma</th><th>Série</th><th>Total</th><th>Presenças</th><th>Faltas</th><th>Frequência</th><th>Status</th></tr></thead>
        <tbody>${rows.map(r => `
          <tr>
            <td>${esc(r.matricula)}</td>
            <td>${esc(r.aluno)}</td>
            <td>${esc(r.turma)}</td>
            <td>${esc(r.serie)}</td>
            <td style="text-align:center">${r.total}</td>
            <td style="text-align:center">${r.presencas}</td>
            <td style="text-align:center;${r.faltas > 0 ? 'color:#dc2626' : ''}">${r.faltas}</td>
            <td style="text-align:center;font-weight:700;${r.pct >= 75 ? 'color:#16a34a' : r.pct != null ? 'color:#dc2626' : ''}">${r.pct != null ? r.pct.toFixed(1) + '%' : '—'}</td>
            <td style="background:${getStatusColor(r.status)};text-align:center;font-size:11px;font-weight:600">${esc(r.status)}</td>
          </tr>`).join('')}
        </tbody>
      </table>`;
  }

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="UTF-8"/><title>Relatório de Frequência ${modeTitle} — Lexend Scholar</title>
<style>
  body{font-family:Arial,sans-serif;font-size:12px;color:#111418;padding:32px}
  h1{color:#137fec;font-size:20px;margin-bottom:4px}
  .meta{color:#617589;font-size:11px;margin-bottom:20px}
  table{width:100%;border-collapse:collapse}
  th{background:#137fec;color:#fff;padding:7px 10px;font-size:11px;text-align:left}
  td{padding:7px 10px;border-bottom:1px solid #e5e7eb}
  tr:hover td{background:#f9fafb}
  .footer{margin-top:24px;text-align:center;font-size:10px;color:#9ca3af;border-top:1px solid #e5e7eb;padding-top:10px}
</style>
</head>
<body>
<h1>Relatório de Frequência ${modeTitle}</h1>
<div class="meta">Período: ${fmtDate(dateStart)} a ${fmtDate(dateEnd)} · Gerado em: ${new Date().toLocaleString('pt-BR')}</div>
${tableHtml}
<div class="footer">Lexend Scholar — Sistema de Gestão Escolar · Frequência mínima legal: 75% da carga horária</div>
</body></html>`;
}
