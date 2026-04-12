/**
 * Lexend Scholar — Export de Dados XLSX para Secretaria
 * GET /api/export/xlsx?type=...&format_opts=...
 *
 * Dependência: npm install exceljs
 *
 * Tipos de export disponíveis (query param `type`):
 *   - students        — cadastro completo de alunos
 *   - attendance      — frequência por aluno/turma/período
 *   - grades          — boletim/notas todos os alunos
 *   - financial       — mensalidades (pago/em atraso/pendente)
 *   - inadimplencia   — relatório de inadimplência
 *   - full            — planilha multi-aba com tudo acima
 *
 * Query params adicionais:
 *   class_id          — filtra por turma
 *   date_start        — início período (YYYY-MM-DD)
 *   date_end          — fim período   (YYYY-MM-DD)
 *   academic_year_id  — filtra por ano letivo
 */

import ExcelJS from 'exceljs';
import { createClient } from '@supabase/supabase-js';

function getSupabase() {
  return createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);
}

// Brand colors
const BRAND_BLUE = '137fec';
const HEADER_FONT = { bold: true, color: { argb: 'FFFFFFFF' }, size: 11, name: 'Calibri' };
const HEADER_FILL = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF' + BRAND_BLUE } };
const HEADER_ALIGN = { vertical: 'middle', horizontal: 'center', wrapText: true };
const BORDER_THIN = { style: 'thin', color: { argb: 'FFE5E7EB' } };
const ALL_BORDERS = { top: BORDER_THIN, left: BORDER_THIN, bottom: BORDER_THIN, right: BORDER_THIN };
const ROW_FILL_ALT = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF9FAFB' } };

export async function xlsxExportHandler(req, res) {
  if (req.method !== 'GET') return res.status(405).end();

  const schoolId = req.session?.schoolId || req.headers['x-school-id'];
  if (!schoolId) return res.status(401).json({ error: 'Não autenticado' });

  const type = req.query?.type || 'full';
  const classId = req.query?.class_id || null;
  const dateStart = req.query?.date_start || `${new Date().getFullYear()}-01-01`;
  const dateEnd = req.query?.date_end || new Date().toISOString().split('T')[0];
  const academicYearId = req.query?.academic_year_id || null;

  const supabase = getSupabase();

  try {
    const { data: school } = await supabase
      .from('schools')
      .select('name')
      .eq('id', schoolId)
      .single();

    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'Lexend Scholar';
    workbook.created = new Date();
    workbook.properties.date1904 = false;

    const exportTypes = type === 'full'
      ? ['students', 'attendance', 'grades', 'financial', 'inadimplencia']
      : [type];

    for (const t of exportTypes) {
      switch (t) {
        case 'students':
          await addStudentsSheet(workbook, supabase, schoolId, classId);
          break;
        case 'attendance':
          await addAttendanceSheet(workbook, supabase, schoolId, classId, dateStart, dateEnd);
          break;
        case 'grades':
          await addGradesSheet(workbook, supabase, schoolId, classId, academicYearId);
          break;
        case 'financial':
          await addFinancialSheet(workbook, supabase, schoolId, dateStart, dateEnd);
          break;
        case 'inadimplencia':
          await addInadimplenciaSheet(workbook, supabase, schoolId);
          break;
      }
    }

    const filename = `lexend_scholar_${type}_${dateEnd}.xlsx`;
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

    await workbook.xlsx.write(res);
    res.end();
  } catch (err) {
    console.error('[XLSX] export error:', err);
    if (!res.headersSent) res.status(500).json({ error: 'Erro ao gerar XLSX' });
  }
}

// ---------------------------------------------------------------------------
// addStudentsSheet — Aba: Alunos
// ---------------------------------------------------------------------------
async function addStudentsSheet(workbook, supabase, schoolId, classId) {
  const { data: rows } = await supabase
    .from('students')
    .select(`
      enrollment_code, full_name, birth_date, gender, cpf, email, phone,
      address, city, state, active,
      student_class_enrollments(
        active,
        class:classes(name, grade:grades(name))
      )
    `)
    .eq('school_id', schoolId)
    .order('full_name');

  const sheet = workbook.addWorksheet('Alunos', { properties: { tabColor: { argb: 'FF' + BRAND_BLUE } } });

  const headers = ['Matrícula', 'Nome Completo', 'Data Nasc.', 'Gênero', 'CPF', 'E-mail', 'Telefone', 'Turma', 'Série', 'Cidade', 'UF', 'Ativo'];
  const widths =  [14,          28,               14,           10,       16,    28,       16,         12,      14,      18,      6,    8];

  setupHeaders(sheet, headers, widths);

  (rows || []).forEach((r, i) => {
    const enrollment = r.student_class_enrollments?.find(e => e.active);
    const row = sheet.addRow([
      r.enrollment_code,
      r.full_name,
      r.birth_date ? new Date(r.birth_date + 'T12:00:00') : null,
      r.gender === 'M' ? 'Masculino' : r.gender === 'F' ? 'Feminino' : 'Outro',
      r.cpf || '',
      r.email || '',
      r.phone || '',
      enrollment?.class?.name || '',
      enrollment?.class?.grade?.name || '',
      r.city || '',
      r.state || '',
      r.active ? 'Sim' : 'Não',
    ]);
    styleDataRow(sheet, row, i);
    // Format date column
    row.getCell(3).numFmt = 'dd/mm/yyyy';
  });

  autoFilter(sheet, headers.length);
}

// ---------------------------------------------------------------------------
// addAttendanceSheet — Aba: Frequência
// ---------------------------------------------------------------------------
async function addAttendanceSheet(workbook, supabase, schoolId, classId, dateStart, dateEnd) {
  let query = supabase
    .from('attendance_records')
    .select(`
      date, status, notes,
      student:students(enrollment_code, full_name),
      class:classes(name, grade:grades(name)),
      subject:subjects(name)
    `)
    .eq('school_id', schoolId)
    .gte('date', dateStart)
    .lte('date', dateEnd)
    .order('date')
    .order('student(full_name)');

  if (classId) query = query.eq('class_id', classId);

  const { data: rows } = await query;

  const sheet = workbook.addWorksheet('Frequência', { properties: { tabColor: { argb: 'FF22C55E' } } });
  const headers = ['Data', 'Turma', 'Série', 'Matrícula', 'Aluno', 'Disciplina', 'Status', 'Observação'];
  const widths =  [12,     12,      12,      14,          28,      20,            14,       28];

  setupHeaders(sheet, headers, widths);

  const statusMap = { present: 'Presente', absent: 'Falta', late: 'Atraso', excused: 'Justificada' };

  (rows || []).forEach((r, i) => {
    const row = sheet.addRow([
      r.date ? new Date(r.date + 'T12:00:00') : null,
      r.class?.name || '',
      r.class?.grade?.name || '',
      r.student?.enrollment_code || '',
      r.student?.full_name || '',
      r.subject?.name || '',
      statusMap[r.status] || r.status,
      r.notes || '',
    ]);
    styleDataRow(sheet, row, i);
    row.getCell(1).numFmt = 'dd/mm/yyyy';

    // Color-code status
    const statusCell = row.getCell(7);
    const colors = { present: 'FF86EFAC', absent: 'FFFCA5A5', late: 'FFFDE68A', excused: 'FFD1D5DB' };
    statusCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: colors[r.status] || 'FFF3F4F6' } };
  });

  autoFilter(sheet, headers.length);
}

// ---------------------------------------------------------------------------
// addGradesSheet — Aba: Notas
// ---------------------------------------------------------------------------
async function addGradesSheet(workbook, supabase, schoolId, classId, academicYearId) {
  const { data: rows } = await supabase
    .from('grade_records')
    .select(`
      score, max_score, grade_type, description,
      student:students(enrollment_code, full_name),
      subject:subjects(name),
      academic_period:academic_periods(name)
    `)
    .eq('school_id', schoolId)
    .order('student(full_name)')
    .order('subject(name)')
    .order('academic_period(name)');

  const sheet = workbook.addWorksheet('Notas', { properties: { tabColor: { argb: 'FFF59E0B' } } });
  const headers = ['Matrícula', 'Aluno', 'Disciplina', 'Período', 'Tipo', 'Nota', 'Nota Máxima', 'Percentual', 'Descrição'];
  const widths =  [14,          28,      20,            14,        12,     8,      12,             12,           24];

  setupHeaders(sheet, headers, widths);

  (rows || []).forEach((r, i) => {
    const score = parseFloat(r.score || 0);
    const max = parseFloat(r.max_score || 10);
    const pct = max > 0 ? +((score / max) * 100).toFixed(1) : 0;

    const row = sheet.addRow([
      r.student?.enrollment_code || '',
      r.student?.full_name || '',
      r.subject?.name || '',
      r.academic_period?.name || '',
      r.grade_type || '',
      score,
      max,
      pct / 100,
      r.description || '',
    ]);
    styleDataRow(sheet, row, i);
    row.getCell(6).numFmt = '0.0';
    row.getCell(7).numFmt = '0.0';
    row.getCell(8).numFmt = '0.0%';

    // Red if below 60%
    if (pct < 60) {
      row.getCell(6).font = { bold: true, color: { argb: 'FFDC2626' } };
    }
  });

  autoFilter(sheet, headers.length);
}

// ---------------------------------------------------------------------------
// addFinancialSheet — Aba: Financeiro
// ---------------------------------------------------------------------------
async function addFinancialSheet(workbook, supabase, schoolId, dateStart, dateEnd) {
  const { data: rows } = await supabase
    .from('financial_records')
    .select(`
      description, amount, due_date, paid_date, payment_status, payment_method, notes,
      student:students(enrollment_code, full_name)
    `)
    .eq('school_id', schoolId)
    .gte('due_date', dateStart)
    .lte('due_date', dateEnd)
    .order('due_date')
    .order('student(full_name)');

  const sheet = workbook.addWorksheet('Financeiro', { properties: { tabColor: { argb: 'FF8B5CF6' } } });
  const headers = ['Matrícula', 'Aluno', 'Descrição', 'Valor (R$)', 'Vencimento', 'Pago em', 'Status', 'Forma Pagto.', 'Obs.'];
  const widths =  [14,          28,      24,           12,           12,           12,         14,        14,             24];

  setupHeaders(sheet, headers, widths);

  const statusLabels = { pending: 'Pendente', paid: 'Pago', failed: 'Falhou', refunded: 'Estornado' };
  const statusColors = { pending: 'FFFDE68A', paid: 'FF86EFAC', failed: 'FFFCA5A5', refunded: 'FFD1D5DB' };

  (rows || []).forEach((r, i) => {
    const row = sheet.addRow([
      r.student?.enrollment_code || '',
      r.student?.full_name || '',
      r.description,
      parseFloat(r.amount),
      r.due_date ? new Date(r.due_date + 'T12:00:00') : null,
      r.paid_date ? new Date(r.paid_date + 'T12:00:00') : null,
      statusLabels[r.payment_status] || r.payment_status,
      r.payment_method || '',
      r.notes || '',
    ]);
    styleDataRow(sheet, row, i);
    row.getCell(4).numFmt = 'R$ #,##0.00';
    row.getCell(5).numFmt = 'dd/mm/yyyy';
    row.getCell(6).numFmt = 'dd/mm/yyyy';
    row.getCell(7).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: statusColors[r.payment_status] || 'FFF3F4F6' } };
  });

  // Summary row
  const data = rows || [];
  const total = data.reduce((s, r) => s + parseFloat(r.amount), 0);
  const paid = data.filter(r => r.payment_status === 'paid').reduce((s, r) => s + parseFloat(r.amount), 0);
  const pending = data.filter(r => r.payment_status === 'pending').reduce((s, r) => s + parseFloat(r.amount), 0);

  sheet.addRow([]);
  const summaryRow = sheet.addRow(['', 'TOTAL', '', total, '', '', '', '', '']);
  summaryRow.getCell(2).font = { bold: true };
  summaryRow.getCell(4).numFmt = 'R$ #,##0.00';
  summaryRow.getCell(4).font = { bold: true, color: { argb: 'FF137FEC' } };

  autoFilter(sheet, headers.length);
}

// ---------------------------------------------------------------------------
// addInadimplenciaSheet — Aba: Inadimplência
// ---------------------------------------------------------------------------
async function addInadimplenciaSheet(workbook, supabase, schoolId) {
  const today = new Date().toISOString().split('T')[0];

  const { data: rows } = await supabase
    .from('financial_records')
    .select(`
      description, amount, due_date, notes,
      student:students(enrollment_code, full_name, email)
    `)
    .eq('school_id', schoolId)
    .eq('payment_status', 'pending')
    .lt('due_date', today)
    .order('due_date');

  const sheet = workbook.addWorksheet('Inadimplência', { properties: { tabColor: { argb: 'FFEF4444' } } });
  const headers = ['Matrícula', 'Aluno', 'E-mail', 'Descrição', 'Valor (R$)', 'Vencimento', 'Dias em Atraso', 'Risco'];
  const widths =  [14,          28,      28,        24,           12,           12,            14,               10];

  setupHeaders(sheet, headers, widths);

  const riskColors = { 'Baixo': 'FFFDE68A', 'Médio': 'FFFBCFB1', 'Alto': 'FFFCA5A5', 'Crítico': 'FFEF4444' };

  (rows || []).forEach((r, i) => {
    const days = Math.floor((new Date(today) - new Date(r.due_date)) / 86400000);
    const risco = days <= 30 ? 'Baixo' : days <= 60 ? 'Médio' : days <= 90 ? 'Alto' : 'Crítico';

    const row = sheet.addRow([
      r.student?.enrollment_code || '',
      r.student?.full_name || '',
      r.student?.email || '',
      r.description,
      parseFloat(r.amount),
      r.due_date ? new Date(r.due_date + 'T12:00:00') : null,
      days,
      risco,
    ]);
    styleDataRow(sheet, row, i);
    row.getCell(5).numFmt = 'R$ #,##0.00';
    row.getCell(6).numFmt = 'dd/mm/yyyy';
    row.getCell(8).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: riskColors[risco] } };
    if (risco === 'Crítico') row.getCell(8).font = { bold: true, color: { argb: 'FFFFFFFF' } };
  });

  autoFilter(sheet, headers.length);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function setupHeaders(sheet, headers, widths) {
  sheet.columns = headers.map((h, i) => ({ header: h, width: widths[i] || 16 }));
  const headerRow = sheet.getRow(1);
  headerRow.height = 28;
  headerRow.eachCell(cell => {
    cell.font = HEADER_FONT;
    cell.fill = HEADER_FILL;
    cell.alignment = HEADER_ALIGN;
    cell.border = ALL_BORDERS;
  });
}

function styleDataRow(sheet, row, index) {
  row.height = 18;
  row.eachCell(cell => {
    cell.border = ALL_BORDERS;
    cell.alignment = { vertical: 'middle' };
    if (index % 2 === 1) cell.fill = ROW_FILL_ALT;
  });
}

function autoFilter(sheet, colCount) {
  sheet.autoFilter = {
    from: { row: 1, column: 1 },
    to: { row: 1, column: colCount },
  };
}
