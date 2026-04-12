/**
 * ocorrencias.js — /api/ocorrencias
 * Lexend Scholar — Registro e histórico de ocorrências disciplinares/administrativas.
 *
 * GET    /api/ocorrencias              — lista ocorrências da escola (paginado)
 * GET    /api/ocorrencias?id=UUID      — busca ocorrência por ID
 * GET    /api/ocorrencias?student_id=  — filtra por aluno
 * GET    /api/ocorrencias?resolved=    — filtra por status (true/false)
 * POST   /api/ocorrencias              — cria nova ocorrência
 * PUT    /api/ocorrencias              — atualiza ocorrência (body: { id, ...fields })
 * DELETE /api/ocorrencias?id=UUID      — remove ocorrência (somente admin)
 *
 * Roles permitidos: admin, secretary (leitura + escrita), teacher (leitura + criação)
 *
 * Tabela: occurrences (não presente no schema original — migração necessária)
 * CREATE TABLE occurrences (
 *   id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 *   school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
 *   student_id  UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
 *   class_id    UUID REFERENCES classes(id),
 *   reported_by UUID NOT NULL REFERENCES users(id),
 *   type        TEXT NOT NULL,      -- 'disciplinar' | 'administrativo' | 'academico'
 *   severity    TEXT NOT NULL DEFAULT 'low',  -- 'low' | 'medium' | 'high'
 *   description TEXT NOT NULL,
 *   resolved    BOOLEAN NOT NULL DEFAULT FALSE,
 *   resolved_at TIMESTAMPTZ,
 *   resolved_by UUID REFERENCES users(id),
 *   resolution_notes TEXT,
 *   created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 *   updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
 * );
 */

import { authenticateRequest, apiError, parsePagination } from './_middleware.js';
import { supabase } from './_supabase.js';

const ALLOWED_ROLES = ['admin', 'secretary', 'teacher'];
const WRITE_ROLES   = ['admin', 'secretary', 'teacher'];
const DELETE_ROLES  = ['admin', 'secretary'];

export default async function handler(req, res) {
  // Authenticate
  await new Promise((resolve, reject) => {
    authenticateRequest(req, res, (err) => (err ? reject(err) : resolve()));
  });

  if (!ALLOWED_ROLES.includes(req.user.role)) {
    return apiError(res, 403, 'Acesso negado para este perfil', 'FORBIDDEN');
  }

  const { school_id, id: userId, role } = req.user;

  // -------------------------------------------------------------------------
  // GET
  // -------------------------------------------------------------------------
  if (req.method === 'GET') {
    const { id, student_id, class_id, resolved, type, severity } = req.query;
    const { limit, offset } = parsePagination(req.query);

    // Single record lookup
    if (id) {
      const { data, error } = await supabase
        .from('occurrences')
        .select(`
          *,
          student:students(id, full_name, enrollment_code),
          reporter:users!reported_by(id, full_name, role),
          resolver:users!resolved_by(id, full_name, role),
          class:classes(id, name)
        `)
        .eq('id', id)
        .eq('school_id', school_id)
        .single();

      if (error) return apiError(res, 404, 'Ocorrência não encontrada', 'NOT_FOUND');
      return res.status(200).json({ data });
    }

    // List with filters
    let query = supabase
      .from('occurrences')
      .select(`
        *,
        student:students(id, full_name, enrollment_code),
        reporter:users!reported_by(id, full_name, role),
        class:classes(id, name)
      `, { count: 'exact' })
      .eq('school_id', school_id)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (student_id)           query = query.eq('student_id', student_id);
    if (class_id)             query = query.eq('class_id', class_id);
    if (resolved !== undefined && resolved !== '') {
      query = query.eq('resolved', resolved === 'true');
    }
    if (type)     query = query.eq('type', type);
    if (severity) query = query.eq('severity', severity);

    // Teachers can only see their own class occurrences
    if (role === 'teacher') {
      query = query.eq('reported_by', userId);
    }

    const { data, error, count } = await query;
    if (error) return apiError(res, 500, 'Erro ao buscar ocorrências', 'DB_ERROR');

    return res.status(200).json({ data, total: count, limit, offset });
  }

  // -------------------------------------------------------------------------
  // POST — create
  // -------------------------------------------------------------------------
  if (req.method === 'POST') {
    if (!WRITE_ROLES.includes(role)) {
      return apiError(res, 403, 'Sem permissão para criar ocorrências', 'FORBIDDEN');
    }

    const { student_id, class_id, type, severity = 'low', description } = req.body;

    if (!student_id || !type || !description) {
      return apiError(res, 400, 'Campos obrigatórios: student_id, type, description', 'VALIDATION_ERROR');
    }

    const VALID_TYPES     = ['disciplinar', 'administrativo', 'academico'];
    const VALID_SEVERITIES = ['low', 'medium', 'high'];

    if (!VALID_TYPES.includes(type)) {
      return apiError(res, 400, `type deve ser um de: ${VALID_TYPES.join(', ')}`, 'VALIDATION_ERROR');
    }
    if (!VALID_SEVERITIES.includes(severity)) {
      return apiError(res, 400, `severity deve ser um de: ${VALID_SEVERITIES.join(', ')}`, 'VALIDATION_ERROR');
    }

    // Verify student belongs to school
    const { data: student, error: studentErr } = await supabase
      .from('students')
      .select('id')
      .eq('id', student_id)
      .eq('school_id', school_id)
      .single();

    if (studentErr || !student) {
      return apiError(res, 404, 'Aluno não encontrado nesta escola', 'STUDENT_NOT_FOUND');
    }

    const { data, error } = await supabase
      .from('occurrences')
      .insert({
        school_id,
        student_id,
        class_id: class_id || null,
        reported_by: userId,
        type,
        severity,
        description: description.trim(),
        resolved: false,
      })
      .select(`
        *,
        student:students(id, full_name, enrollment_code),
        reporter:users!reported_by(id, full_name, role)
      `)
      .single();

    if (error) return apiError(res, 500, 'Erro ao criar ocorrência', 'DB_ERROR');
    return res.status(201).json({ data });
  }

  // -------------------------------------------------------------------------
  // PUT — update / resolve
  // -------------------------------------------------------------------------
  if (req.method === 'PUT') {
    if (!WRITE_ROLES.includes(role)) {
      return apiError(res, 403, 'Sem permissão para atualizar ocorrências', 'FORBIDDEN');
    }

    const { id, resolved, resolution_notes, description, severity } = req.body;
    if (!id) return apiError(res, 400, 'Campo obrigatório: id', 'VALIDATION_ERROR');

    // Check ownership
    const { data: existing, error: fetchErr } = await supabase
      .from('occurrences')
      .select('id, reported_by')
      .eq('id', id)
      .eq('school_id', school_id)
      .single();

    if (fetchErr || !existing) return apiError(res, 404, 'Ocorrência não encontrada', 'NOT_FOUND');

    // Teachers can only update their own occurrences
    if (role === 'teacher' && existing.reported_by !== userId) {
      return apiError(res, 403, 'Sem permissão para editar esta ocorrência', 'FORBIDDEN');
    }

    const patch = { updated_at: new Date().toISOString() };
    if (description !== undefined)       patch.description = description.trim();
    if (severity !== undefined)          patch.severity = severity;
    if (resolved === true) {
      patch.resolved      = true;
      patch.resolved_at   = new Date().toISOString();
      patch.resolved_by   = userId;
      patch.resolution_notes = resolution_notes?.trim() || null;
    }
    if (resolved === false) {
      patch.resolved         = false;
      patch.resolved_at      = null;
      patch.resolved_by      = null;
      patch.resolution_notes = null;
    }

    const { data, error } = await supabase
      .from('occurrences')
      .update(patch)
      .eq('id', id)
      .eq('school_id', school_id)
      .select()
      .single();

    if (error) return apiError(res, 500, 'Erro ao atualizar ocorrência', 'DB_ERROR');
    return res.status(200).json({ data });
  }

  // -------------------------------------------------------------------------
  // DELETE
  // -------------------------------------------------------------------------
  if (req.method === 'DELETE') {
    if (!DELETE_ROLES.includes(role)) {
      return apiError(res, 403, 'Apenas admin e secretaria podem remover ocorrências', 'FORBIDDEN');
    }

    const { id } = req.query;
    if (!id) return apiError(res, 400, 'Parâmetro id obrigatório', 'VALIDATION_ERROR');

    const { error } = await supabase
      .from('occurrences')
      .delete()
      .eq('id', id)
      .eq('school_id', school_id);

    if (error) return apiError(res, 500, 'Erro ao remover ocorrência', 'DB_ERROR');
    return res.status(200).json({ success: true });
  }

  return apiError(res, 405, 'Método não permitido', 'METHOD_NOT_ALLOWED');
}
