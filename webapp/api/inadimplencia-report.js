/**
 * Lexend Scholar — Relatório de Inadimplência Financeira
 *
 * GET /reports/finance/delinquency
 *
 * Query params (opcionais):
 *   class_id  — filtrar por turma (UUID)
 *   min_days  — dias mínimos de atraso (default: 1)
 *
 * Retorna:
 *   { total_overdue, total_amount, students: [...] }
 *
 * Tabelas usadas (database_schema.sql):
 *   financial_records, students, student_class_enrollments, classes
 */

import express from 'express';
import { createClient } from '@supabase/supabase-js';

const router = express.Router();

function getSupabase() {
  return createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY
  );
}

/**
 * GET /reports/finance/delinquency
 */
router.get('/', async (req, res) => {
  const schoolId = req.session?.schoolId || req.headers['x-school-id'];
  if (!schoolId) {
    return res.status(401).json({ error: 'Não autenticado' });
  }

  const minDays = parseInt(req.query.min_days || '1', 10);
  const classId = req.query.class_id || null;

  const supabase = getSupabase();
  const today = new Date().toISOString().split('T')[0];

  try {
    // Construir query via Supabase client
    let query = supabase
      .from('financial_records')
      .select(`
        id,
        description,
        amount,
        due_date,
        payment_status,
        days_overdue,
        student:students!inner (
          id,
          enrollment_code,
          full_name,
          email,
          student_class_enrollments!left (
            class:classes!left (
              id,
              name
            )
          )
        )
      `)
      .eq('school_id', schoolId)
      .eq('payment_status', 'pending')
      .lt('due_date', today)
      .gte('days_overdue', minDays)
      .order('due_date', { ascending: true });

    // Filtro opcional por turma
    if (classId) {
      query = query.eq('student.student_class_enrollments.class_id', classId);
    }

    const { data: records, error } = await query;

    if (error) {
      console.error('[Report] inadimplencia query error:', error);
      return res.status(500).json({ error: 'Erro ao buscar dados de inadimplência' });
    }

    // Consolidar por aluno
    const studentMap = new Map();

    for (const record of records || []) {
      const student = record.student;
      const sid = student?.id;
      if (!sid) continue;

      const daysOverdue = record.days_overdue ||
        Math.floor((new Date(today) - new Date(record.due_date)) / 86400000);

      // Turma atual (primeira matrícula ativa)
      const className = student.student_class_enrollments?.[0]?.class?.name || null;

      if (!studentMap.has(sid)) {
        studentMap.set(sid, {
          student_id:      sid,
          enrollment_code: student.enrollment_code,
          full_name:       student.full_name,
          email:           student.email,
          class_name:      className,
          invoices:        [],
          total_overdue:   0,
          max_days_overdue: 0,
        });
      }

      const entry = studentMap.get(sid);
      entry.invoices.push({
        id:          record.id,
        description: record.description,
        amount:      parseFloat(record.amount),
        due_date:    record.due_date,
        days_overdue: daysOverdue,
        risk:        getRiskLevel(daysOverdue),
      });
      entry.total_overdue   += parseFloat(record.amount);
      entry.max_days_overdue = Math.max(entry.max_days_overdue, daysOverdue);
    }

    const students = Array.from(studentMap.values())
      .sort((a, b) => b.max_days_overdue - a.max_days_overdue);

    const totalAmount = students.reduce((sum, s) => sum + s.total_overdue, 0);

    return res.status(200).json({
      total_overdue: students.length,
      total_amount:  totalAmount,
      filters: {
        class_id:  classId,
        min_days:  minDays,
        as_of:     today,
      },
      students,
    });
  } catch (err) {
    console.error('[Report] inadimplencia error:', err);
    return res.status(500).json({ error: 'Erro interno ao gerar relatório de inadimplência' });
  }
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function getRiskLevel(daysOverdue) {
  if (daysOverdue <= 30) return 'Baixo';
  if (daysOverdue <= 60) return 'Médio';
  if (daysOverdue <= 90) return 'Alto';
  return 'Crítico';
}

export default router;
