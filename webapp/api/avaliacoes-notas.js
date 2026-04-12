// LS-72 — Endpoints de avaliações e notas (grade_records)
// Vercel Serverless Function — Web Request/Response API
import { getAuthUser, jsonResponse as json, errResponse as err, parsePagination, getSupabaseAdmin } from './_middleware.js';

export default async function handler(request) {
  const user = await getAuthUser(request);
  if (!user) return err('Missing or invalid authorization token', 'UNAUTHORIZED', 401);

  const url = new URL(request.url);
  const segments = url.pathname.replace(/^\/api\/avaliacoes-notas\/?/, '').split('/').filter(Boolean);
  const resource = segments[0]; // notas | boletim | estatisticas
  const id = segments[1];
  const method = request.method.toUpperCase();

  switch (resource) {
    case 'notas':        return handleNotas(method, id, url, request, user);
    case 'boletim':      return handleBoletim(method, id, url, request, user);
    case 'estatisticas': return handleEstatisticas(method, id, url, request, user);
    default:             return err('Route not found', 'NOT_FOUND', 404);
  }
}

// ──────────────────────────────────────────────────────────────
// NOTAS (grade_records)
// ──────────────────────────────────────────────────────────────
async function handleNotas(method, id, url, request, user) {
  const supabase = getSupabaseAdmin();
  const { school_id } = user;

  // GET /api/avaliacoes-notas/notas?student_id=&class_id=&subject_id=&academic_period_id=
  if (method === 'GET' && !id) {
    const { limit, offset } = parsePagination(url);
    const student_id = url.searchParams.get('student_id');
    const class_id = url.searchParams.get('class_id');
    const subject_id = url.searchParams.get('subject_id');
    const academic_period_id = url.searchParams.get('academic_period_id');
    const grade_type = url.searchParams.get('grade_type');

    let q = supabase
      .from('grade_records')
      .select(`
        *,
        students(full_name, enrollment_code),
        subjects(name, code),
        classes(name),
        academic_periods(name, start_date, end_date),
        users(full_name)
      `, { count: 'exact' })
      .eq('school_id', school_id)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (student_id) q = q.eq('student_id', student_id);
    if (class_id) q = q.eq('class_id', class_id);
    if (subject_id) q = q.eq('subject_id', subject_id);
    if (academic_period_id) q = q.eq('academic_period_id', academic_period_id);
    if (grade_type) q = q.eq('grade_type', grade_type);

    const { data, error, count } = await q;
    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data, total: count, limit, offset });
  }

  // GET /api/avaliacoes-notas/notas/:id
  if (method === 'GET' && id) {
    const { data, error } = await supabase
      .from('grade_records')
      .select('*, students(full_name), subjects(name), classes(name), academic_periods(name)')
      .eq('id', id)
      .eq('school_id', school_id)
      .single();

    if (error) return err('Grade record not found', 'NOT_FOUND', 404);
    return json({ data });
  }

  // POST /api/avaliacoes-notas/notas — create a grade record
  if (method === 'POST') {
    const body = await request.json();
    const {
      student_id, class_id, subject_id, academic_period_id,
      score, max_score = 10.00, grade_type = 'prova', description,
    } = body;

    if (!student_id || !class_id || !subject_id || !academic_period_id)
      return err('student_id, class_id, subject_id, and academic_period_id are required', 'VALIDATION_ERROR', 400);

    if (score !== undefined && (score < 0 || score > max_score))
      return err(`score must be between 0 and ${max_score}`, 'VALIDATION_ERROR', 422);

    // Verify entities belong to this school
    const [{ data: student }, { data: cls }] = await Promise.all([
      supabase.from('students').select('id').eq('id', student_id).eq('school_id', school_id).single(),
      supabase.from('classes').select('id').eq('id', class_id).eq('school_id', school_id).single(),
    ]);

    if (!student) return err('Student not found in this school', 'NOT_FOUND', 404);
    if (!cls) return err('Class not found in this school', 'NOT_FOUND', 404);

    const { data, error } = await supabase
      .from('grade_records')
      .insert({
        school_id, student_id, class_id, subject_id, academic_period_id,
        score, max_score, grade_type, description, recorded_by: user.id,
      })
      .select('*, students(full_name), subjects(name), academic_periods(name)')
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data }, 201);
  }

  // POST bulk: /api/avaliacoes-notas/notas/bulk
  if (method === 'POST' && id === 'bulk') {
    const records = await request.json();
    if (!Array.isArray(records) || records.length === 0)
      return err('Body must be a non-empty array of grade records', 'VALIDATION_ERROR', 400);

    const inserts = records.map(r => ({
      school_id,
      student_id: r.student_id,
      class_id: r.class_id,
      subject_id: r.subject_id,
      academic_period_id: r.academic_period_id,
      score: r.score,
      max_score: r.max_score ?? 10.00,
      grade_type: r.grade_type ?? 'prova',
      description: r.description,
      recorded_by: user.id,
    }));

    const { data, error } = await supabase
      .from('grade_records')
      .insert(inserts)
      .select();

    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data, inserted: data.length }, 201);
  }

  // PATCH /api/avaliacoes-notas/notas/:id — update score or description
  if (method === 'PATCH' && id) {
    const body = await request.json();
    const allowed = ['score', 'max_score', 'grade_type', 'description'];
    const updates = { updated_at: new Date().toISOString() };
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }

    const { data, error } = await supabase
      .from('grade_records')
      .update(updates)
      .eq('id', id)
      .eq('school_id', school_id)
      .select()
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    if (!data) return err('Grade record not found', 'NOT_FOUND', 404);
    return json({ data });
  }

  // DELETE /api/avaliacoes-notas/notas/:id
  if (method === 'DELETE' && id) {
    const { error } = await supabase
      .from('grade_records')
      .delete()
      .eq('id', id)
      .eq('school_id', school_id);

    if (error) return err(error.message, 'DB_ERROR', 500);
    return new Response(null, { status: 204 });
  }

  return err('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
}

// ──────────────────────────────────────────────────────────────
// BOLETIM — grade report per student per period
// GET /api/avaliacoes-notas/boletim/:student_id?academic_period_id=
// ──────────────────────────────────────────────────────────────
async function handleBoletim(method, id, url, request, user) {
  if (method !== 'GET') return err('Method not allowed', 'METHOD_NOT_ALLOWED', 405);

  const supabase = getSupabaseAdmin();
  const { school_id } = user;
  const student_id = id;
  const academic_period_id = url.searchParams.get('academic_period_id');
  const class_id = url.searchParams.get('class_id');

  if (!student_id) return err('student_id is required as path param', 'VALIDATION_ERROR', 400);

  // Verify student belongs to this school
  const { data: student, error: sErr } = await supabase
    .from('students')
    .select('id, full_name, enrollment_code')
    .eq('id', student_id)
    .eq('school_id', school_id)
    .single();

  if (sErr || !student) return err('Student not found', 'NOT_FOUND', 404);

  let q = supabase
    .from('grade_records')
    .select(`
      score, max_score, grade_type, description,
      subjects(id, name, code),
      academic_periods(id, name)
    `)
    .eq('school_id', school_id)
    .eq('student_id', student_id);

  if (academic_period_id) q = q.eq('academic_period_id', academic_period_id);
  if (class_id) q = q.eq('class_id', class_id);

  const { data: grades, error } = await q;
  if (error) return err(error.message, 'DB_ERROR', 500);

  // Group by subject
  const bySubject = {};
  for (const g of grades) {
    const subjectId = g.subjects?.id;
    if (!subjectId) continue;
    if (!bySubject[subjectId]) {
      bySubject[subjectId] = {
        subject: g.subjects,
        grades: [],
        average: null,
      };
    }
    bySubject[subjectId].grades.push({
      score: g.score,
      max_score: g.max_score,
      grade_type: g.grade_type,
      description: g.description,
      academic_period: g.academic_periods,
    });
  }

  // Compute weighted average per subject
  for (const entry of Object.values(bySubject)) {
    const valid = entry.grades.filter(g => g.score !== null && g.max_score > 0);
    if (valid.length > 0) {
      const sum = valid.reduce((acc, g) => acc + (g.score / g.max_score) * 10, 0);
      entry.average = parseFloat((sum / valid.length).toFixed(2));
    }
  }

  return json({
    data: {
      student,
      subjects: Object.values(bySubject),
    },
  });
}

// ──────────────────────────────────────────────────────────────
// ESTATISTICAS — class/subject grade statistics
// GET /api/avaliacoes-notas/estatisticas?class_id=&subject_id=&academic_period_id=
// ──────────────────────────────────────────────────────────────
async function handleEstatisticas(method, id, url, request, user) {
  if (method !== 'GET') return err('Method not allowed', 'METHOD_NOT_ALLOWED', 405);

  const supabase = getSupabaseAdmin();
  const { school_id } = user;
  const class_id = url.searchParams.get('class_id');
  const subject_id = url.searchParams.get('subject_id');
  const academic_period_id = url.searchParams.get('academic_period_id');

  if (!class_id) return err('class_id is required', 'VALIDATION_ERROR', 400);

  let q = supabase
    .from('grade_records')
    .select('score, max_score, student_id')
    .eq('school_id', school_id)
    .eq('class_id', class_id)
    .not('score', 'is', null);

  if (subject_id) q = q.eq('subject_id', subject_id);
  if (academic_period_id) q = q.eq('academic_period_id', academic_period_id);

  const { data, error } = await q;
  if (error) return err(error.message, 'DB_ERROR', 500);

  if (data.length === 0) return json({ data: { count: 0, mean: null, min: null, max: null, passing_rate: null } });

  const normalized = data.map(g => (g.score / g.max_score) * 10);
  const mean = normalized.reduce((a, b) => a + b, 0) / normalized.length;
  const min = Math.min(...normalized);
  const max = Math.max(...normalized);
  const passing = normalized.filter(n => n >= 5).length; // passing threshold: 5/10
  const passing_rate = parseFloat(((passing / normalized.length) * 100).toFixed(1));

  return json({
    data: {
      count: data.length,
      mean: parseFloat(mean.toFixed(2)),
      min: parseFloat(min.toFixed(2)),
      max: parseFloat(max.toFixed(2)),
      passing_rate,
    },
  });
}
