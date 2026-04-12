/**
 * ocorrencias.js — /api/ocorrencias
 * Lexend Scholar — Registro e histórico de ocorrências disciplinares/administrativas.
 *
 * GET    /api/ocorrencias                  — lista ocorrências da escola (paginado)
 * GET    /api/ocorrencias?id=UUID          — busca ocorrência por ID
 * GET    /api/ocorrencias?aluno_id=UUID    — filtra por aluno (alias: student_id)
 * GET    /api/ocorrencias?class_id=UUID    — filtra por turma
 * GET    /api/ocorrencias?resolved=bool    — filtra por status resolvida
 * GET    /api/ocorrencias?tipo=X           — filtra por tipo
 * POST   /api/ocorrencias                  — cria nova ocorrência
 * PUT    /api/ocorrencias                  — atualiza ocorrência (body: { id, ...fields })
 * DELETE /api/ocorrencias?id=UUID          — remove ocorrência (admin/secretary)
 *
 * Campos de ocorrência:
 *   aluno_id (student_id), tipo (disciplinar/elogio/saude/outro/administrativo/academico),
 *   descricao, data, registrado_por (reported_by), severity, resolved
 *
 * Roles permitidos: admin, secretary (leitura + escrita), teacher (leitura + criação)
 *
 * Tabela: occurrences
 * CREATE TABLE occurrences (
 *   id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 *   school_id        UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
 *   student_id       UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
 *   class_id         UUID REFERENCES classes(id),
 *   reported_by      UUID NOT NULL REFERENCES users(id),
 *   tipo             TEXT NOT NULL,   -- 'disciplinar' | 'elogio' | 'saude' | 'outro' | 'administrativo' | 'academico'
 *   severity         TEXT NOT NULL DEFAULT 'low',  -- 'low' | 'medium' | 'high'
 *   descricao        TEXT NOT NULL,
 *   data             DATE NOT NULL DEFAULT CURRENT_DATE,
 *   resolved         BOOLEAN NOT NULL DEFAULT FALSE,
 *   resolved_at      TIMESTAMPTZ,
 *   resolved_by      UUID REFERENCES users(id),
 *   resolution_notes TEXT,
 *   created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 *   updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
 * );
 */

import { authenticateRequest, apiError, parsePagination } from './_middleware.js';
import { supabase } from './_supabase.js';

const ALLOWED_ROLES = ['admin', 'secretary', 'teacher'];
const WRITE_ROLES   = ['admin', 'secretary', 'teacher'];
const DELETE_ROLES  = ['admin', 'secretary'];

const VALID_TIPOS      = ['disciplinar', 'elogio', 'saude', 'outro', 'administrativo', 'academico'];
const VALID_SEVERITIES = ['low', 'medium', 'high'];

export default async function handler(req, res) {
  // ── Authenticate ──────────────────────────────────────────────────────────
  await new Promise((resolve, reject) => {
    authenticateRequest(req, res, (err) => (err ? reject(err) : resolve()));
  });

  if (!ALLOWED_ROLES.includes(req.user.role)) {
    return apiError(res, 403, 'Acesso negado para este perfil', 'FORBIDDEN');
  }

  const { school_id, id: userId, role } = req.user;

  // ── GET ────────────────────────────────────────────────────────────────────
  if (req.method === 'GET') {
    // Support both aluno_id (PT-BR naming from issue spec) and student_id (internal)
    const {
      id,
      aluno_id, student_id,
      class_id,
      resolved,
      tipo, type,
      severity,
    } = req.query;

    const alunoId   = aluno_id || student_id;
    const tipoFilter = tipo || type;
    const { limit, offset } = parsePagination(req.query);

    // Single record lookup by ID
    if (id) {
      const { data, error } = await supabase
        .from('occurrences')
        .select(`
          *,
          aluno:students(id, full_name, enrollment_code),
          registrado_por:users!reported_by(id, full_name, role),
          resolvido_por:users!resolved_by(id, full_name, role),
          turma:classes(id, name)
        `)
        .eq('id', id)
        .eq('school_id', school_id)
        .single();

      if (error) return apiError(res, 404, 'Ocorrência não encontrada', 'NOT_FOUND');
      return res.status(200).json({ data: normalizeOcorrencia(data) });
    }

    // List with filters
    let query = supabase
      .from('occurrences')
      .select(`
        *,
        aluno:students(id, full_name, enrollment_code),
        registrado_por:users!reported_by(id, full_name, role),
        turma:classes(id, name)
      `, { count: 'exact' })
      .eq('school_id', school_id)
      .order('data', { ascending: false })
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (alunoId)   query = query.eq('student_id', alunoId);
    if (class_id)  query = query.eq('class_id', class_id);
    if (tipoFilter) query = query.eq('tipo', tipoFilter);
    if (severity)  query = query.eq('severity', severity);
    if (resolved !== undefined && resolved !== '') {
      query = query.eq('resolved', resolved === 'true');
    }

    // Teachers see only their own reported occurrences
    if (role === 'teacher') {
      query = query.eq('reported_by', userId);
    }

    const { data, error, count } = await query;
    if (error) return apiError(res, 500, 'Erro ao buscar ocorrências', 'DB_ERROR');

    return res.status(200).json({
      data: (data || []).map(normalizeOcorrencia),
      total: count,
      limit,
      offset,
    });
  }

  // ── POST — criar ocorrência ───────────────────────────────────────────────
  if (req.method === 'POST') {
    if (!WRITE_ROLES.includes(role)) {
      return apiError(res, 403, 'Sem permissão para criar ocorrências', 'FORBIDDEN');
    }

    // Accept PT-BR fields (aluno_id, descricao, tipo, data) or English equivalents
    const {
      aluno_id, student_id,
      class_id,
      tipo, type,
      descricao, description,
      severity = 'low',
      data: dataOcorrencia,
      registrado_por,  // ignored — always set from JWT
    } = req.body;

    const resolvedAlunoId   = aluno_id || student_id;
    const resolvedTipo      = tipo || type;
    const resolvedDescricao = descricao || description;
    const resolvedData      = dataOcorrencia || new Date().toISOString().slice(0, 10);

    if (!resolvedAlunoId || !resolvedTipo || !resolvedDescricao) {
      return apiError(
        res, 400,
        'Campos obrigatórios: aluno_id (ou student_id), tipo, descricao',
        'VALIDATION_ERROR'
      );
    }

    if (!VALID_TIPOS.includes(resolvedTipo)) {
      return apiError(
        res, 400,
        `tipo deve ser um de: ${VALID_TIPOS.join(', ')}`,
        'VALIDATION_ERROR'
      );
    }

    if (!VALID_SEVERITIES.includes(severity)) {
      return apiError(
        res, 400,
        `severity deve ser um de: ${VALID_SEVERITIES.join(', ')}`,
        'VALIDATION_ERROR'
      );
    }

    // Verify student belongs to this school
    const { data: student, error: studentErr } = await supabase
      .from('students')
      .select('id')
      .eq('id', resolvedAlunoId)
      .eq('school_id', school_id)
      .single();

    if (studentErr || !student) {
      return apiError(res, 404, 'Aluno não encontrado nesta escola', 'STUDENT_NOT_FOUND');
    }

    const { data, error } = await supabase
      .from('occurrences')
      .insert({
        school_id,
        student_id:  resolvedAlunoId,
        class_id:    class_id || null,
        reported_by: userId,
        tipo:        resolvedTipo,
        severity,
        descricao:   resolvedDescricao.trim(),
        data:        resolvedData,
        resolved:    false,
      })
      .select(`
        *,
        aluno:students(id, full_name, enrollment_code),
        registrado_por:users!reported_by(id, full_name, role)
      `)
      .single();

    if (error) return apiError(res, 500, 'Erro ao criar ocorrência', 'DB_ERROR');
    return res.status(201).json({ data: normalizeOcorrencia(data) });
  }

  // ── PUT — atualizar ocorrência ────────────────────────────────────────────
  if (req.method === 'PUT') {
    if (!WRITE_ROLES.includes(role)) {
      return apiError(res, 403, 'Sem permissão para atualizar ocorrências', 'FORBIDDEN');
    }

    const {
      id,
      resolved,
      resolution_notes,
      descricao, description,
      severity,
      tipo, type,
    } = req.body;

    if (!id) return apiError(res, 400, 'Campo obrigatório: id', 'VALIDATION_ERROR');

    // Ownership check
    const { data: existing, error: fetchErr } = await supabase
      .from('occurrences')
      .select('id, reported_by')
      .eq('id', id)
      .eq('school_id', school_id)
      .single();

    if (fetchErr || !existing) {
      return apiError(res, 404, 'Ocorrência não encontrada', 'NOT_FOUND');
    }

    // Teachers can only edit their own occurrences
    if (role === 'teacher' && existing.reported_by !== userId) {
      return apiError(res, 403, 'Sem permissão para editar esta ocorrência', 'FORBIDDEN');
    }

    const patch = { updated_at: new Date().toISOString() };
    const resolvedDesc = descricao || description;
    const resolvedTipo = tipo || type;

    if (resolvedDesc !== undefined)  patch.descricao = resolvedDesc.trim();
    if (resolvedTipo !== undefined)  patch.tipo = resolvedTipo;
    if (severity !== undefined)      patch.severity = severity;

    if (resolved === true) {
      patch.resolved           = true;
      patch.resolved_at        = new Date().toISOString();
      patch.resolved_by        = userId;
      patch.resolution_notes   = resolution_notes?.trim() || null;
    } else if (resolved === false) {
      patch.resolved           = false;
      patch.resolved_at        = null;
      patch.resolved_by        = null;
      patch.resolution_notes   = null;
    }

    const { data, error } = await supabase
      .from('occurrences')
      .update(patch)
      .eq('id', id)
      .eq('school_id', school_id)
      .select()
      .single();

    if (error) return apiError(res, 500, 'Erro ao atualizar ocorrência', 'DB_ERROR');
    return res.status(200).json({ data: normalizeOcorrencia(data) });
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  if (req.method === 'DELETE') {
    if (!DELETE_ROLES.includes(role)) {
      return apiError(
        res, 403,
        'Apenas admin e secretaria podem remover ocorrências',
        'FORBIDDEN'
      );
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

// ── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Normalizes a DB row to expose both Portuguese and English field aliases
 * so consumers can use either aluno_id/descricao/tipo or student_id/description/type.
 */
function normalizeOcorrencia(row) {
  if (!row) return row;
  return {
    ...row,
    // PT-BR aliases for primary fields
    aluno_id:       row.student_id,
    descricao:      row.descricao  || row.description,
    tipo:           row.tipo       || row.type,
    data:           row.data,
    registrado_por: row.registrado_por || null,
  };
}
