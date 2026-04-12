/**
 * Lexend Scholar — Boletim Escolar
 *
 * GET /reports/academic/report-card?student_id=&period=
 *
 * Query params:
 *   student_id          — UUID do aluno (obrigatório)
 *   period              — UUID do período letivo (academic_period_id) (obrigatório)
 *
 * Retorna JSON estruturado para geração de PDF:
 *   { student, school, period, subjects: [{ name, grades: [...], average, status }], overall_status }
 *
 * Pesos por tipo: prova=0.6, trabalho=0.3, participacao=0.1
 * Situação: aprovado >= 6.0, recuperação 4.0–5.9, reprovado < 4.0
 *
 * Tabelas usadas (database_schema.sql):
 *   grade_records, subjects, students, schools, academic_periods
 */

import express from 'express';
import { createClient } from '@supabase/supabase-js';

const router = express.Router();

const GRADE_WEIGHTS = {
  prova:        0.60,
  trabalho:     0.30,
  participacao: 0.10,
};

function getSupabase() {
  return createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY
  );
}

/**
 * GET /reports/academic/report-card
 */
router.get('/', async (req, res) => {
  const schoolId = req.session?.schoolId || req.headers['x-school-id'];
  if (!schoolId) {
    return res.status(401).json({ error: 'Não autenticado' });
  }

  const { student_id: studentId, period: periodId } = req.query;

  if (!studentId) {
    return res.status(400).json({ error: 'Parâmetro obrigatório: student_id' });
  }
  if (!periodId) {
    return res.status(400).json({ error: 'Parâmetro obrigatório: period (academic_period_id)' });
  }

  const supabase = getSupabase();

  try {
    // 1. Buscar dados do aluno
    const { data: student, error: studentErr } = await supabase
      .from('students')
      .select('id, full_name, enrollment_code, email')
      .eq('id', studentId)
      .eq('school_id', schoolId)
      .single();

    if (studentErr || !student) {
      return res.status(404).json({ error: 'Aluno não encontrado' });
    }

    // 2. Buscar dados da escola
    const { data: school } = await supabase
      .from('schools')
      .select('id, name')
      .eq('id', schoolId)
      .single();

    // 3. Buscar dados do período
    const { data: period } = await supabase
      .from('academic_periods')
      .select('id, name, start_date, end_date')
      .eq('id', periodId)
      .eq('school_id', schoolId)
      .single();

    if (!period) {
      return res.status(404).json({ error: 'Período letivo não encontrado' });
    }

    // 4. Buscar notas do aluno no período
    const { data: grades, error: gradesErr } = await supabase
      .from('grade_records')
      .select(`
        id,
        score,
        max_score,
        grade_type,
        description,
        subject:subjects!inner ( id, name, code )
      `)
      .eq('school_id', schoolId)
      .eq('student_id', studentId)
      .eq('academic_period_id', periodId)
      .not('score', 'is', null)
      .order('created_at', { ascending: true });

    if (gradesErr) {
      console.error('[Boletim] grades query error:', gradesErr);
      return res.status(500).json({ error: 'Erro ao buscar notas' });
    }

    // 5. Agrupar notas por disciplina e calcular médias ponderadas
    const subjectMap = new Map();

    for (const grade of grades || []) {
      const subjectId = grade.subject?.id;
      if (!subjectId) continue;

      if (!subjectMap.has(subjectId)) {
        subjectMap.set(subjectId, {
          id:     subjectId,
          name:   grade.subject.name,
          code:   grade.subject.code || null,
          grades: [],
        });
      }

      // Normalizar nota para escala 0-10
      const maxScore      = parseFloat(grade.max_score) || 10;
      const score         = parseFloat(grade.score) || 0;
      const normalized    = maxScore > 0 ? (score / maxScore) * 10 : 0;
      const weight        = GRADE_WEIGHTS[grade.grade_type] || 0;

      subjectMap.get(subjectId).grades.push({
        id:          grade.id,
        type:        grade.grade_type,
        description: grade.description || null,
        score:       Math.round(score * 100) / 100,
        max_score:   maxScore,
        normalized:  Math.round(normalized * 100) / 100,
        weight,
      });
    }

    // 6. Calcular média ponderada e situação por disciplina
    const subjects = [];
    let totalWeightedAvg = 0;
    let subjectCount = 0;

    for (const subjectData of subjectMap.values()) {
      const { grades: subGrades } = subjectData;

      // Somar pesos disponíveis
      const totalWeight = subGrades.reduce((sum, g) => sum + g.weight, 0);
      const weightedSum = subGrades.reduce((sum, g) => sum + g.normalized * g.weight, 0);

      const average = totalWeight > 0
        ? Math.round((weightedSum / totalWeight) * 100) / 100
        : null;

      const status = average === null ? null
        : average >= 6.0 ? 'aprovado'
        : average >= 4.0 ? 'recuperacao'
        : 'reprovado';

      subjects.push({
        name:    subjectData.name,
        code:    subjectData.code,
        grades:  subGrades,
        average,
        status,
      });

      if (average !== null) {
        totalWeightedAvg += average;
        subjectCount++;
      }
    }

    // Ordenar por nome de disciplina
    subjects.sort((a, b) => a.name.localeCompare(b.name, 'pt-BR'));

    // 7. Situação geral do aluno
    const overallAverage = subjectCount > 0
      ? Math.round((totalWeightedAvg / subjectCount) * 100) / 100
      : null;

    const hasReprovado    = subjects.some(s => s.status === 'reprovado');
    const hasRecuperacao  = subjects.some(s => s.status === 'recuperacao');
    const overallStatus   = hasReprovado    ? 'reprovado'
                          : hasRecuperacao  ? 'recuperacao'
                          : 'aprovado';

    return res.status(200).json({
      student: {
        id:              student.id,
        full_name:       student.full_name,
        enrollment_code: student.enrollment_code,
        email:           student.email,
      },
      school: {
        id:   school?.id,
        name: school?.name,
      },
      period: {
        id:         period.id,
        name:       period.name,
        start_date: period.start_date,
        end_date:   period.end_date,
      },
      subjects,
      overall_average: overallAverage,
      overall_status:  overallStatus,
      generated_at:    new Date().toISOString(),
    });
  } catch (err) {
    console.error('[Boletim] report error:', err);
    return res.status(500).json({ error: 'Erro interno ao gerar boletim' });
  }
});

export default router;
