/**
 * Lexend Scholar — Relatório de Frequência
 *
 * GET /reports/attendance
 *
 * Query params (opcionais):
 *   student_id  — filtrar por aluno (UUID)
 *   class_id    — filtrar por turma (UUID)
 *   date_from   — data inicial YYYY-MM-DD (default: início do ano corrente)
 *   date_to     — data final   YYYY-MM-DD (default: hoje)
 *   page        — página (default: 1)
 *   per_page    — itens por página (default: 50, máx: 200)
 *
 * Retorna:
 *   { data: [...], pagination: { total, page, per_page } }
 *
 * Tabelas usadas (database_schema.sql):
 *   attendance_records, students, student_class_enrollments, classes
 */

import express from 'express';
import { createClient } from '@supabase/supabase-js';

const router = express.Router();

const DEFAULT_PER_PAGE = 50;
const MAX_PER_PAGE     = 200;

function getSupabase() {
  return createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY
  );
}

/**
 * GET /reports/attendance
 */
router.get('/', async (req, res) => {
  const schoolId = req.session?.schoolId || req.headers['x-school-id'];
  if (!schoolId) {
    return res.status(401).json({ error: 'Não autenticado' });
  }

  const today    = new Date().toISOString().split('T')[0];
  const yearStart = `${today.slice(0, 4)}-01-01`;

  const studentId = req.query.student_id || null;
  const classId   = req.query.class_id   || null;
  const dateFrom  = req.query.date_from  || yearStart;
  const dateTo    = req.query.date_to    || today;

  const page    = Math.max(1, parseInt(req.query.page     || '1', 10));
  const perPage = Math.min(MAX_PER_PAGE, Math.max(1, parseInt(req.query.per_page || String(DEFAULT_PER_PAGE), 10)));
  const offset  = (page - 1) * perPage;

  const supabase = getSupabase();

  try {
    // Buscar registros de frequência com dados de aluno e turma
    let query = supabase
      .from('attendance_records')
      .select(`
        id,
        date,
        status,
        notes,
        student:students!inner ( id, full_name, enrollment_code ),
        class:classes!inner    ( id, name )
      `, { count: 'exact' })
      .eq('school_id', schoolId)
      .gte('date', dateFrom)
      .lte('date', dateTo)
      .order('date', { ascending: false })
      .order('student(full_name)', { ascending: true });

    if (studentId) query = query.eq('student_id', studentId);
    if (classId)   query = query.eq('class_id', classId);

    // Aplicar paginação
    query = query.range(offset, offset + perPage - 1);

    const { data: records, count, error } = await query;

    if (error) {
      console.error('[Frequência] attendance query error:', error);
      return res.status(500).json({ error: 'Erro ao buscar registros de frequência' });
    }

    // Agregar frequência por aluno+turma a partir dos registros da página
    const aggregated = aggregateAttendance(records || []);

    return res.status(200).json({
      data: aggregated,
      pagination: {
        total:    count || 0,
        page,
        per_page: perPage,
        pages:    Math.ceil((count || 0) / perPage),
      },
      filters: {
        student_id: studentId,
        class_id:   classId,
        date_from:  dateFrom,
        date_to:    dateTo,
      },
    });
  } catch (err) {
    console.error('[Frequência] report error:', err);
    return res.status(500).json({ error: 'Erro interno ao gerar relatório de frequência' });
  }
});

// ---------------------------------------------------------------------------
// aggregateAttendance
// Agrupa registros individuais por aluno+turma e calcula totais.
// ---------------------------------------------------------------------------
function aggregateAttendance(records) {
  const map = new Map();

  for (const record of records) {
    const key = `${record.student?.id}_${record.class?.id}`;

    if (!map.has(key)) {
      map.set(key, {
        student_id:      record.student?.id,
        enrollment_code: record.student?.enrollment_code,
        full_name:       record.student?.full_name,
        class_id:        record.class?.id,
        class_name:      record.class?.name,
        total_aulas:     0,
        presencas:       0,
        faltas:          0,
        faltas_justificadas: 0,
        atrasos:         0,
        percentual:      null,
        situacao:        null,
      });
    }

    const entry = map.get(key);
    entry.total_aulas++;

    switch (record.status) {
      case 'present':
        entry.presencas++;
        break;
      case 'absent':
        entry.faltas++;
        break;
      case 'late':
        // Atraso conta como presença
        entry.presencas++;
        entry.atrasos++;
        break;
      case 'excused':
        entry.faltas_justificadas++;
        break;
    }
  }

  // Calcular percentual e situação
  for (const entry of map.values()) {
    if (entry.total_aulas > 0) {
      entry.percentual = Math.round((entry.presencas / entry.total_aulas) * 1000) / 10;
      const ratio = entry.presencas / entry.total_aulas;
      entry.situacao = ratio >= 0.75 ? 'regular'
                     : ratio >= 0.60 ? 'atencao'
                     : 'critico';
    } else {
      entry.situacao = 'sem_registro';
    }
  }

  return Array.from(map.values())
    .sort((a, b) => (a.percentual ?? 100) - (b.percentual ?? 100));
}

export default router;
