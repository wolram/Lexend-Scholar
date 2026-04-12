// LS-71 — Endpoints de matrículas e frequência
// Vercel Serverless Function — Web Request/Response API
import { getAuthUser, jsonResponse as json, errResponse as err, parsePagination, getSupabaseAdmin } from './_middleware.js';

export default async function handler(request) {
  const user = await getAuthUser(request);
  if (!user) return err('Missing or invalid authorization token', 'UNAUTHORIZED', 401);

  const url = new URL(request.url);
  const segments = url.pathname.replace(/^\/api\/matriculas-frequencia\/?/, '').split('/').filter(Boolean);
  const resource = segments[0]; // matriculas | frequencia
  const id = segments[1];
  const method = request.method.toUpperCase();

  switch (resource) {
    case 'matriculas':  return handleMatriculas(method, id, url, request, user);
    case 'frequencia':  return handleFrequencia(method, id, url, request, user);
    default:            return err('Route not found', 'NOT_FOUND', 404);
  }
}

// ──────────────────────────────────────────────────────────────
// MATRICULAS (student_class_enrollments)
// ──────────────────────────────────────────────────────────────
async function handleMatriculas(method, id, url, request, user) {
  const supabase = getSupabaseAdmin();
  const { school_id } = user;

  // GET /api/matriculas-frequencia/matriculas?class_id=&student_id=
  if (method === 'GET' && !id) {
    const { limit, offset } = parsePagination(url);
    const class_id = url.searchParams.get('class_id');
    const student_id = url.searchParams.get('student_id');

    let q = supabase
      .from('student_class_enrollments')
      .select(`
        *,
        students!inner(id, full_name, enrollment_code, school_id),
        classes!inner(id, name, school_id, grades(name))
      `, { count: 'exact' })
      .range(offset, offset + limit - 1);

    // Tenant isolation: filter via the joined tables
    q = q.eq('students.school_id', school_id);
    if (class_id) q = q.eq('class_id', class_id);
    if (student_id) q = q.eq('student_id', student_id);

    const { data, error, count } = await q;
    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data, total: count, limit, offset });
  }

  // GET /api/matriculas-frequencia/matriculas/:id
  if (method === 'GET' && id) {
    const { data, error } = await supabase
      .from('student_class_enrollments')
      .select('*, students(id, full_name, enrollment_code), classes(id, name, grades(name))')
      .eq('id', id)
      .eq('students.school_id', school_id)
      .single();

    if (error) return err('Enrollment not found', 'NOT_FOUND', 404);
    return json({ data });
  }

  // POST /api/matriculas-frequencia/matriculas — enroll a student in a class
  if (method === 'POST') {
    const body = await request.json();
    const { student_id, class_id, enrolled_at } = body;

    if (!student_id || !class_id)
      return err('student_id and class_id are required', 'VALIDATION_ERROR', 400);

    // Verify student and class belong to this school
    const [{ data: student }, { data: cls }] = await Promise.all([
      supabase.from('students').select('id').eq('id', student_id).eq('school_id', school_id).single(),
      supabase.from('classes').select('id, max_students').eq('id', class_id).eq('school_id', school_id).single(),
    ]);

    if (!student) return err('Student not found in this school', 'NOT_FOUND', 404);
    if (!cls) return err('Class not found in this school', 'NOT_FOUND', 404);

    // Check class capacity
    const { count: currentCount } = await supabase
      .from('student_class_enrollments')
      .select('id', { count: 'exact', head: true })
      .eq('class_id', class_id)
      .eq('active', true);

    if (currentCount >= cls.max_students)
      return err(`Class is full (max ${cls.max_students} students)`, 'CLASS_FULL', 422);

    const { data, error } = await supabase
      .from('student_class_enrollments')
      .insert({ student_id, class_id, enrolled_at: enrolled_at || new Date().toISOString().slice(0, 10), active: true })
      .select('*, students(full_name), classes(name)')
      .single();

    if (error) {
      if (error.code === '23505') return err('Student is already enrolled in this class', 'DUPLICATE', 409);
      return err(error.message, 'DB_ERROR', 500);
    }
    return json({ data }, 201);
  }

  // PATCH /api/matriculas-frequencia/matriculas/:id — transfer or deactivate
  if (method === 'PATCH' && id) {
    const body = await request.json();
    const updates = {};
    if (body.active !== undefined) updates.active = body.active;
    if (body.left_at !== undefined) updates.left_at = body.left_at;

    const { data, error } = await supabase
      .from('student_class_enrollments')
      .update(updates)
      .eq('id', id)
      .select('*, students(full_name, school_id), classes(name)')
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    if (!data || data.students?.school_id !== school_id)
      return err('Enrollment not found', 'NOT_FOUND', 404);
    return json({ data });
  }

  // DELETE /api/matriculas-frequencia/matriculas/:id — soft delete (unenroll)
  if (method === 'DELETE' && id) {
    const { data, error } = await supabase
      .from('student_class_enrollments')
      .update({ active: false, left_at: new Date().toISOString().slice(0, 10) })
      .eq('id', id)
      .select('*, students(school_id)')
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    if (!data || data.students?.school_id !== school_id)
      return err('Enrollment not found', 'NOT_FOUND', 404);
    return json({ data, message: 'Student unenrolled (soft delete)' });
  }

  return err('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
}

// ──────────────────────────────────────────────────────────────
// FREQUENCIA (attendance_records)
// ──────────────────────────────────────────────────────────────
async function handleFrequencia(method, id, url, request, user) {
  const supabase = getSupabaseAdmin();
  const { school_id } = user;

  // GET /api/matriculas-frequencia/frequencia?class_id=&date=&student_id=
  if (method === 'GET' && !id) {
    const { limit, offset } = parsePagination(url);
    const class_id = url.searchParams.get('class_id');
    const student_id = url.searchParams.get('student_id');
    const subject_id = url.searchParams.get('subject_id');
    const date_from = url.searchParams.get('date_from');
    const date_to = url.searchParams.get('date_to');
    const date = url.searchParams.get('date');

    let q = supabase
      .from('attendance_records')
      .select('*, students(full_name, enrollment_code), subjects(name), classes(name)', { count: 'exact' })
      .eq('school_id', school_id)
      .order('date', { ascending: false })
      .range(offset, offset + limit - 1);

    if (class_id) q = q.eq('class_id', class_id);
    if (student_id) q = q.eq('student_id', student_id);
    if (subject_id) q = q.eq('subject_id', subject_id);
    if (date) q = q.eq('date', date);
    if (date_from) q = q.gte('date', date_from);
    if (date_to) q = q.lte('date', date_to);

    const { data, error, count } = await q;
    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data, total: count, limit, offset });
  }

  // GET /api/matriculas-frequencia/frequencia/:id
  if (method === 'GET' && id) {
    const { data, error } = await supabase
      .from('attendance_records')
      .select('*, students(full_name), subjects(name), classes(name)')
      .eq('id', id)
      .eq('school_id', school_id)
      .single();

    if (error) return err('Attendance record not found', 'NOT_FOUND', 404);
    return json({ data });
  }

  // POST /api/matriculas-frequencia/frequencia — record attendance (bulk supported)
  if (method === 'POST') {
    const body = await request.json();

    // Accept a single record or an array for bulk insert
    const records = Array.isArray(body) ? body : [body];
    const validated = [];

    for (const rec of records) {
      const { class_id, subject_id, student_id, date, status = 'present', notes } = rec;
      if (!class_id || !subject_id || !student_id || !date)
        return err('class_id, subject_id, student_id, and date are required for each record', 'VALIDATION_ERROR', 400);

      validated.push({
        school_id,
        class_id,
        subject_id,
        student_id,
        date,
        status,
        notes,
        recorded_by: user.id,
      });
    }

    const { data, error } = await supabase
      .from('attendance_records')
      .upsert(validated, { onConflict: 'class_id,subject_id,student_id,date', ignoreDuplicates: false })
      .select();

    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data, inserted: data.length }, 201);
  }

  // PATCH /api/matriculas-frequencia/frequencia/:id — update status/notes
  if (method === 'PATCH' && id) {
    const body = await request.json();
    const updates = {};
    if (body.status !== undefined) updates.status = body.status;
    if (body.notes !== undefined) updates.notes = body.notes;

    const { data, error } = await supabase
      .from('attendance_records')
      .update(updates)
      .eq('id', id)
      .eq('school_id', school_id)
      .select()
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    if (!data) return err('Attendance record not found', 'NOT_FOUND', 404);
    return json({ data });
  }

  // DELETE /api/matriculas-frequencia/frequencia/:id
  if (method === 'DELETE' && id) {
    const { error } = await supabase
      .from('attendance_records')
      .delete()
      .eq('id', id)
      .eq('school_id', school_id);

    if (error) return err(error.message, 'DB_ERROR', 500);
    return new Response(null, { status: 204 });
  }

  // GET summary: /api/matriculas-frequencia/frequencia/summary?student_id=&class_id=
  if (method === 'GET' && id === 'summary') {
    const student_id = url.searchParams.get('student_id');
    const class_id = url.searchParams.get('class_id');

    if (!student_id) return err('student_id is required for summary', 'VALIDATION_ERROR', 400);

    let q = supabase
      .from('attendance_records')
      .select('status')
      .eq('school_id', school_id)
      .eq('student_id', student_id);

    if (class_id) q = q.eq('class_id', class_id);

    const { data, error } = await q;
    if (error) return err(error.message, 'DB_ERROR', 500);

    const summary = data.reduce(
      (acc, r) => { acc[r.status] = (acc[r.status] || 0) + 1; return acc; },
      { present: 0, absent: 0, late: 0, excused: 0 }
    );
    const total = data.length;
    const attendance_rate = total > 0 ? ((summary.present + summary.late) / total * 100).toFixed(1) : '0.0';

    return json({ data: { ...summary, total, attendance_rate: parseFloat(attendance_rate) } });
  }

  return err('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
}
