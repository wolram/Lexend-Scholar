/**
 * declaracoes-pdf.js — /api/declaracoes-pdf
 * Lexend Scholar — Emissão de declarações escolares em PDF via jsPDF.
 *
 * POST /api/declaracoes-pdf
 *   Body: { student_id, type, academic_year_id?, custom_text? }
 *
 *   type: 'matricula' | 'frequencia' | 'conclusao' | 'transferencia' | 'personalizada'
 *
 * Resposta: { pdf_base64, filename }
 *   O cliente pode criar um Blob e acionar download:
 *   const blob = new Blob([atob(pdf_base64)], { type: 'application/pdf' });
 *   const url = URL.createObjectURL(blob);
 *
 * Roles permitidos: admin, secretary
 *
 * Dependência de runtime: jspdf (instalar via npm install jspdf)
 */

import { authenticateRequest, apiError } from './_middleware.js';
import { supabase } from './_supabase.js';
import { jsPDF } from 'jspdf';

const ALLOWED_ROLES = ['admin', 'secretary'];

const DECLARATION_TYPES = ['matricula', 'frequencia', 'conclusao', 'transferencia', 'personalizada'];

export default async function handler(req, res) {
  await new Promise((resolve, reject) => {
    authenticateRequest(req, res, (err) => (err ? reject(err) : resolve()));
  });

  if (!ALLOWED_ROLES.includes(req.user.role)) {
    return apiError(res, 403, 'Apenas admin e secretaria podem emitir declarações', 'FORBIDDEN');
  }

  if (req.method !== 'POST') {
    return apiError(res, 405, 'Método não permitido', 'METHOD_NOT_ALLOWED');
  }

  const { school_id } = req.user;
  const { student_id, type, academic_year_id, custom_text } = req.body;

  // Validation
  if (!student_id || !type) {
    return apiError(res, 400, 'Campos obrigatórios: student_id, type', 'VALIDATION_ERROR');
  }
  if (!DECLARATION_TYPES.includes(type)) {
    return apiError(res, 400, `type deve ser: ${DECLARATION_TYPES.join(', ')}`, 'VALIDATION_ERROR');
  }

  // -------------------------------------------------------------------------
  // Fetch student + school data
  // -------------------------------------------------------------------------
  const [studentResult, schoolResult] = await Promise.all([
    supabase
      .from('students')
      .select(`
        id, full_name, enrollment_code, birth_date, cpf,
        class_enrollments:student_class_enrollments(
          class:classes(
            id, name,
            grade:grades(name, level),
            academic_year:academic_years(name, start_date, end_date)
          )
        )
      `)
      .eq('id', student_id)
      .eq('school_id', school_id)
      .eq('active', true)
      .single(),

    supabase
      .from('schools')
      .select('name, address, city, state, cnpj, phone, email')
      .eq('id', school_id)
      .single(),
  ]);

  if (studentResult.error || !studentResult.data) {
    return apiError(res, 404, 'Aluno não encontrado', 'STUDENT_NOT_FOUND');
  }
  if (schoolResult.error || !schoolResult.data) {
    return apiError(res, 500, 'Erro ao carregar dados da escola', 'DB_ERROR');
  }

  const student = studentResult.data;
  const school  = schoolResult.data;

  // Resolve current enrollment (most recent active class)
  const enrollments = student.class_enrollments || [];
  const currentEnrollment = enrollments[enrollments.length - 1] || null;
  const cls  = currentEnrollment?.class;
  const grade = cls?.grade;
  const academicYear = cls?.academic_year;

  // -------------------------------------------------------------------------
  // Fetch attendance rate (for frequencia declaration)
  // -------------------------------------------------------------------------
  let attendanceRate = null;
  if (type === 'frequencia' && cls?.id) {
    const { data: attendanceData } = await supabase
      .from('attendance_records')
      .select('status')
      .eq('student_id', student_id)
      .eq('school_id', school_id)
      .eq('class_id', cls.id);

    if (attendanceData && attendanceData.length > 0) {
      const present = attendanceData.filter(
        (r) => r.status === 'present' || r.status === 'late'
      ).length;
      attendanceRate = Math.round((present / attendanceData.length) * 100);
    }
  }

  // -------------------------------------------------------------------------
  // Generate PDF
  // -------------------------------------------------------------------------
  const pdfBase64 = generateDeclarationPDF({
    type,
    student,
    school,
    cls,
    grade,
    academicYear,
    attendanceRate,
    customText: custom_text,
    issuedAt: new Date(),
  });

  const slugName = student.full_name.toLowerCase().replace(/\s+/g, '_').slice(0, 30);
  const filename = `declaracao_${type}_${slugName}_${Date.now()}.pdf`;

  // Optionally log the emission in an audit table
  await supabase.from('document_emissions').insert({
    school_id,
    student_id,
    type,
    filename,
    issued_by: req.user.id,
    issued_at: new Date().toISOString(),
  }).then(() => {}); // best-effort, ignore errors

  return res.status(200).json({ pdf_base64: pdfBase64, filename });
}

// ---------------------------------------------------------------------------
// PDF generation
// ---------------------------------------------------------------------------

const PT_BR_DATE = new Intl.DateTimeFormat('pt-BR', {
  day: '2-digit', month: 'long', year: 'numeric',
});

const DECLARATION_TEMPLATES = {
  matricula: (ctx) =>
    `Declaramos, para os devidos fins, que ${ctx.studentName}, ` +
    `portador(a) do CPF ${ctx.cpf || 'não informado'}, ` +
    `encontra-se devidamente matriculado(a) nesta instituição de ensino ` +
    `${ctx.grade ? `na ${ctx.grade}, turma ${ctx.className}` : ''} ` +
    `${ctx.academicYear ? `, no ano letivo de ${ctx.academicYear}` : ''}. ` +
    `A matrícula encontra-se em situação regular.`,

  frequencia: (ctx) =>
    `Declaramos, para os devidos fins, que ${ctx.studentName}, ` +
    `matriculado(a) na ${ctx.grade || 'turma'} ${ctx.className || ''}, ` +
    `apresentou frequência de ${ctx.attendanceRate !== null ? ctx.attendanceRate + '%' : 'dados não disponíveis'} ` +
    `no período letivo corrente do ano de ${ctx.academicYear || new Date().getFullYear()}.`,

  conclusao: (ctx) =>
    `Declaramos que ${ctx.studentName} concluiu com êxito o ${ctx.grade || 'ano letivo'} ` +
    `no ano de ${ctx.academicYear || new Date().getFullYear()} nesta instituição de ensino, ` +
    `tendo cumprido todos os requisitos curriculares exigidos.`,

  transferencia: (ctx) =>
    `Declaramos que ${ctx.studentName}, portador(a) do CPF ${ctx.cpf || 'não informado'}, ` +
    `era aluno(a) regularmente matriculado(a) nesta instituição e encontra-se em processo de transferência. ` +
    `O(a) referido(a) aluno(a) não possui débitos ou pendências junto a esta escola.`,

  personalizada: (ctx) => ctx.customText || 'Declaramos, para os devidos fins, o que foi solicitado.',
};

/**
 * Generates the declaration PDF and returns it as a base64 string.
 */
function generateDeclarationPDF({
  type, student, school, cls, grade, academicYear,
  attendanceRate, customText, issuedAt,
}) {
  const doc = new jsPDF({ unit: 'mm', format: 'a4', orientation: 'portrait' });
  const pageW = doc.internal.pageSize.getWidth();
  const margin = 25;
  const contentW = pageW - margin * 2;

  const ctx = {
    studentName:  student.full_name,
    cpf:          student.cpf,
    enrollment:   student.enrollment_code,
    className:    cls?.name || '',
    grade:        grade?.name || '',
    academicYear: academicYear?.name || '',
    attendanceRate,
    customText,
  };

  const bodyText = DECLARATION_TEMPLATES[type]?.(ctx) || DECLARATION_TEMPLATES.personalizada(ctx);
  const dateStr  = PT_BR_DATE.format(issuedAt);
  const cityStr  = school.city && school.state
    ? `${school.city} - ${school.state}`
    : 'Local não informado';

  // ---- Header ----
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(14);
  doc.text(school.name.toUpperCase(), pageW / 2, 28, { align: 'center' });

  if (school.cnpj) {
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.setTextColor(100);
    doc.text(`CNPJ: ${school.cnpj}`, pageW / 2, 34, { align: 'center' });
  }

  if (school.address) {
    doc.setFontSize(9);
    doc.text(school.address, pageW / 2, 39, { align: 'center' });
  }

  // ---- Divider ----
  doc.setDrawColor(180);
  doc.line(margin, 44, pageW - margin, 44);

  // ---- Title ----
  const titleMap = {
    matricula:    'DECLARAÇÃO DE MATRÍCULA',
    frequencia:   'DECLARAÇÃO DE FREQUÊNCIA',
    conclusao:    'DECLARAÇÃO DE CONCLUSÃO',
    transferencia:'DECLARAÇÃO DE TRANSFERÊNCIA',
    personalizada:'DECLARAÇÃO',
  };

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(13);
  doc.setTextColor(0);
  doc.text(titleMap[type] || 'DECLARAÇÃO', pageW / 2, 58, { align: 'center' });

  // ---- Body ----
  doc.setFont('helvetica', 'normal');
  doc.setFontSize(11);
  doc.setTextColor(30);

  const lines = doc.splitTextToSize(bodyText, contentW);
  doc.text(lines, margin, 75, { lineHeightFactor: 1.6 });

  const bodyHeight = lines.length * 11 * 0.3528 * 1.6; // approximate mm

  // ---- Closing ----
  const closingY = 75 + bodyHeight + 15;
  doc.setFontSize(11);
  doc.text(
    `Por ser verdade, firmamos a presente declaração.`,
    pageW / 2,
    closingY,
    { align: 'center' }
  );

  const dateY = closingY + 10;
  doc.text(`${cityStr}, ${dateStr}.`, pageW / 2, dateY, { align: 'center' });

  // ---- Signature line ----
  const sigY = dateY + 25;
  doc.line(pageW / 2 - 35, sigY, pageW / 2 + 35, sigY);
  doc.setFontSize(9);
  doc.setTextColor(80);
  doc.text('Direção / Secretaria', pageW / 2, sigY + 5, { align: 'center' });
  doc.text(school.name, pageW / 2, sigY + 10, { align: 'center' });

  // ---- Footer ----
  doc.setFontSize(8);
  doc.setTextColor(150);
  doc.text(
    `Documento emitido em ${dateStr} pelo sistema Lexend Scholar`,
    pageW / 2,
    doc.internal.pageSize.getHeight() - 10,
    { align: 'center' }
  );

  return doc.output('datauristring').split(',')[1]; // base64 only
}
