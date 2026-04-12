/**
 * Lexend Scholar — Export de Dados XLSX para Secretaria
 *
 * GET /export/xlsx?type=all|students|attendance|grades|financial
 *
 * Query params:
 *   type       — 'all' | 'students' | 'attendance' | 'grades' | 'financial' (default: 'all')
 *   class_id   — filtrar por turma (opcional)
 *   date_from  — data inicial YYYY-MM-DD (default: início do ano)
 *   date_to    — data final   YYYY-MM-DD (default: hoje)
 *
 * Workbook com 4 abas:
 *   "Alunos"    — nome, turma, status, email responsável
 *   "Frequência" — aluno, turma, total aulas, presenças, percentual
 *   "Boletim"   — aluno, disciplina, média, situação
 *   "Financeiro" — aluno, mensalidade, vencimento, status, valor pago
 *
 * Estilização: header azul (#1E3A5F), auto-filter, colunas com largura automática
 *
 * Dependência: npm install exceljs
 */

import ExcelJS from 'exceljs';
import express from 'express';
import { createClient } from '@supabase/supabase-js';

const router = express.Router();

// Cor do header conforme spec: #1E3A5F
const HEADER_BG_COLOR  = 'FF1E3A5F';
const HEADER_FONT_COLOR = 'FFFFFFFF';

const HEADER_FONT  = { bold: true, color: { argb: HEADER_FONT_COLOR }, size: 11, name: 'Calibri' };
const HEADER_FILL  = { type: 'pattern', pattern: 'solid', fgColor: { argb: HEADER_BG_COLOR } };
const HEADER_ALIGN = { vertical: 'middle', horizontal: 'center', wrapText: true };
const BORDER_THIN  = { style: 'thin', color: { argb: 'FFE5E7EB' } };
const ALL_BORDERS  = { top: BORDER_THIN, left: BORDER_THIN, bottom: BORDER_THIN, right: BORDER_THIN };
const ROW_FILL_ALT = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF9FAFB' } };

function getSupabase() {
  return createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY
  );
}

/**
 * GET /export/xlsx
 */
router.get('/', async (req, res) => {
  const schoolId = req.session?.schoolId || req.headers['x-school-id'];
  if (!schoolId) {
    return res.status(401).json({ error: 'Não autenticado' });
  }

  const type    = req.query.type  || 'all';
  const classId = req.query.class_id || null;
  const today   = new Date().toISOString().split('T')[0];
  const dateFrom = req.query.date_from || `${today.slice(0, 4)}-01-01`;
  const dateTo   = req.query.date_to   || today;

  const supabase = getSupabase();

  try {
    const workbook = new ExcelJS.Workbook();
    workbook.creator    = 'Lexend Scholar';
    workbook.created    = new Date();
    workbook.modified   = new Date();

    const tabs = type === 'all'
      ? ['students', 'attendance', 'grades', 'financial']
      : [type];

    for (const tab of tabs) {
      switch (tab) {
        case 'students':
          await addAlunosSheet(workbook, supabase, schoolId, classId);
          break;
        case 'attendance':
          await addFrequenciaSheet(workbook, supabase, schoolId, classId, dateFrom, dateTo);
          break;
        case 'grades':
          await addBoletimSheet(workbook, supabase, schoolId, classId);
          break;
        case 'financial':
          await addFinanceiroSheet(workbook, supabase, schoolId, dateFrom, dateTo);
          break;
      }
    }

    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename=lexend-scholar-export.xlsx'
    );

    await workbook.xlsx.write(res);
    res.end();
  } catch (err) {
    console.error('[XLSX] export error:', err);
    if (!res.headersSent) {
      res.status(500).json({ error: 'Erro ao gerar arquivo XLSX' });
    }
  }
});

// ---------------------------------------------------------------------------
// Aba: Alunos — nome, turma, status, email responsável
// ---------------------------------------------------------------------------
async function addAlunosSheet(workbook, supabase, schoolId, classId) {
  const { data: rows } = await supabase
    .from('students')
    .select(`
      enrollment_code,
      full_name,
      email,
      active,
      student_class_enrollments (
        active,
        class:classes ( name )
      ),
      student_guardians (
        guardian:guardians ( full_name, email, phone, relation )
      )
    `)
    .eq('school_id', schoolId)
    .order('full_name');

  const sheet = workbook.addWorksheet('Alunos');

  const headers = ['Matrícula', 'Nome do Aluno', 'Turma', 'Status', 'Email do Aluno', 'Responsável', 'Email Responsável', 'Telefone Responsável'];
  const widths  = [14,          28,               16,      10,       28,               24,             26,                  20];

  setupSheet(sheet, headers, widths);

  for (const [i, r] of (rows || []).entries()) {
    const enrollment = r.student_class_enrollments?.find(e => e.active);
    const guardian   = r.student_guardians?.[0]?.guardian;

    const row = sheet.addRow([
      r.enrollment_code     || '',
      r.full_name           || '',
      enrollment?.class?.name || '',
      r.active ? 'Ativo' : 'Inativo',
      r.email               || '',
      guardian?.full_name   || '',
      guardian?.email       || '',
      guardian?.phone       || '',
    ]);
    styleRow(row, i);
  }

  applyAutoFilter(sheet, headers.length);
}

// ---------------------------------------------------------------------------
// Aba: Frequência — aluno, turma, total aulas, presenças, percentual
// ---------------------------------------------------------------------------
async function addFrequenciaSheet(workbook, supabase, schoolId, classId, dateFrom, dateTo) {
  let query = supabase
    .from('attendance_records')
    .select(`
      status,
      student:students!inner ( id, enrollment_code, full_name ),
      class:classes!inner    ( id, name )
    `)
    .eq('school_id', schoolId)
    .gte('date', dateFrom)
    .lte('date', dateTo);

  if (classId) query = query.eq('class_id', classId);

  const { data: records } = await query;

  // Agregar por aluno + turma
  const map = new Map();
  for (const r of records || []) {
    const key = `${r.student?.id}_${r.class?.id}`;
    if (!map.has(key)) {
      map.set(key, {
        matricula:    r.student?.enrollment_code,
        aluno:        r.student?.full_name,
        turma:        r.class?.name,
        total_aulas:  0,
        presencas:    0,
        faltas:       0,
        percentual:   0,
      });
    }
    const e = map.get(key);
    e.total_aulas++;
    if (r.status === 'present' || r.status === 'late') e.presencas++;
    else if (r.status === 'absent') e.faltas++;
  }

  // Calcular percentual
  for (const e of map.values()) {
    e.percentual = e.total_aulas > 0
      ? Math.round((e.presencas / e.total_aulas) * 1000) / 10
      : 0;
  }

  const sheet = workbook.addWorksheet('Frequência');
  const headers = ['Matrícula', 'Aluno', 'Turma', 'Total de Aulas', 'Presenças', 'Faltas', 'Percentual (%)'];
  const widths  = [14,          28,      16,       14,               12,          10,        14];

  setupSheet(sheet, headers, widths);

  const sorted = Array.from(map.values()).sort((a, b) => a.percentual - b.percentual);

  for (const [i, r] of sorted.entries()) {
    const row = sheet.addRow([
      r.matricula,
      r.aluno,
      r.turma,
      r.total_aulas,
      r.presencas,
      r.faltas,
      r.percentual / 100,   // formato percentual no Excel
    ]);
    styleRow(row, i);
    row.getCell(7).numFmt = '0.0%';
    // Destacar frequência baixa em vermelho
    if (r.percentual < 75) {
      row.getCell(7).font = { bold: true, color: { argb: 'FFDC2626' } };
    }
  }

  applyAutoFilter(sheet, headers.length);
}

// ---------------------------------------------------------------------------
// Aba: Boletim — aluno, disciplina, média, situação
// ---------------------------------------------------------------------------
async function addBoletimSheet(workbook, supabase, schoolId, classId) {
  const { data: records } = await supabase
    .from('grade_records')
    .select(`
      score,
      max_score,
      grade_type,
      student:students!inner ( id, enrollment_code, full_name ),
      subject:subjects!inner ( id, name ),
      academic_period:academic_periods ( name )
    `)
    .eq('school_id', schoolId)
    .not('score', 'is', null)
    .order('student(full_name)')
    .order('subject(name)');

  // Agregar por aluno + disciplina (média simples ponderada)
  const WEIGHTS = { prova: 0.6, trabalho: 0.3, participacao: 0.1 };
  const map = new Map();

  for (const r of records || []) {
    const key = `${r.student?.id}_${r.subject?.id}`;
    if (!map.has(key)) {
      map.set(key, {
        matricula:  r.student?.enrollment_code,
        aluno:      r.student?.full_name,
        disciplina: r.subject?.name,
        scores:     [],
      });
    }
    const maxScore   = parseFloat(r.max_score) || 10;
    const score      = parseFloat(r.score) || 0;
    const normalized = maxScore > 0 ? (score / maxScore) * 10 : 0;
    const weight     = WEIGHTS[r.grade_type] || 0;
    map.get(key).scores.push({ normalized, weight });
  }

  const sheet = workbook.addWorksheet('Boletim');
  const headers = ['Matrícula', 'Aluno', 'Disciplina', 'Média Ponderada', 'Situação'];
  const widths  = [14,          28,      20,            16,                14];

  setupSheet(sheet, headers, widths);

  const rows = Array.from(map.values()).map(entry => {
    const totalWeight = entry.scores.reduce((s, g) => s + g.weight, 0);
    const weightedSum = entry.scores.reduce((s, g) => s + g.normalized * g.weight, 0);
    const average = totalWeight > 0
      ? Math.round((weightedSum / totalWeight) * 100) / 100
      : null;

    const situacao = average === null ? '—'
      : average >= 6.0 ? 'Aprovado'
      : average >= 4.0 ? 'Em Recuperação'
      : 'Reprovado';

    return { ...entry, average, situacao };
  });

  const situacaoColors = {
    'Aprovado':       'FF86EFAC',
    'Em Recuperação': 'FFFDE68A',
    'Reprovado':      'FFFCA5A5',
  };

  for (const [i, r] of rows.entries()) {
    const row = sheet.addRow([
      r.matricula,
      r.aluno,
      r.disciplina,
      r.average,
      r.situacao,
    ]);
    styleRow(row, i);
    row.getCell(4).numFmt = '0.00';

    const color = situacaoColors[r.situacao];
    if (color) {
      row.getCell(5).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: color } };
    }
  }

  applyAutoFilter(sheet, headers.length);
}

// ---------------------------------------------------------------------------
// Aba: Financeiro — aluno, mensalidade, vencimento, status, valor pago
// ---------------------------------------------------------------------------
async function addFinanceiroSheet(workbook, supabase, schoolId, dateFrom, dateTo) {
  const { data: records } = await supabase
    .from('financial_records')
    .select(`
      description,
      amount,
      due_date,
      paid_date,
      payment_status,
      payment_method,
      student:students!inner ( enrollment_code, full_name )
    `)
    .eq('school_id', schoolId)
    .gte('due_date', dateFrom)
    .lte('due_date', dateTo)
    .order('due_date')
    .order('student(full_name)');

  const sheet = workbook.addWorksheet('Financeiro');
  const headers = ['Matrícula', 'Aluno', 'Mensalidade', 'Vencimento', 'Status', 'Valor (R$)', 'Valor Pago (R$)', 'Data Pagamento', 'Forma Pagamento'];
  const widths  = [14,          28,      24,             12,           12,        14,            14,                14,               16];

  setupSheet(sheet, headers, widths);

  const statusLabels = { pending: 'Pendente', paid: 'Pago', failed: 'Falhou', refunded: 'Estornado' };
  const statusColors = { pending: 'FFFDE68A', paid: 'FF86EFAC', failed: 'FFFCA5A5', refunded: 'FFD1D5DB' };

  for (const [i, r] of (records || []).entries()) {
    const amount    = parseFloat(r.amount) || 0;
    const valorPago = r.payment_status === 'paid' ? amount : 0;

    const row = sheet.addRow([
      r.student?.enrollment_code  || '',
      r.student?.full_name        || '',
      r.description               || '',
      r.due_date  ? new Date(r.due_date  + 'T12:00:00') : null,
      statusLabels[r.payment_status] || r.payment_status,
      amount,
      valorPago,
      r.paid_date ? new Date(r.paid_date + 'T12:00:00') : null,
      r.payment_method            || '',
    ]);
    styleRow(row, i);

    row.getCell(4).numFmt = 'dd/mm/yyyy';
    row.getCell(6).numFmt = 'R$ #,##0.00';
    row.getCell(7).numFmt = 'R$ #,##0.00';
    row.getCell(8).numFmt = 'dd/mm/yyyy';

    const color = statusColors[r.payment_status];
    if (color) {
      row.getCell(5).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: color } };
    }
  }

  applyAutoFilter(sheet, headers.length);
}

// ---------------------------------------------------------------------------
// Helpers compartilhados
// ---------------------------------------------------------------------------

function setupSheet(sheet, headers, widths) {
  sheet.columns = headers.map((h, i) => ({
    header: h,
    width:  widths[i] || 16,
  }));

  const headerRow = sheet.getRow(1);
  headerRow.height = 28;
  headerRow.eachCell(cell => {
    cell.font      = HEADER_FONT;
    cell.fill      = HEADER_FILL;
    cell.alignment = HEADER_ALIGN;
    cell.border    = ALL_BORDERS;
  });
}

function styleRow(row, index) {
  row.height = 18;
  row.eachCell(cell => {
    cell.border    = ALL_BORDERS;
    cell.alignment = { vertical: 'middle' };
    if (index % 2 === 1) cell.fill = ROW_FILL_ALT;
  });
}

function applyAutoFilter(sheet, colCount) {
  sheet.autoFilter = {
    from: { row: 1, column: 1 },
    to:   { row: 1, column: colCount },
  };
}

export default router;
