/**
 * declaracoes-pdf.js — /api/declaracoes-pdf  (also routed as /api/declaracoes/pdf)
 * Lexend Scholar — Emissão de declarações escolares.
 *
 * ─── Rotas ───────────────────────────────────────────────────────────────────
 * POST /api/declaracoes-pdf
 *   Body: { student_id | aluno_id, type | tipo, academic_year_id?, custom_text?, finalidade? }
 *
 * GET  /api/declaracoes-pdf?tipo=matricula&aluno_id=UUID[&academic_year_id=UUID]
 *   Equivalente ao POST, conveniente para chamada direta de browser.
 *
 * Tipos suportados:
 *   'matricula' | 'frequencia' | 'conclusao' | 'transferencia' | 'personalizada'
 *
 * ─── Resposta ────────────────────────────────────────────────────────────────
 * Se jspdf estiver disponível:
 *   { pdf_base64: "<base64>", filename: "declaracao_matricula_nome_ts.pdf" }
 *
 * Se jspdf não estiver disponível (fallback HTML):
 *   Content-Type: text/html  — documento HTML pronto para Ctrl+P / window.print()
 *
 * ─── Campos do documento ─────────────────────────────────────────────────────
 *   - Nome completo do aluno
 *   - RG / CPF
 *   - Turma e série
 *   - Ano letivo
 *   - Data atual de emissão
 *   - Assinatura / carimbo da direção
 *   - Finalidade (opcional)
 *
 * Roles permitidos: admin, secretary
 */

import { authenticateRequest, apiError } from './_middleware.js';
import { supabase } from './_supabase.js';

// jsPDF is optional — gracefully degrade to HTML if unavailable
let jsPDF = null;
try {
  const mod = await import('jspdf');
  jsPDF = mod.jsPDF;
} catch (_) {
  // Will fall back to HTML output
}

const ALLOWED_ROLES     = ['admin', 'secretary'];
const DECLARATION_TYPES = ['matricula', 'frequencia', 'conclusao', 'transferencia', 'personalizada'];

export default async function handler(req, res) {
  // ── Auth ──────────────────────────────────────────────────────────────────
  await new Promise((resolve, reject) => {
    authenticateRequest(req, res, (err) => (err ? reject(err) : resolve()));
  });

  if (!ALLOWED_ROLES.includes(req.user.role)) {
    return apiError(res, 403, 'Apenas admin e secretaria podem emitir declarações', 'FORBIDDEN');
  }

  if (req.method !== 'POST' && req.method !== 'GET') {
    return apiError(res, 405, 'Método não permitido', 'METHOD_NOT_ALLOWED');
  }

  const { school_id } = req.user;

  // ── Resolve params from body (POST) or query string (GET) ────────────────
  const source = req.method === 'GET' ? req.query : req.body;

  const student_id      = source.aluno_id      || source.student_id;
  const tipo            = source.tipo          || source.type;
  const academic_year_id = source.academic_year_id || null;
  const custom_text     = source.custom_text   || null;
  const finalidade      = source.finalidade    || null;

  // ── Validate ──────────────────────────────────────────────────────────────
  if (!student_id || !tipo) {
    return apiError(
      res, 400,
      'Parâmetros obrigatórios: aluno_id (ou student_id), tipo (ou type)',
      'VALIDATION_ERROR'
    );
  }
  if (!DECLARATION_TYPES.includes(tipo)) {
    return apiError(
      res, 400,
      `tipo deve ser: ${DECLARATION_TYPES.join(', ')}`,
      'VALIDATION_ERROR'
    );
  }

  // ── Fetch data ────────────────────────────────────────────────────────────
  const [studentResult, schoolResult] = await Promise.all([
    supabase
      .from('students')
      .select(`
        id, full_name, enrollment_code, birth_date, cpf, rg,
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
      .select('id, name, address, city, state, zip_code, cnpj, phone, email')
      .eq('id', school_id)
      .single(),
  ]);

  if (studentResult.error || !studentResult.data) {
    return apiError(res, 404, 'Aluno não encontrado ou inativo', 'STUDENT_NOT_FOUND');
  }
  if (schoolResult.error || !schoolResult.data) {
    return apiError(res, 500, 'Erro ao carregar dados da escola', 'DB_ERROR');
  }

  const student = studentResult.data;
  const school  = schoolResult.data;

  // Resolve active enrollment — prefer the one matching academic_year_id if given
  const enrollments = student.class_enrollments || [];
  let currentEnrollment = enrollments[enrollments.length - 1] || null;
  if (academic_year_id && enrollments.length > 1) {
    const byYear = enrollments.find(
      (e) => e.class?.academic_year?.id === academic_year_id
    );
    if (byYear) currentEnrollment = byYear;
  }

  const cls          = currentEnrollment?.class         || null;
  const grade        = cls?.grade                        || null;
  const academicYear = cls?.academic_year                || null;

  // ── Attendance rate (for frequencia declaration) ──────────────────────────
  let attendanceRate = null;
  if (tipo === 'frequencia' && cls?.id) {
    const { data: records } = await supabase
      .from('attendance_records')
      .select('status')
      .eq('student_id', student_id)
      .eq('school_id', school_id)
      .eq('class_id', cls.id);

    if (records && records.length > 0) {
      const present = records.filter(
        (r) => r.status === 'present' || r.status === 'late'
      ).length;
      attendanceRate = Math.round((present / records.length) * 100);
    }
  }

  // ── Build context object ──────────────────────────────────────────────────
  const issuedAt = new Date();
  const ctx = {
    studentName:    student.full_name,
    cpf:            student.cpf,
    rg:             student.rg,
    enrollment:     student.enrollment_code,
    className:      cls?.name     || '',
    grade:          grade?.name   || '',
    academicYear:   academicYear?.name || String(new Date().getFullYear()),
    attendanceRate,
    customText:     custom_text,
    finalidade,
    school,
    issuedAt,
  };

  const slugName = student.full_name
    .toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, '_')
    .slice(0, 30);
  const filename = `declaracao_${tipo}_${slugName}_${Date.now()}.pdf`;

  // ── Audit log — best-effort ───────────────────────────────────────────────
  void supabase.from('document_emissions').insert({
    school_id,
    student_id,
    type:      tipo,
    filename,
    issued_by: req.user.id,
    issued_at: issuedAt.toISOString(),
  });

  // ── Generate output ───────────────────────────────────────────────────────
  if (jsPDF) {
    // PDF via jsPDF
    const pdfBase64 = generatePDF(tipo, ctx);
    return res.status(200).json({ pdf_base64: pdfBase64, filename });
  }

  // Fallback: return printable HTML
  const html = generateHTMLDeclaracao(tipo, ctx);
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader(
    'Content-Disposition',
    `inline; filename="${filename.replace('.pdf', '.html')}"`
  );
  return res.status(200).send(html);
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF generation (jsPDF)
// ─────────────────────────────────────────────────────────────────────────────

const PT_DATE = new Intl.DateTimeFormat('pt-BR', {
  day: '2-digit', month: 'long', year: 'numeric',
});

const TITLE_MAP = {
  matricula:     'DECLARAÇÃO DE MATRÍCULA',
  frequencia:    'DECLARAÇÃO DE FREQUÊNCIA',
  conclusao:     'DECLARAÇÃO DE CONCLUSÃO',
  transferencia: 'DECLARAÇÃO DE TRANSFERÊNCIA',
  personalizada: 'DECLARAÇÃO',
};

function buildBodyText(tipo, ctx) {
  const {
    studentName, cpf, rg, className, grade, academicYear,
    attendanceRate, customText, finalidade,
  } = ctx;

  const finalidadeClause = finalidade
    ? ` Esta declaração é expedida a pedido do(a) interessado(a) para fins de: ${finalidade}.`
    : ' Esta declaração é expedida a pedido do(a) interessado(a) para os fins que se fizerem necessários.';

  const identDoc = rg
    ? `portador(a) do RG ${rg}${cpf ? ` e CPF ${cpf}` : ''}`
    : cpf
      ? `portador(a) do CPF ${cpf}`
      : '';

  switch (tipo) {
    case 'matricula':
      return (
        `Declaramos, para os devidos fins, que ${studentName}` +
        (identDoc ? `, ${identDoc},` : ',') +
        ` encontra-se devidamente matriculado(a) nesta instituição de ensino` +
        (grade ? ` na ${grade}` : '') +
        (className ? `, turma ${className},` : ',') +
        (academicYear ? ` no ano letivo de ${academicYear}.` : '.') +
        ` A matrícula encontra-se em situação regular.${finalidadeClause}`
      );

    case 'frequencia':
      return (
        `Declaramos que ${studentName}, matriculado(a) na ${grade || 'turma'} ${className || ''}` +
        ` no ano letivo de ${academicYear}, apresentou frequência de ` +
        (attendanceRate !== null ? `${attendanceRate}%` : 'dados não disponíveis') +
        ` no período letivo corrente.${finalidadeClause}`
      );

    case 'conclusao':
      return (
        `Declaramos que ${studentName} concluiu com êxito o ${grade || 'ano letivo'} ` +
        `no ano de ${academicYear} nesta instituição, ` +
        `tendo cumprido todos os requisitos curriculares exigidos.${finalidadeClause}`
      );

    case 'transferencia':
      return (
        `Declaramos que ${studentName}` +
        (identDoc ? `, ${identDoc},` : ',') +
        ` era aluno(a) regularmente matriculado(a) nesta instituição e encontra-se em processo ` +
        `de transferência. O(a) referido(a) aluno(a) não possui débitos ou pendências junto a esta escola.` +
        finalidadeClause
      );

    case 'personalizada':
      return customText || 'Declaramos, para os devidos fins, o que foi solicitado.' + finalidadeClause;

    default:
      return '';
  }
}

function generatePDF(tipo, ctx) {
  const { school, issuedAt } = ctx;
  const doc     = new jsPDF({ unit: 'mm', format: 'a4', orientation: 'portrait' });
  const pageW   = doc.internal.pageSize.getWidth();
  const margin  = 25;
  const contentW = pageW - margin * 2;

  const bodyText = buildBodyText(tipo, ctx);
  const dateStr  = PT_DATE.format(issuedAt);
  const cityStr  = school.city && school.state
    ? `${school.city} - ${school.state}`
    : 'Local não informado';

  // Header — school name
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
    doc.text(
      [school.address, school.city && school.state ? `${school.city} - ${school.state}` : '']
        .filter(Boolean).join(' — '),
      pageW / 2, 39, { align: 'center' }
    );
  }

  // Divider
  doc.setDrawColor(180);
  doc.line(margin, 44, pageW - margin, 44);

  // Title
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(13);
  doc.setTextColor(0);
  doc.text(TITLE_MAP[tipo] || 'DECLARAÇÃO', pageW / 2, 58, { align: 'center' });

  // Body
  doc.setFont('helvetica', 'normal');
  doc.setFontSize(11);
  doc.setTextColor(30);

  const lines       = doc.splitTextToSize(bodyText, contentW);
  const bodyStartY  = 75;
  doc.text(lines, margin, bodyStartY, { lineHeightFactor: 1.6 });

  const bodyHeightMM = lines.length * 11 * 0.3528 * 1.6;

  // Closing sentence
  const closingY = bodyStartY + bodyHeightMM + 15;
  doc.setFontSize(11);
  doc.text('Por ser verdade, firmamos a presente declaração.', pageW / 2, closingY, { align: 'center' });

  const dateY = closingY + 10;
  doc.text(`${cityStr}, ${dateStr}.`, pageW / 2, dateY, { align: 'center' });

  // Signature line
  const sigY = dateY + 25;
  doc.line(pageW / 2 - 40, sigY, pageW / 2 + 40, sigY);
  doc.setFontSize(9);
  doc.setTextColor(80);
  doc.text('Direção / Secretaria', pageW / 2, sigY + 5, { align: 'center' });
  doc.text(school.name, pageW / 2, sigY + 10, { align: 'center' });

  // Footer
  doc.setFontSize(8);
  doc.setTextColor(150);
  doc.text(
    `Documento emitido em ${dateStr} pelo sistema Lexend Scholar`,
    pageW / 2,
    doc.internal.pageSize.getHeight() - 10,
    { align: 'center' }
  );

  return doc.output('datauristring').split(',')[1]; // base64
}

// ─────────────────────────────────────────────────────────────────────────────
// HTML fallback — printable, no external dependencies
// ─────────────────────────────────────────────────────────────────────────────

function generateHTMLDeclaracao(tipo, ctx) {
  const { school, issuedAt, studentName, rg, cpf, enrollment } = ctx;
  const bodyText = buildBodyText(tipo, ctx);
  const dateStr  = PT_DATE.format(issuedAt);
  const cityStr  = school.city && school.state ? `${school.city} - ${school.state}` : '';
  const title    = TITLE_MAP[tipo] || 'DECLARAÇÃO';

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} — ${studentName}</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Times New Roman', Times, serif;
      font-size: 12pt;
      color: #1a1a1a;
      background: #fff;
      padding: 0;
    }
    .page {
      width: 210mm;
      min-height: 297mm;
      margin: 0 auto;
      padding: 25mm 25mm 20mm 25mm;
      position: relative;
    }
    .header { text-align: center; margin-bottom: 6mm; }
    .school-name {
      font-size: 14pt;
      font-weight: bold;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .school-meta {
      font-size: 9pt;
      color: #555;
      margin-top: 2mm;
    }
    hr.divider {
      border: none;
      border-top: 1px solid #bbb;
      margin: 5mm 0;
    }
    .doc-title {
      text-align: center;
      font-size: 13pt;
      font-weight: bold;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin: 10mm 0 8mm;
    }
    .body-text {
      line-height: 1.9;
      text-align: justify;
      margin-bottom: 8mm;
      font-size: 11pt;
    }
    .closing {
      text-align: center;
      margin-top: 12mm;
      font-size: 11pt;
    }
    .date-place {
      text-align: center;
      margin-top: 4mm;
      font-size: 11pt;
    }
    .signature-block {
      text-align: center;
      margin-top: 20mm;
    }
    .sig-line {
      display: inline-block;
      width: 80mm;
      border-top: 1px solid #333;
      margin-bottom: 3mm;
    }
    .sig-label { font-size: 9pt; color: #444; }
    .footer {
      position: absolute;
      bottom: 10mm;
      left: 25mm;
      right: 25mm;
      text-align: center;
      font-size: 8pt;
      color: #aaa;
    }
    @media print {
      body { background: #fff; }
      .page { padding: 20mm; }
      .no-print { display: none; }
    }
  </style>
</head>
<body>
  <div class="no-print" style="background:#f0f4ff;padding:10px 20px;text-align:center;font-family:sans-serif;font-size:13px">
    Para salvar como PDF: pressione <strong>Ctrl+P</strong> (ou ⌘+P no Mac) e escolha <em>Salvar como PDF</em>.
    <button onclick="window.print()" style="margin-left:12px;padding:5px 14px;cursor:pointer">Imprimir / Salvar PDF</button>
  </div>

  <div class="page">
    <div class="header">
      <div class="school-name">${escHtml(school.name)}</div>
      <div class="school-meta">
        ${school.cnpj ? `CNPJ: ${escHtml(school.cnpj)}` : ''}
        ${school.cnpj && school.address ? ' &nbsp;|&nbsp; ' : ''}
        ${school.address ? escHtml(school.address) : ''}
        ${cityStr ? ` — ${escHtml(cityStr)}` : ''}
      </div>
      ${school.phone ? `<div class="school-meta">Tel: ${escHtml(school.phone)}${school.email ? ` &nbsp;|&nbsp; ${escHtml(school.email)}` : ''}</div>` : ''}
    </div>

    <hr class="divider">

    <div class="doc-title">${escHtml(title)}</div>

    <div class="body-text">${escHtml(bodyText)}</div>

    <div class="closing">Por ser verdade, firmamos a presente declaração.</div>
    <div class="date-place">${cityStr ? escHtml(cityStr) + ', ' : ''}${escHtml(dateStr)}.</div>

    <div class="signature-block">
      <div class="sig-line"></div><br>
      <div class="sig-label">Direção / Secretaria</div>
      <div class="sig-label">${escHtml(school.name)}</div>
    </div>

    <div class="footer">
      Documento emitido em ${escHtml(dateStr)} pelo sistema Lexend Scholar
      &nbsp;|&nbsp; Matrícula: ${escHtml(enrollment || '—')}
    </div>
  </div>
</body>
</html>`;
}

function escHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
