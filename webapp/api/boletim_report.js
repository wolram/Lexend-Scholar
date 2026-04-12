/**
 * Lexend Scholar — API: Geração de Boletim Escolar em PDF
 * GET /api/reports/boletim/:studentId?academic_year_id=xxx&format=html|pdf
 *
 * Para gerar PDF real, use puppeteer ou wkhtmltopdf apontando para o endpoint HTML.
 * Tabelas: grade_records, students, subjects, academic_periods, attendance_records
 */

import { createClient } from '@supabase/supabase-js';

function getSupabase() {
  return createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);
}

export async function boletimReportHandler(req, res) {
  if (req.method !== 'GET') return res.status(405).end();

  const schoolId = req.session?.schoolId || req.headers['x-school-id'];
  if (!schoolId) return res.status(401).json({ error: 'Não autenticado' });

  const studentId = req.params?.studentId || req.query?.student_id;
  const academicYearId = req.query?.academic_year_id;
  const format = req.query?.format || 'html';

  if (!studentId) return res.status(400).json({ error: 'student_id obrigatório' });

  const supabase = getSupabase();

  try {
    // --- Student info ---
    const { data: student } = await supabase
      .from('students')
      .select(`
        id, enrollment_code, full_name, birth_date,
        student_class_enrollments(
          active,
          class:classes(
            name,
            academic_year:academic_years(id, name),
            grade:grades(name)
          )
        )
      `)
      .eq('id', studentId)
      .eq('school_id', schoolId)
      .single();

    if (!student) return res.status(404).json({ error: 'Aluno não encontrado' });

    const { data: school } = await supabase
      .from('schools')
      .select('name')
      .eq('id', schoolId)
      .single();

    // Find the enrollment for the given academic year
    const enrollment = student.student_class_enrollments?.find(e => {
      if (!e.active) return false;
      if (academicYearId) return e.class?.academic_year?.id === academicYearId;
      return true;
    });

    const yearId = academicYearId || enrollment?.class?.academic_year?.id;

    // --- Grades ---
    const { data: grades } = await supabase
      .from('grade_records')
      .select(`
        score, max_score, grade_type, description,
        subject:subjects(id, name),
        academic_period:academic_periods(id, name, start_date, end_date)
      `)
      .eq('school_id', schoolId)
      .eq('student_id', studentId)
      .order('subject(name)')
      .order('academic_period(start_date)');

    // Filter by academic year via period
    const { data: periods } = await supabase
      .from('academic_periods')
      .select('id, name')
      .eq('academic_year_id', yearId);

    const periodIds = new Set(periods?.map(p => p.id) || []);
    const filteredGrades = grades?.filter(g => periodIds.has(g.academic_period?.id)) || [];

    // Group by subject → period
    const subjectMap = {};
    filteredGrades.forEach(g => {
      const subId = g.subject?.id;
      const subName = g.subject?.name;
      const periodName = g.academic_period?.name;
      const score = parseFloat(g.score || 0);
      const maxScore = parseFloat(g.max_score || 10);

      if (!subjectMap[subId]) {
        subjectMap[subId] = { name: subName, periods: {}, maxScore };
      }

      if (!subjectMap[subId].periods[periodName]) {
        subjectMap[subId].periods[periodName] = { scores: [], maxScore };
      }
      subjectMap[subId].periods[periodName].scores.push(score);
    });

    // Compute averages per subject per period
    const periodNames = periods?.map(p => p.name).sort() || [];
    const subjectRows = Object.values(subjectMap).map(sub => {
      const periodAvgs = {};
      periodNames.forEach(p => {
        const period = sub.periods[p];
        if (period && period.scores.length > 0) {
          periodAvgs[p] = +(period.scores.reduce((a, b) => a + b, 0) / period.scores.length).toFixed(1);
        } else {
          periodAvgs[p] = null;
        }
      });

      const availableAvgs = Object.values(periodAvgs).filter(v => v !== null);
      const mediaAnual = availableAvgs.length > 0
        ? +(availableAvgs.reduce((a, b) => a + b, 0) / availableAvgs.length).toFixed(1)
        : null;

      const maxScore = sub.maxScore || 10;
      const situacao = mediaAnual === null ? '—'
        : mediaAnual >= 6 ? 'Aprovado'
        : mediaAnual >= 4 ? 'Recuperação'
        : 'Reprovado';

      return { disciplina: sub.name, periodAvgs, mediaAnual, maxScore, situacao };
    });

    // --- Attendance per subject ---
    const { data: attendance } = await supabase
      .from('attendance_records')
      .select('status, subject:subjects(id, name), class:classes(academic_year_id)')
      .eq('school_id', schoolId)
      .eq('student_id', studentId);

    const attendanceFiltered = attendance?.filter(a => a.class?.academic_year_id === yearId) || [];
    const attendanceMap = {};
    attendanceFiltered.forEach(a => {
      const subId = a.subject?.id;
      const subName = a.subject?.name;
      if (!subId) return;
      if (!attendanceMap[subId]) attendanceMap[subId] = { name: subName, total: 0, present: 0, absent: 0 };
      attendanceMap[subId].total++;
      if (a.status === 'present' || a.status === 'late') attendanceMap[subId].present++;
      if (a.status === 'absent') attendanceMap[subId].absent++;
    });

    const attendanceRows = Object.values(attendanceMap).map(a => ({
      disciplina: a.name,
      total: a.total,
      presencas: a.present,
      faltas: a.absent,
      pct: a.total > 0 ? +((a.present / a.total) * 100).toFixed(1) : 0,
    }));

    const boletimData = {
      school: school?.name || '',
      student: {
        name: student.full_name,
        enrollment: student.enrollment_code,
        birth: student.birth_date,
        class: enrollment?.class?.name,
        grade: enrollment?.class?.grade?.name,
        year: enrollment?.class?.academic_year?.name,
      },
      periods: periodNames,
      subjects: subjectRows,
      attendance: attendanceRows,
      generatedAt: new Date().toISOString(),
    };

    if (format === 'json') {
      return res.status(200).json(boletimData);
    }

    // Default: HTML (suitable for PDF conversion)
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    if (format === 'pdf') {
      res.setHeader('Content-Disposition', `attachment; filename="boletim_${student.enrollment_code}.pdf"`);
    }
    return res.status(200).send(generateBoletimHtml(boletimData));
  } catch (err) {
    console.error('[Boletim] error:', err);
    return res.status(500).json({ error: 'Erro ao gerar boletim' });
  }
}

// ---------------------------------------------------------------------------
// generateBoletimHtml
// ---------------------------------------------------------------------------
function generateBoletimHtml(d) {
  const situacaoColor = { 'Aprovado': '#dcfce7', 'Recuperação': '#fef3c7', 'Reprovado': '#fecaca' };

  const periodHeaders = d.periods.map(p => `<th>${escHtml(p)}</th>`).join('');

  const gradeRows = d.subjects.map(sub => {
    const periodCells = d.periods.map(p => {
      const v = sub.periodAvgs[p];
      return `<td style="text-align:center;font-weight:600;${v !== null && v < 6 ? 'color:#dc2626' : ''}">${v !== null ? v.toFixed(1) : '—'}</td>`;
    }).join('');
    const bgColor = situacaoColor[sub.situacao] || '#f9fafb';
    return `
      <tr>
        <td>${escHtml(sub.disciplina)}</td>
        ${periodCells}
        <td style="text-align:center;font-weight:700;${sub.mediaAnual !== null && sub.mediaAnual < 6 ? 'color:#dc2626' : 'color:#137fec'}">${sub.mediaAnual !== null ? sub.mediaAnual.toFixed(1) : '—'}</td>
        <td style="background:${bgColor};text-align:center;font-weight:600;font-size:11px">${sub.situacao}</td>
      </tr>`;
  }).join('');

  const attendanceRows = d.attendance.map(a => `
    <tr>
      <td>${escHtml(a.disciplina)}</td>
      <td style="text-align:center">${a.total}</td>
      <td style="text-align:center">${a.presencas}</td>
      <td style="text-align:center;${a.faltas > 0 ? 'color:#dc2626;font-weight:600' : ''}">${a.faltas}</td>
      <td style="text-align:center;font-weight:600;${a.pct >= 75 ? 'color:#16a34a' : 'color:#dc2626'}">${a.pct}%</td>
    </tr>`).join('');

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8"/>
<title>Boletim — ${escHtml(d.student.name)}</title>
<style>
  @page { size: A4; margin: 20mm; }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: Arial, sans-serif; font-size: 12px; color: #111418; }
  .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 3px solid #137fec; padding-bottom: 16px; margin-bottom: 20px; }
  .school-name { font-size: 18px; font-weight: 700; color: #137fec; }
  .doc-title { font-size: 14px; font-weight: 700; text-align: right; }
  .student-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px; margin-bottom: 20px; background: #f1f3fd; border-radius: 8px; padding: 14px; }
  .field { }
  .field-label { font-size: 10px; color: #617589; text-transform: uppercase; margin-bottom: 2px; }
  .field-value { font-size: 13px; font-weight: 600; }
  h2 { font-size: 13px; font-weight: 700; text-transform: uppercase; color: #137fec; border-bottom: 1px solid #e5e7eb; padding-bottom: 6px; margin: 20px 0 10px; }
  table { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
  th { background: #137fec; color: white; padding: 7px 10px; font-size: 11px; text-align: left; }
  td { padding: 7px 10px; border-bottom: 1px solid #e5e7eb; }
  tr:nth-child(even) td { background: #f9fafb; }
  .footer { margin-top: 30px; text-align: center; font-size: 10px; color: #9ca3af; border-top: 1px solid #e5e7eb; padding-top: 10px; }
  .sig-row { display: flex; gap: 40px; margin-top: 40px; }
  .sig { flex: 1; text-align: center; }
  .sig-line { border-top: 1px solid #374151; padding-top: 6px; font-size: 11px; color: #617589; }
</style>
</head>
<body>
<div class="header">
  <div>
    <div class="school-name">${escHtml(d.school)}</div>
    <div style="color:#617589;font-size:11px">Sistema de Gestão Escolar Lexend Scholar</div>
  </div>
  <div class="doc-title">
    BOLETIM ESCOLAR<br/>
    <span style="font-size:11px;font-weight:400;color:#617589">Ano letivo: ${escHtml(d.student.year || '—')}</span>
  </div>
</div>

<div class="student-grid">
  <div class="field"><div class="field-label">Aluno</div><div class="field-value">${escHtml(d.student.name)}</div></div>
  <div class="field"><div class="field-label">Matrícula</div><div class="field-value">${escHtml(d.student.enrollment)}</div></div>
  <div class="field"><div class="field-label">Data de nascimento</div><div class="field-value">${d.student.birth ? new Date(d.student.birth).toLocaleDateString('pt-BR') : '—'}</div></div>
  <div class="field"><div class="field-label">Turma</div><div class="field-value">${escHtml(d.student.class || '—')}</div></div>
  <div class="field"><div class="field-label">Série / Ano</div><div class="field-value">${escHtml(d.student.grade || '—')}</div></div>
  <div class="field"><div class="field-label">Gerado em</div><div class="field-value">${new Date(d.generatedAt).toLocaleDateString('pt-BR')}</div></div>
</div>

<h2>Notas por Disciplina</h2>
<table>
  <thead>
    <tr><th>Disciplina</th>${periodHeaders}<th style="background:#0f6ec7">Média Anual</th><th style="background:#0f6ec7">Situação</th></tr>
  </thead>
  <tbody>${gradeRows}</tbody>
</table>

<h2>Frequência por Disciplina</h2>
<table>
  <thead>
    <tr><th>Disciplina</th><th>Total de Aulas</th><th>Presenças</th><th>Faltas</th><th>Frequência</th></tr>
  </thead>
  <tbody>${attendanceRows}</tbody>
</table>

<div class="sig-row">
  <div class="sig"><div class="sig-line">Coordenador(a) Pedagógico(a)</div></div>
  <div class="sig"><div class="sig-line">Diretor(a)</div></div>
  <div class="sig"><div class="sig-line">Ciência do Responsável</div></div>
</div>

<div class="footer">
  ${escHtml(d.school)} · Gerado em ${new Date(d.generatedAt).toLocaleString('pt-BR')} · Lexend Scholar — Sistema de Gestão Escolar
</div>
</body>
</html>`;
}

function escHtml(str) {
  return String(str || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}
