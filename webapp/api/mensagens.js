/**
 * mensagens.js — /api/mensagens
 * Lexend Scholar — Mensagens escola ↔ responsável.
 *
 * POST   /api/mensagens                     — enviar mensagem
 * GET    /api/mensagens/caixa-de-entrada    — listar mensagens recebidas
 * GET    /api/mensagens/enviadas            — listar mensagens enviadas
 * PUT    /api/mensagens/:id/lida            — marcar como lida
 * GET    /api/mensagens/nao-lidas/count     — contador de não lidas
 *
 * Usa tabela messages (criada em sql/migrations/001-add-missing-tables.sql),
 * expandida com coluna deleted_at em 002-soft-delete-indexes.sql.
 */

import { getAuthUser, jsonResponse, errResponse, parsePagination } from './_middleware.js';
import { supabase } from './_supabase.js';

export default async function handler(request) {
  const user = await getAuthUser(request);
  if (!user) return errResponse('Não autenticado', 'UNAUTHORIZED', 401);

  const url    = new URL(request.url);
  const path   = url.pathname.replace(/^\/api\/mensagens\/?/, '');
  const method = request.method.toUpperCase();
  const { school_id, id: userId } = user;

  // ── GET /api/mensagens/nao-lidas/count ───────────────────────────────────────
  if (method === 'GET' && path === 'nao-lidas/count') {
    const { count, error } = await supabase
      .from('messages')
      .select('id', { count: 'exact', head: true })
      .eq('school_id', school_id)
      .eq('recipient_id', userId)
      .eq('read', false)
      .is('deleted_at', null);

    if (error) return errResponse('Erro ao contar mensagens', 'DB_ERROR', 500);
    return jsonResponse({ count });
  }

  // ── GET /api/mensagens/caixa-de-entrada ─────────────────────────────────────
  if (method === 'GET' && path === 'caixa-de-entrada') {
    const { limit, offset } = parsePagination(url);

    const { data, error, count } = await supabase
      .from('messages')
      .select(
        'id, subject, body, read, read_at, created_at, sender:users!sender_id(id, full_name, role)',
        { count: 'exact' }
      )
      .eq('school_id', school_id)
      .eq('recipient_id', userId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) return errResponse('Erro ao buscar mensagens', 'DB_ERROR', 500);
    return jsonResponse({ data, total: count, limit, offset });
  }

  // ── GET /api/mensagens/enviadas ──────────────────────────────────────────────
  if (method === 'GET' && path === 'enviadas') {
    const { limit, offset } = parsePagination(url);

    const { data, error, count } = await supabase
      .from('messages')
      .select(
        'id, subject, body, read, read_at, created_at, recipient:users!recipient_id(id, full_name, role)',
        { count: 'exact' }
      )
      .eq('school_id', school_id)
      .eq('sender_id', userId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) return errResponse('Erro ao buscar mensagens enviadas', 'DB_ERROR', 500);
    return jsonResponse({ data, total: count, limit, offset });
  }

  // ── POST /api/mensagens ──────────────────────────────────────────────────────
  if (method === 'POST' && !path) {
    let body;
    try { body = await request.json(); } catch { return errResponse('Body JSON inválido', 'BAD_REQUEST', 400); }

    const { recipient_id, subject, body: msgBody } = body;

    if (!recipient_id || !msgBody) {
      return errResponse('Campos obrigatórios: recipient_id, body', 'VALIDATION_ERROR', 400);
    }

    // Verificar que o destinatário pertence à mesma escola
    const { data: recipient, error: recipErr } = await supabase
      .from('users')
      .select('id')
      .eq('id', recipient_id)
      .eq('school_id', school_id)
      .single();

    if (recipErr || !recipient) {
      return errResponse('Destinatário não encontrado nesta escola', 'NOT_FOUND', 404);
    }

    const { data, error } = await supabase
      .from('messages')
      .insert({
        school_id,
        sender_id:    userId,
        recipient_id,
        subject:      subject?.trim() || null,
        body:         msgBody.trim(),
        read:         false,
      })
      .select(
        'id, subject, body, read, created_at, recipient:users!recipient_id(id, full_name, role)'
      )
      .single();

    if (error) return errResponse('Erro ao enviar mensagem', 'DB_ERROR', 500);
    return jsonResponse({ data }, 201);
  }

  // ── PUT /api/mensagens/:id/lida ──────────────────────────────────────────────
  if (method === 'PUT' && path.endsWith('/lida')) {
    const id = path.replace('/lida', '').split('/')[0];
    if (!id) return errResponse('ID da mensagem obrigatório', 'VALIDATION_ERROR', 400);

    // Só o destinatário pode marcar como lida
    const { data: existing, error: fetchErr } = await supabase
      .from('messages')
      .select('id, recipient_id, read')
      .eq('id', id)
      .eq('school_id', school_id)
      .is('deleted_at', null)
      .single();

    if (fetchErr || !existing) return errResponse('Mensagem não encontrada', 'NOT_FOUND', 404);
    if (existing.recipient_id !== userId) {
      return errResponse('Sem permissão para marcar esta mensagem', 'FORBIDDEN', 403);
    }

    if (existing.read) return jsonResponse({ data: existing }); // já lida — idempotente

    const { data, error } = await supabase
      .from('messages')
      .update({ read: true, read_at: new Date().toISOString() })
      .eq('id', id)
      .select('id, subject, read, read_at')
      .single();

    if (error) return errResponse('Erro ao marcar mensagem como lida', 'DB_ERROR', 500);
    return jsonResponse({ data });
  }

  return errResponse('Método ou rota não permitido', 'METHOD_NOT_ALLOWED', 405);
}
