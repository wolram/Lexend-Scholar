// LS-70 — CRUD endpoints: alunos, professores (users), turmas (classes)
// Vercel Serverless Function — Web Request/Response API (no Express)
import { getAuthUser, jsonResponse as json, errResponse as err, parsePagination, getSupabaseAdmin } from './_middleware.js';

const getSupabase = getSupabaseAdmin;

// ──────────────────────────────────────────────────────────────
// Router — matches /api/crud-academico/<resource>[/<id>]
// ──────────────────────────────────────────────────────────────
export default async function handler(request) {
  const user = await getAuthUser(request);
  if (!user) return err('Missing or invalid authorization token', 'UNAUTHORIZED', 401);

  const url = new URL(request.url);
  // Strip leading /api/crud-academico and split remaining path
  const segments = url.pathname.replace(/^\/api\/crud-academico\/?/, '').split('/').filter(Boolean);
  const resource = segments[0]; // alunos | professores | turmas | series | disciplinas
  const id = segments[1];       // UUID or undefined
  const method = request.method.toUpperCase();

  switch (resource) {
    case 'alunos':       return handleAlunos(method, id, url, request, user);
    case 'professores':  return handleProfessores(method, id, url, request, user);
    case 'turmas':       return handleTurmas(method, id, url, request, user);
    case 'series':       return handleSeries(method, id, url, request, user);
    case 'disciplinas':  return handleDisciplinas(method, id, url, request, user);
    default:             return err('Route not found', 'NOT_FOUND', 404);
  }
}

// ──────────────────────────────────────────────────────────────
// STUDENTS (alunos)
// ──────────────────────────────────────────────────────────────
async function handleAlunos(method, id, url, request, user) {
  const supabase = getSupabase();
  const { school_id } = user;

  if (method === 'GET' && !id) {
    const { limit, offset } = parsePagination(url);
    const search = url.searchParams.get('search');
    const active = url.searchParams.get('active');

    let q = supabase
      .from('students')
      .select('*', { count: 'exact' })
      .eq('school_id', school_id)
      .order('full_name')
      .range(offset, offset + limit - 1);

    if (search) q = q.ilike('full_name', `%${search}%`);
    if (active !== null) q = q.eq('active', active === 'true');

    const { data, error, count } = await q;
    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data, total: count, limit, offset });
  }

  if (method === 'GET' && id) {
    const { data, error } = await supabase
      .from('students')
      .select('*, student_guardians(guardians(*)), student_class_enrollments(classes(name, grade_id, grades(name)))')
      .eq('id', id)
      .eq('school_id', school_id)
      .single();

    if (error) return err('Student not found', 'NOT_FOUND', 404);
    return json({ data });
  }

  if (method === 'POST') {
    const body = await request.json();
    const { full_name, birth_date, gender, cpf, email, phone, address, city, state, zip_code, enrollment_code } = body;

    if (!full_name || !enrollment_code)
      return err('full_name and enrollment_code are required', 'VALIDATION_ERROR', 400);

    const { data, error } = await supabase
      .from('students')
      .insert({ school_id, full_name, birth_date, gender, cpf, email, phone, address, city, state, zip_code, enrollment_code })
      .select()
      .single();

    if (error) {
      if (error.code === '23505') return err('enrollment_code already exists for this school', 'DUPLICATE', 409);
      return err(error.message, 'DB_ERROR', 500);
    }
    return json({ data }, 201);
  }

  if (method === 'PATCH' && id) {
    const body = await request.json();
    const allowed = ['full_name', 'birth_date', 'gender', 'cpf', 'email', 'phone', 'address', 'city', 'state', 'zip_code', 'photo_url'];
    const updates = { updated_at: new Date().toISOString() };
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }

    const { data, error } = await supabase
      .from('students')
      .update(updates)
      .eq('id', id)
      .eq('school_id', school_id)
      .select()
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    if (!data) return err('Student not found', 'NOT_FOUND', 404);
    return json({ data });
  }

  if (method === 'DELETE' && id) {
    // Soft delete
    const { data, error } = await supabase
      .from('students')
      .update({ active: false, updated_at: new Date().toISOString() })
      .eq('id', id)
      .eq('school_id', school_id)
      .select()
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    if (!data) return err('Student not found', 'NOT_FOUND', 404);
    return json({ data, message: 'Student deactivated (soft delete)' });
  }

  return err('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
}

// ──────────────────────────────────────────────────────────────
// TEACHERS / USERS (professores)
// ──────────────────────────────────────────────────────────────
async function handleProfessores(method, id, url, request, user) {
  const supabase = getSupabase();
  const { school_id, role: requesterRole } = user;

  if (method === 'GET' && !id) {
    const { limit, offset } = parsePagination(url);
    const role = url.searchParams.get('role');
    const search = url.searchParams.get('search');

    let q = supabase
      .from('users')
      .select('id, full_name, email, role, avatar_url, active, created_at', { count: 'exact' })
      .eq('school_id', school_id)
      .order('full_name')
      .range(offset, offset + limit - 1);

    if (role) q = q.eq('role', role);
    if (search) q = q.ilike('full_name', `%${search}%`);

    const { data, error, count } = await q;
    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data, total: count, limit, offset });
  }

  if (method === 'GET' && id) {
    const { data, error } = await supabase
      .from('users')
      .select('id, full_name, email, role, avatar_url, active, created_at, class_subjects(classes(name), subjects(name, code))')
      .eq('id', id)
      .eq('school_id', school_id)
      .single();

    if (error) return err('User not found', 'NOT_FOUND', 404);
    return json({ data });
  }

  if (method === 'POST') {
    if (!['admin', 'secretary'].includes(requesterRole))
      return err('Only admins and secretaries can create users', 'FORBIDDEN', 403);

    const body = await request.json();
    const { email, full_name, role = 'teacher', avatar_url } = body;
    if (!email || !full_name) return err('email and full_name are required', 'VALIDATION_ERROR', 400);

    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email,
      email_confirm: true,
      app_metadata: { school_id, role },
      user_metadata: { full_name },
    });

    if (authError) {
      if (authError.message.includes('already registered')) return err('Email already registered', 'DUPLICATE', 409);
      return err(authError.message, 'AUTH_ERROR', 500);
    }

    const { data, error } = await supabase
      .from('users')
      .insert({ id: authData.user.id, school_id, email, full_name, role, avatar_url })
      .select()
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data }, 201);
  }

  if (method === 'PATCH' && id) {
    const body = await request.json();
    const allowed = ['full_name', 'avatar_url', 'fcm_token'];
    if (['admin', 'secretary'].includes(requesterRole)) allowed.push('role', 'active');

    const updates = { updated_at: new Date().toISOString() };
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }

    const { data, error } = await supabase
      .from('users')
      .update(updates)
      .eq('id', id)
      .eq('school_id', school_id)
      .select()
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    if (!data) return err('User not found', 'NOT_FOUND', 404);
    return json({ data });
  }

  if (method === 'DELETE' && id) {
    if (requesterRole !== 'admin') return err('Only admins can deactivate users', 'FORBIDDEN', 403);

    const { data, error } = await supabase
      .from('users')
      .update({ active: false, updated_at: new Date().toISOString() })
      .eq('id', id)
      .eq('school_id', school_id)
      .select()
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    if (!data) return err('User not found', 'NOT_FOUND', 404);
    return json({ data, message: 'User deactivated (soft delete)' });
  }

  return err('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
}

// ──────────────────────────────────────────────────────────────
// CLASSES / TURMAS
// ──────────────────────────────────────────────────────────────
async function handleTurmas(method, id, url, request, user) {
  const supabase = getSupabase();
  const { school_id, role: requesterRole } = user;

  if (method === 'GET' && !id) {
    const { limit, offset } = parsePagination(url);
    const academic_year_id = url.searchParams.get('academic_year_id');
    const grade_id = url.searchParams.get('grade_id');

    let q = supabase
      .from('classes')
      .select('*, grades(name, level), academic_years(name), users(full_name)', { count: 'exact' })
      .eq('school_id', school_id)
      .order('name')
      .range(offset, offset + limit - 1);

    if (academic_year_id) q = q.eq('academic_year_id', academic_year_id);
    if (grade_id) q = q.eq('grade_id', grade_id);

    const { data, error, count } = await q;
    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data, total: count, limit, offset });
  }

  if (method === 'GET' && id) {
    const { data, error } = await supabase
      .from('classes')
      .select(`
        *,
        grades(name, level),
        academic_years(name, start_date, end_date),
        users(id, full_name, email),
        class_subjects(id, weekly_hours, subjects(name, code), users(full_name)),
        student_class_enrollments(count)
      `)
      .eq('id', id)
      .eq('school_id', school_id)
      .single();

    if (error) return err('Class not found', 'NOT_FOUND', 404);
    return json({ data });
  }

  if (method === 'POST') {
    const body = await request.json();
    const { grade_id, academic_year_id, name, teacher_id, max_students = 40 } = body;

    if (!grade_id || !academic_year_id || !name)
      return err('grade_id, academic_year_id, and name are required', 'VALIDATION_ERROR', 400);

    const { data, error } = await supabase
      .from('classes')
      .insert({ school_id, grade_id, academic_year_id, name, teacher_id, max_students })
      .select('*, grades(name), academic_years(name)')
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data }, 201);
  }

  if (method === 'PATCH' && id) {
    const body = await request.json();
    const allowed = ['name', 'teacher_id', 'max_students', 'grade_id', 'academic_year_id'];
    const updates = {};
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }

    const { data, error } = await supabase
      .from('classes')
      .update(updates)
      .eq('id', id)
      .eq('school_id', school_id)
      .select('*, grades(name), academic_years(name)')
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    if (!data) return err('Class not found', 'NOT_FOUND', 404);
    return json({ data });
  }

  if (method === 'DELETE' && id) {
    if (requesterRole !== 'admin') return err('Only admins can delete classes', 'FORBIDDEN', 403);

    const { error } = await supabase
      .from('classes')
      .delete()
      .eq('id', id)
      .eq('school_id', school_id);

    if (error) return err(error.message, 'DB_ERROR', 500);
    return new Response(null, { status: 204 });
  }

  return err('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
}

// ──────────────────────────────────────────────────────────────
// GRADES / SERIES
// ──────────────────────────────────────────────────────────────
async function handleSeries(method, id, url, request, user) {
  const supabase = getSupabase();
  const { school_id } = user;

  if (method === 'GET') {
    const { data, error } = await supabase
      .from('grades')
      .select('*')
      .eq('school_id', school_id)
      .order('name');

    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data });
  }

  if (method === 'POST') {
    const body = await request.json();
    const { name, level } = body;
    if (!name) return err('name is required', 'VALIDATION_ERROR', 400);

    const { data, error } = await supabase
      .from('grades')
      .insert({ school_id, name, level })
      .select()
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data }, 201);
  }

  return err('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
}

// ──────────────────────────────────────────────────────────────
// SUBJECTS / DISCIPLINAS
// ──────────────────────────────────────────────────────────────
async function handleDisciplinas(method, id, url, request, user) {
  const supabase = getSupabase();
  const { school_id } = user;

  if (method === 'GET') {
    const { data, error } = await supabase
      .from('subjects')
      .select('*')
      .eq('school_id', school_id)
      .order('name');

    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data });
  }

  if (method === 'POST') {
    const body = await request.json();
    const { name, code } = body;
    if (!name) return err('name is required', 'VALIDATION_ERROR', 400);

    const { data, error } = await supabase
      .from('subjects')
      .insert({ school_id, name, code })
      .select()
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data }, 201);
  }

  return err('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
}
