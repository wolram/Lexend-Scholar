/**
 * comunicados.js — /api/comunicados
 * Lexend Scholar — Fluxo de comunicados por turma / escola.
 *
 * POST   /api/comunicados               — criar comunicado (professor, coordenador, diretor)
 * GET    /api/comunicados?turma_id=X    — listar comunicados de uma turma
 * GET    /api/comunicados/escola        — todos os comunicados da escola
 * PUT    /api/comunicados/:id           — editar comunicado
 * DELETE /api/comunicados/:id           — excluir comunicado
 *
 * Tabela: announcements (criada em sql/migrations/003-comunicados-events.sql)
 */

import { getAuthUser, jsonResponse, errResponse, parsePagination } from './_middleware.js';
import { supabase } from './_supabase.js';

const WRITE_ROLES  = ['professor', 'coordenador', 'diretor', 'admin', 'secretary', 'teacher'];
const DELETE_ROLES = ['coordenador', 'diretor', 'admin', 'secretary'];

export default async function handler(request) {
  const user = await getAuthUser(request);
  if (!user) return errResponse('Não autenticado', 'UNAUTHORIZED', 401);

  const url    = new URL(request.url);
  // Extract path segments after /api/comunicados
  const path   = url.pathname.replace(/^\/api\/comunicados\/?/, '');
  const method = request.method.toUpperCase();
  const { school_id, id: userId, role } = user;

  // ── GET /api/comunicados/escola ─────────────────────────────────────────────
  if (method === 'GET' && path === 'escola') {
    const { limit, offset } = parsePagination(url);

    const { data, error, count } = await supabase
      .from('announcements')
      .select('*, author:users!created_by(id, full_name, role)', { count: 'exact' })
      .eq('school_id', school_id)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) return errResponse('Erro ao buscar comunicados', 'DB_ERROR', 500);
    return jsonResponse({ data, total: count, limit, offset });
  }

  // ── GET /api/comunicados?turma_id=X ─────────────────────────────────────────
  if (method === 'GET' && !path) {
    const turma_id = url.searchParams.get('turma_id');
    const { limit, offset } = parsePagination(url);

    let query = supabase
      .from('announcements')
      .select('*, author:users!created_by(id, full_name, role)', { count: 'exact' })
      .eq('school_id', school_id)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (turma_id) {
      // comunicados para esta turma específica OU para toda a escola (class_id IS NULL)
      query = query.or(`class_id.eq.${turma_id},class_id.is.null`);
    }

    const { data, error, count } = await query;
    if (error) return errResponse('Erro ao buscar comunicados', 'DB_ERROR', 500);
    return jsonResponse({ data, total: count, limit, offset });
  }

  // ── POST /api/comunicados ────────────────────────────────────────────────────
  if (method === 'POST' && !path) {
    if (!WRITE_ROLES.includes(role)) {
      return errResponse('Sem permissão para criar comunicados', 'FORBIDDEN', 403);
    }

    let body;
    try { body = await request.json(); } catch { return errResponse('Body JSON inválido', 'BAD_REQUEST', 400); }

    const { titulo, conteudo, class_id, fixado = false } = body;

    if (!titulo || !conteudo) {
      return errResponse('Campos obrigatórios: titulo, conteudo', 'VALIDATION_ERROR', 400);
    }

    // Verificar que a turma pertence à escola (se informada)
    if (class_id) {
      const { data: turma, error: turmaErr } = await supabase
        .from('classes')
        .select('id')
        .eq('id', class_id)
        .eq('school_id', school_id)
        .single();
      if (turmaErr || !turma) return errResponse('Turma não encontrada nesta escola', 'NOT_FOUND', 404);
    }

    const { data, error } = await supabase
      .from('announcements')
      .insert({
        school_id,
        class_id: class_id || null,
        titulo:   titulo.trim(),
        conteudo: conteudo.trim(),
        fixado,
        created_by: userId,
      })
      .select('*, author:users!created_by(id, full_name, role)')
      .single();

    if (error) return errResponse('Erro ao criar comunicado', 'DB_ERROR', 500);
    return jsonResponse({ data }, 201);
  }

  // ── PUT /api/comunicados/:id ─────────────────────────────────────────────────
  if (method === 'PUT' && path) {
    const id = path.split('/')[0];
    if (!WRITE_ROLES.includes(role)) {
      return errResponse('Sem permissão para editar comunicados', 'FORBIDDEN', 403);
    }

    let body;
    try { body = await request.json(); } catch { return errResponse('Body JSON inválido', 'BAD_REQUEST', 400); }

    // Verificar existência e propriedade
    const { data: existing, error: fetchErr } = await supabase
      .from('announcements')
      .select('id, created_by')
      .eq('id', id)
      .eq('school_id', school_id)
      .is('deleted_at', null)
      .single();

    if (fetchErr || !existing) return errResponse('Comunicado não encontrado', 'NOT_FOUND', 404);

    // Professores só editam os próprios; coordenador/diretor/admin editam qualquer um
    if (!DELETE_ROLES.includes(role) && existing.created_by !== userId) {
      return errResponse('Sem permissão para editar este comunicado', 'FORBIDDEN', 403);
    }

    const patch = { updated_at: new Date().toISOString() };
    if (body.titulo   !== undefined) patch.titulo   = body.titulo.trim();
    if (body.conteudo !== undefined) patch.conteudo = body.conteudo.trim();
    if (body.fixado   !== undefined) patch.fixado   = body.fixado;
    if (body.class_id !== undefined) patch.class_id = body.class_id || null;

    const { data, error } = await supabase
      .from('announcements')
      .update(patch)
      .eq('id', id)
      .eq('school_id', school_id)
      .select('*, author:users!created_by(id, full_name, role)')
      .single();

    if (error) return errResponse('Erro ao atualizar comunicado', 'DB_ERROR', 500);
    return jsonResponse({ data });
  }

  // ── DELETE /api/comunicados/:id ──────────────────────────────────────────────
  if (method === 'DELETE' && path) {
    const id = path.split('/')[0];
    if (!DELETE_ROLES.includes(role)) {
      return errResponse('Apenas coordenador, diretor ou admin podem excluir comunicados', 'FORBIDDEN', 403);
    }

    const { data: existing, error: fetchErr } = await supabase
      .from('announcements')
      .select('id')
      .eq('id', id)
      .eq('school_id', school_id)
      .is('deleted_at', null)
      .single();

    if (fetchErr || !existing) return errResponse('Comunicado não encontrado', 'NOT_FOUND', 404);

    // Soft delete
    const { error } = await supabase
      .from('announcements')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id)
      .eq('school_id', school_id);

    if (error) return errResponse('Erro ao excluir comunicado', 'DB_ERROR', 500);
    return jsonResponse({ success: true });
  }

  return errResponse('Método ou rota não permitido', 'METHOD_NOT_ALLOWED', 405);
}
