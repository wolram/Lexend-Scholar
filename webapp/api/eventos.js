/**
 * eventos.js — /api/eventos
 * Lexend Scholar — Eventos escolares com RSVP de responsáveis.
 *
 * POST   /api/eventos              — criar evento (escola/turma/todos)
 * GET    /api/eventos              — listar eventos futuros
 * POST   /api/eventos/:id/rsvp    — confirmar presença (responsável/usuário)
 * GET    /api/eventos/:id/rsvp    — ver lista de confirmações
 *
 * Tabelas: events (já existe em 001), event_rsvp (criada em 004-eventos-rsvp.sql)
 */

import { getAuthUser, jsonResponse, errResponse, parsePagination } from './_middleware.js';
import { supabase } from './_supabase.js';

const WRITE_ROLES = ['admin', 'secretary', 'teacher', 'coordenador', 'diretor'];

export default async function handler(request) {
  const user = await getAuthUser(request);
  if (!user) return errResponse('Não autenticado', 'UNAUTHORIZED', 401);

  const url    = new URL(request.url);
  const path   = url.pathname.replace(/^\/api\/eventos\/?/, '');
  const method = request.method.toUpperCase();
  const { school_id, id: userId, role } = user;

  // ── POST /api/eventos/:id/rsvp ───────────────────────────────────────────────
  if (method === 'POST' && path.endsWith('/rsvp')) {
    const eventId = path.replace('/rsvp', '').split('/')[0];
    if (!eventId) return errResponse('ID do evento obrigatório', 'VALIDATION_ERROR', 400);

    // Verificar que o evento existe e pertence à escola
    const { data: evento, error: evErr } = await supabase
      .from('events')
      .select('id, title')
      .eq('id', eventId)
      .eq('school_id', school_id)
      .single();

    if (evErr || !evento) return errResponse('Evento não encontrado', 'NOT_FOUND', 404);

    let body = {};
    try { body = await request.json(); } catch { /* body opcional */ }
    const status = body.status || 'confirmado'; // confirmado | recusado | talvez
    const VALID = ['confirmado', 'recusado', 'talvez'];
    if (!VALID.includes(status)) {
      return errResponse(`status deve ser um de: ${VALID.join(', ')}`, 'VALIDATION_ERROR', 400);
    }

    // Upsert — um RSVP por usuário por evento
    const { data, error } = await supabase
      .from('event_rsvp')
      .upsert(
        { event_id: eventId, user_id: userId, school_id, status, updated_at: new Date().toISOString() },
        { onConflict: 'event_id,user_id' }
      )
      .select()
      .single();

    if (error) return errResponse('Erro ao registrar RSVP', 'DB_ERROR', 500);
    return jsonResponse({ data }, 201);
  }

  // ── GET /api/eventos/:id/rsvp ────────────────────────────────────────────────
  if (method === 'GET' && path.endsWith('/rsvp')) {
    const eventId = path.replace('/rsvp', '').split('/')[0];
    if (!eventId) return errResponse('ID do evento obrigatório', 'VALIDATION_ERROR', 400);

    if (!WRITE_ROLES.includes(role)) {
      return errResponse('Sem permissão para ver confirmações', 'FORBIDDEN', 403);
    }

    const { data, error } = await supabase
      .from('event_rsvp')
      .select('status, updated_at, user:users!user_id(id, full_name, role, email)')
      .eq('event_id', eventId)
      .eq('school_id', school_id)
      .order('updated_at', { ascending: false });

    if (error) return errResponse('Erro ao buscar RSVPs', 'DB_ERROR', 500);

    const totals = data.reduce((acc, r) => {
      acc[r.status] = (acc[r.status] || 0) + 1;
      return acc;
    }, {});

    return jsonResponse({ data, totals, total: data.length });
  }

  // ── GET /api/eventos ─────────────────────────────────────────────────────────
  if (method === 'GET' && !path) {
    const { limit, offset } = parsePagination(url);
    const todos    = url.searchParams.get('todos') === 'true'; // incluir passados
    const turmaId  = url.searchParams.get('turma_id');

    let query = supabase
      .from('events')
      .select('*, criador:users!created_by(id, full_name, role)', { count: 'exact' })
      .eq('school_id', school_id)
      .order('start_date', { ascending: true })
      .range(offset, offset + limit - 1);

    if (!todos) {
      query = query.gte('start_date', new Date().toISOString());
    }

    if (turmaId) {
      // eventos que incluem esta turma OU eventos para toda a escola (class_ids IS NULL)
      query = query.or(`class_ids.cs.{${turmaId}},class_ids.is.null`);
    }

    const { data, error, count } = await query;
    if (error) return errResponse('Erro ao buscar eventos', 'DB_ERROR', 500);
    return jsonResponse({ data, total: count, limit, offset });
  }

  // ── POST /api/eventos ────────────────────────────────────────────────────────
  if (method === 'POST' && !path) {
    if (!WRITE_ROLES.includes(role)) {
      return errResponse('Sem permissão para criar eventos', 'FORBIDDEN', 403);
    }

    let body;
    try { body = await request.json(); } catch { return errResponse('Body JSON inválido', 'BAD_REQUEST', 400); }

    const {
      title, description, event_type = 'general',
      start_date, end_date, all_day = false, class_ids = null
    } = body;

    if (!title || !start_date || !end_date) {
      return errResponse('Campos obrigatórios: title, start_date, end_date', 'VALIDATION_ERROR', 400);
    }

    const VALID_TYPES = ['general', 'holiday', 'exam', 'meeting', 'activity'];
    if (!VALID_TYPES.includes(event_type)) {
      return errResponse(`event_type deve ser um de: ${VALID_TYPES.join(', ')}`, 'VALIDATION_ERROR', 400);
    }

    const { data, error } = await supabase
      .from('events')
      .insert({
        school_id,
        title:      title.trim(),
        description: description?.trim() || null,
        event_type,
        start_date,
        end_date,
        all_day,
        class_ids:  class_ids || null,
        created_by: userId,
      })
      .select('*, criador:users!created_by(id, full_name, role)')
      .single();

    if (error) return errResponse('Erro ao criar evento', 'DB_ERROR', 500);
    return jsonResponse({ data }, 201);
  }

  return errResponse('Método ou rota não permitido', 'METHOD_NOT_ALLOWED', 405);
}
