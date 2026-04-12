// LS-74 — Endpoints de financeiro (financial_records / mensalidades)
// Vercel Serverless Function — Web Request/Response API
import { getAuthUser, jsonResponse as json, errResponse as err, parsePagination, getSupabaseAdmin } from './_middleware.js';

export default async function handler(request) {
  const user = await getAuthUser(request);
  if (!user) return err('Missing or invalid authorization token', 'UNAUTHORIZED', 401);

  const url = new URL(request.url);
  const segments = url.pathname.replace(/^\/api\/financeiro\/?/, '').split('/').filter(Boolean);
  const resource = segments[0]; // mensalidades | resumo | inadimplentes
  const id = segments[1];
  const method = request.method.toUpperCase();

  switch (resource) {
    case 'mensalidades':  return handleMensalidades(method, id, url, request, user);
    case 'resumo':        return handleResumo(method, id, url, request, user);
    case 'inadimplentes': return handleInadimplentes(method, id, url, request, user);
    default:              return err('Route not found', 'NOT_FOUND', 404);
  }
}

// ──────────────────────────────────────────────────────────────
// MENSALIDADES (financial_records)
// ──────────────────────────────────────────────────────────────
async function handleMensalidades(method, id, url, request, user) {
  const supabase = getSupabaseAdmin();
  const { school_id, role } = user;

  // GET /api/financeiro/mensalidades
  if (method === 'GET' && !id) {
    const { limit, offset } = parsePagination(url);
    const student_id = url.searchParams.get('student_id');
    const payment_status = url.searchParams.get('payment_status');
    const due_from = url.searchParams.get('due_from');
    const due_to = url.searchParams.get('due_to');

    let q = supabase
      .from('financial_records')
      .select(`
        *,
        students(id, full_name, enrollment_code)
      `, { count: 'exact' })
      .eq('school_id', school_id)
      .order('due_date', { ascending: false })
      .range(offset, offset + limit - 1);

    if (student_id) q = q.eq('student_id', student_id);
    if (payment_status) q = q.eq('payment_status', payment_status);
    if (due_from) q = q.gte('due_date', due_from);
    if (due_to) q = q.lte('due_date', due_to);

    const { data, error, count } = await q;
    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data, total: count, limit, offset });
  }

  // GET /api/financeiro/mensalidades/:id
  if (method === 'GET' && id) {
    const { data, error } = await supabase
      .from('financial_records')
      .select('*, students(full_name, enrollment_code, email, phone)')
      .eq('id', id)
      .eq('school_id', school_id)
      .single();

    if (error) return err('Financial record not found', 'NOT_FOUND', 404);
    return json({ data });
  }

  // POST /api/financeiro/mensalidades — create a charge
  if (method === 'POST') {
    if (!['admin', 'secretary'].includes(role))
      return err('Only admins and secretaries can create financial records', 'FORBIDDEN', 403);

    const body = await request.json();
    const {
      student_id, description, amount, due_date,
      payment_method, notes,
    } = body;

    if (!student_id || !description || !amount || !due_date)
      return err('student_id, description, amount, and due_date are required', 'VALIDATION_ERROR', 400);

    if (amount <= 0) return err('amount must be greater than 0', 'VALIDATION_ERROR', 422);

    // Verify student belongs to school
    const { data: student } = await supabase
      .from('students')
      .select('id')
      .eq('id', student_id)
      .eq('school_id', school_id)
      .single();

    if (!student) return err('Student not found in this school', 'NOT_FOUND', 404);

    const { data, error } = await supabase
      .from('financial_records')
      .insert({
        school_id, student_id, description, amount,
        due_date, payment_method, notes, payment_status: 'pending',
      })
      .select('*, students(full_name)')
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data }, 201);
  }

  // POST bulk: generate monthly charges for all active students
  // POST /api/financeiro/mensalidades/gerar-lote
  if (method === 'POST' && id === 'gerar-lote') {
    if (!['admin', 'secretary'].includes(role))
      return err('Only admins and secretaries can generate batch charges', 'FORBIDDEN', 403);

    const body = await request.json();
    const { description, amount, due_date, class_id } = body;

    if (!description || !amount || !due_date)
      return err('description, amount, and due_date are required', 'VALIDATION_ERROR', 400);

    // Fetch active students — optionally filtered by class
    let studentsQuery = supabase
      .from('students')
      .select('id')
      .eq('school_id', school_id)
      .eq('active', true);

    if (class_id) {
      const { data: enrollments } = await supabase
        .from('student_class_enrollments')
        .select('student_id')
        .eq('class_id', class_id)
        .eq('active', true);

      const ids = (enrollments || []).map(e => e.student_id);
      if (ids.length === 0) return json({ data: [], inserted: 0 });
      studentsQuery = studentsQuery.in('id', ids);
    }

    const { data: students, error: sErr } = await studentsQuery;
    if (sErr) return err(sErr.message, 'DB_ERROR', 500);

    const inserts = students.map(s => ({
      school_id, student_id: s.id, description, amount,
      due_date, payment_status: 'pending',
    }));

    const { data, error } = await supabase
      .from('financial_records')
      .insert(inserts)
      .select();

    if (error) return err(error.message, 'DB_ERROR', 500);
    return json({ data, inserted: data.length }, 201);
  }

  // PATCH /api/financeiro/mensalidades/:id — register payment or update
  if (method === 'PATCH' && id) {
    if (!['admin', 'secretary'].includes(role))
      return err('Only admins and secretaries can update financial records', 'FORBIDDEN', 403);

    const body = await request.json();
    const allowed = ['payment_status', 'paid_date', 'payment_method', 'notes', 'amount', 'due_date', 'description'];
    const updates = { updated_at: new Date().toISOString() };
    for (const key of allowed) {
      if (body[key] !== undefined) updates[key] = body[key];
    }

    // Auto-set paid_date when marking as paid
    if (updates.payment_status === 'paid' && !updates.paid_date) {
      updates.paid_date = new Date().toISOString().slice(0, 10);
    }
    // Clear paid_date if status reverted
    if (updates.payment_status && updates.payment_status !== 'paid') {
      updates.paid_date = null;
    }

    const { data, error } = await supabase
      .from('financial_records')
      .update(updates)
      .eq('id', id)
      .eq('school_id', school_id)
      .select('*, students(full_name)')
      .single();

    if (error) return err(error.message, 'DB_ERROR', 500);
    if (!data) return err('Financial record not found', 'NOT_FOUND', 404);
    return json({ data });
  }

  // DELETE /api/financeiro/mensalidades/:id — only pending records
  if (method === 'DELETE' && id) {
    if (role !== 'admin') return err('Only admins can delete financial records', 'FORBIDDEN', 403);

    // Only allow deletion of pending records
    const { data: existing } = await supabase
      .from('financial_records')
      .select('id, payment_status')
      .eq('id', id)
      .eq('school_id', school_id)
      .single();

    if (!existing) return err('Financial record not found', 'NOT_FOUND', 404);
    if (existing.payment_status !== 'pending')
      return err('Only pending records can be deleted', 'CONFLICT', 409);

    const { error } = await supabase
      .from('financial_records')
      .delete()
      .eq('id', id)
      .eq('school_id', school_id);

    if (error) return err(error.message, 'DB_ERROR', 500);
    return new Response(null, { status: 204 });
  }

  return err('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
}

// ──────────────────────────────────────────────────────────────
// RESUMO — financial summary for the school
// GET /api/financeiro/resumo?month=2025-05
// ──────────────────────────────────────────────────────────────
async function handleResumo(method, id, url, request, user) {
  if (method !== 'GET') return err('Method not allowed', 'METHOD_NOT_ALLOWED', 405);

  const supabase = getSupabaseAdmin();
  const { school_id } = user;
  const month = url.searchParams.get('month'); // e.g. "2025-05"

  let q = supabase
    .from('financial_records')
    .select('amount, payment_status, due_date, paid_date')
    .eq('school_id', school_id);

  if (month) {
    q = q.gte('due_date', `${month}-01`).lte('due_date', `${month}-31`);
  }

  const { data, error } = await q;
  if (error) return err(error.message, 'DB_ERROR', 500);

  const summary = data.reduce(
    (acc, r) => {
      acc.total += parseFloat(r.amount);
      acc[r.payment_status] = (acc[r.payment_status] || 0) + parseFloat(r.amount);
      return acc;
    },
    { total: 0, pending: 0, paid: 0, failed: 0, refunded: 0 }
  );

  const overdue = data.filter(
    r => r.payment_status === 'pending' && r.due_date < new Date().toISOString().slice(0, 10)
  );
  summary.overdue = overdue.reduce((acc, r) => acc + parseFloat(r.amount), 0);
  summary.overdue_count = overdue.length;
  summary.total_records = data.length;

  // Round to 2 decimals
  for (const key of Object.keys(summary)) {
    if (typeof summary[key] === 'number') summary[key] = parseFloat(summary[key].toFixed(2));
  }

  return json({ data: summary });
}

// ──────────────────────────────────────────────────────────────
// INADIMPLENTES — list of students with overdue payments
// GET /api/financeiro/inadimplentes?min_days=1
// ──────────────────────────────────────────────────────────────
async function handleInadimplentes(method, id, url, request, user) {
  if (method !== 'GET') return err('Method not allowed', 'METHOD_NOT_ALLOWED', 405);

  const supabase = getSupabaseAdmin();
  const { school_id } = user;
  const { limit, offset } = parsePagination(url);
  const min_days = parseInt(url.searchParams.get('min_days') || '1', 10);
  const today = new Date().toISOString().slice(0, 10);
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - min_days);
  const cutoffStr = cutoffDate.toISOString().slice(0, 10);

  const { data, error, count } = await supabase
    .from('financial_records')
    .select(`
      id, description, amount, due_date, days_overdue,
      students(id, full_name, enrollment_code, email, phone)
    `, { count: 'exact' })
    .eq('school_id', school_id)
    .eq('payment_status', 'pending')
    .lt('due_date', today)
    .lte('due_date', cutoffStr)
    .order('due_date', { ascending: true })
    .range(offset, offset + limit - 1);

  if (error) return err(error.message, 'DB_ERROR', 500);

  // Group by student
  const byStudent = {};
  for (const r of data) {
    const sid = r.students?.id;
    if (!sid) continue;
    if (!byStudent[sid]) {
      byStudent[sid] = {
        student: r.students,
        total_overdue: 0,
        records: [],
      };
    }
    byStudent[sid].total_overdue += parseFloat(r.amount);
    byStudent[sid].records.push({
      id: r.id,
      description: r.description,
      amount: parseFloat(r.amount),
      due_date: r.due_date,
      days_overdue: r.days_overdue,
    });
  }

  const result = Object.values(byStudent).map(s => ({
    ...s,
    total_overdue: parseFloat(s.total_overdue.toFixed(2)),
  }));

  return json({ data: result, total: count, limit, offset });
}
