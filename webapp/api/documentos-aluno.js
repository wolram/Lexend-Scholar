/**
 * documentos-aluno.js — /api/documentos-aluno
 * Lexend Scholar — Gerenciamento de documentos de aluno (upload, listagem, download, remoção).
 *
 * Arquivos armazenados no Supabase Storage, bucket: "student-documents"
 * Metadados salvos na tabela: student_documents (ver migration LS-78)
 *
 * ─── Rotas ───────────────────────────────────────────────────────────────────
 * GET    /api/documentos-aluno?student_id=UUID          — lista documentos do aluno
 * GET    /api/documentos-aluno?id=UUID                  — URL assinada para download
 * POST   /api/documentos-aluno                          — registra documento após upload
 * POST   /api/documentos-aluno?action=presigned         — gera URL de upload pré-assinada
 * DELETE /api/documentos-aluno?id=UUID                  — remove do storage e metadados
 *
 * ─── Tipos de documento suportados (category) ────────────────────────────────
 *   rg              — RG (Registro Geral)
 *   cpf             — CPF
 *   certidao        — Certidão de nascimento / casamento
 *   comprovante     — Comprovante de residência
 *   laudo           — Laudo médico / psicológico
 *   historico       — Histórico escolar
 *   declaracao      — Declaração diversa
 *   foto            — Foto 3x4
 *   geral           — Outros documentos
 *
 * ─── Tabela ──────────────────────────────────────────────────────────────────
 * CREATE TABLE student_documents (
 *   id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 *   school_id    UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
 *   student_id   UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
 *   uploaded_by  UUID NOT NULL REFERENCES users(id),
 *   name         TEXT NOT NULL,
 *   filename     TEXT NOT NULL,
 *   storage_path TEXT NOT NULL,
 *   mime_type    TEXT NOT NULL,
 *   size_bytes   INTEGER NOT NULL,
 *   category     TEXT NOT NULL DEFAULT 'geral',
 *   public_url   TEXT,
 *   created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
 * );
 *
 * Roles: admin, secretary (leitura + escrita), teacher (somente leitura)
 */

import { authenticateRequest, apiError, parsePagination } from './_middleware.js';
import { supabase } from './_supabase.js';

const STORAGE_BUCKET    = 'student-documents';
const SIGNED_URL_EXPIRY = 60 * 60; // 1 hour in seconds

const ALLOWED_ROLES = ['admin', 'secretary', 'teacher'];
const WRITE_ROLES   = ['admin', 'secretary'];

// Human-readable labels (used in responses for UI display)
const CATEGORY_LABELS = {
  rg:          'RG (Registro Geral)',
  cpf:         'CPF',
  certidao:    'Certidão de Nascimento / Casamento',
  comprovante: 'Comprovante de Residência',
  laudo:       'Laudo Médico / Psicológico',
  historico:   'Histórico Escolar',
  declaracao:  'Declaração',
  foto:        'Foto 3x4',
  geral:       'Outros',
};

/**
 * NOTE — Routing alias:
 * This handler also serves /api/alunos/:id/documentos when the router
 * passes student_id from the path param via req.query.student_id or
 * req.params.id. The webapp router should do:
 *
 *   app.use('/api/alunos/:student_id/documentos', (req, _, next) => {
 *     req.query.student_id = req.params.student_id;
 *     next();
 *   }, documentosAlunoHandler);
 */

// Categories include all document types from LS-77 spec
const VALID_CATEGORIES = [
  'rg',           // RG - Registro Geral
  'cpf',          // CPF
  'certidao',     // Certidão de nascimento / casamento
  'comprovante',  // Comprovante de residência
  'laudo',        // Laudo médico / psicológico
  'historico',    // Histórico escolar
  'declaracao',   // Declaração diversa
  'foto',         // Foto 3x4
  'geral',        // Outros
];
const MAX_FILE_SIZE    = 20 * 1024 * 1024; // 20 MB
const ALLOWED_MIMES    = [
  'application/pdf',
  'image/jpeg', 'image/png', 'image/webp',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
];

export default async function handler(req, res) {
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
    const { id, student_id, category, action } = req.query;
    const { limit, offset } = parsePagination(req.query);

    // Generate signed download URL for a single document
    if (id) {
      const { data: doc, error: docErr } = await supabase
        .from('student_documents')
        .select('*')
        .eq('id', id)
        .eq('school_id', school_id)
        .single();

      if (docErr || !doc) return apiError(res, 404, 'Documento não encontrado', 'NOT_FOUND');

      const { data: signedData, error: signedErr } = await supabase.storage
        .from(STORAGE_BUCKET)
        .createSignedUrl(doc.storage_path, SIGNED_URL_EXPIRY);

      if (signedErr) return apiError(res, 500, 'Erro ao gerar URL de download', 'STORAGE_ERROR');

      return res.status(200).json({
        data: { ...doc, signed_url: signedData.signedUrl, expires_in: SIGNED_URL_EXPIRY },
      });
    }

    // List documents for a student
    if (!student_id) {
      return apiError(res, 400, 'Parâmetro student_id obrigatório', 'VALIDATION_ERROR');
    }

    let query = supabase
      .from('student_documents')
      .select(`
        id, name, filename, mime_type, size_bytes, category, created_at,
        uploader:users!uploaded_by(id, full_name)
      `, { count: 'exact' })
      .eq('student_id', student_id)
      .eq('school_id', school_id)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (category) query = query.eq('category', category);

    const { data, error, count } = await query;
    if (error) return apiError(res, 500, 'Erro ao buscar documentos', 'DB_ERROR');

    // Enrich with category label for UI display
    const enriched = (data || []).map((doc) => ({
      ...doc,
      category_label: CATEGORY_LABELS[doc.category] || doc.category,
    }));

    return res.status(200).json({ data: enriched, total: count, limit, offset });
  }

  // -------------------------------------------------------------------------
  // POST — generate presigned upload URL OR register document after upload
  // -------------------------------------------------------------------------
  if (req.method === 'POST') {
    if (!WRITE_ROLES.includes(role)) {
      return apiError(res, 403, 'Sem permissão para fazer upload de documentos', 'FORBIDDEN');
    }

    const { action } = req.query;

    // --- Generate presigned upload URL ---
    if (action === 'presigned') {
      const { student_id, filename, mime_type, size_bytes } = req.body;

      if (!student_id || !filename || !mime_type) {
        return apiError(res, 400, 'Campos obrigatórios: student_id, filename, mime_type', 'VALIDATION_ERROR');
      }

      if (!ALLOWED_MIMES.includes(mime_type)) {
        return apiError(res, 400, `Tipo de arquivo não permitido: ${mime_type}`, 'VALIDATION_ERROR');
      }

      if (size_bytes && size_bytes > MAX_FILE_SIZE) {
        return apiError(res, 400, 'Arquivo excede o limite de 20 MB', 'FILE_TOO_LARGE');
      }

      // Verify student belongs to school
      const { data: student } = await supabase
        .from('students')
        .select('id')
        .eq('id', student_id)
        .eq('school_id', school_id)
        .single();

      if (!student) return apiError(res, 404, 'Aluno não encontrado', 'STUDENT_NOT_FOUND');

      // Build a unique storage path: school_id/student_id/timestamp_filename
      const safeFilename = filename.replace(/[^a-zA-Z0-9._-]/g, '_');
      const storagePath  = `${school_id}/${student_id}/${Date.now()}_${safeFilename}`;

      const { data: uploadData, error: uploadErr } = await supabase.storage
        .from(STORAGE_BUCKET)
        .createSignedUploadUrl(storagePath);

      if (uploadErr) return apiError(res, 500, 'Erro ao gerar URL de upload', 'STORAGE_ERROR');

      return res.status(200).json({
        data: {
          signed_url: uploadData.signedUrl,
          token: uploadData.token,
          storage_path: storagePath,
        },
      });
    }

    // --- Register document metadata after upload ---
    const { student_id, name, filename, storage_path, mime_type, size_bytes, category = 'geral' } = req.body;

    if (!student_id || !name || !filename || !storage_path || !mime_type || !size_bytes) {
      return apiError(
        res, 400,
        'Campos obrigatórios: student_id, name, filename, storage_path, mime_type, size_bytes',
        'VALIDATION_ERROR'
      );
    }

    if (!VALID_CATEGORIES.includes(category)) {
      return apiError(res, 400, `category deve ser: ${VALID_CATEGORIES.join(', ')}`, 'VALIDATION_ERROR');
    }

    // Get public URL (if bucket is public) or leave null
    const { data: urlData } = supabase.storage
      .from(STORAGE_BUCKET)
      .getPublicUrl(storage_path);

    const { data, error } = await supabase
      .from('student_documents')
      .insert({
        school_id,
        student_id,
        uploaded_by: userId,
        name:        name.trim(),
        filename,
        storage_path,
        mime_type,
        size_bytes:  parseInt(size_bytes, 10),
        category,
        public_url:  urlData?.publicUrl || null,
      })
      .select()
      .single();

    if (error) return apiError(res, 500, 'Erro ao registrar documento', 'DB_ERROR');
    return res.status(201).json({ data });
  }

  // -------------------------------------------------------------------------
  // DELETE
  // -------------------------------------------------------------------------
  if (req.method === 'DELETE') {
    if (!WRITE_ROLES.includes(role)) {
      return apiError(res, 403, 'Sem permissão para remover documentos', 'FORBIDDEN');
    }

    const { id } = req.query;
    if (!id) return apiError(res, 400, 'Parâmetro id obrigatório', 'VALIDATION_ERROR');

    // Fetch metadata to get storage path
    const { data: doc, error: fetchErr } = await supabase
      .from('student_documents')
      .select('id, storage_path')
      .eq('id', id)
      .eq('school_id', school_id)
      .single();

    if (fetchErr || !doc) return apiError(res, 404, 'Documento não encontrado', 'NOT_FOUND');

    // Remove from storage
    const { error: storageErr } = await supabase.storage
      .from(STORAGE_BUCKET)
      .remove([doc.storage_path]);

    if (storageErr) {
      // Log but don't fail — metadata deletion is more important
      console.error('[documentos-aluno] Storage remove error:', storageErr);
    }

    // Remove metadata
    const { error: dbErr } = await supabase
      .from('student_documents')
      .delete()
      .eq('id', id)
      .eq('school_id', school_id);

    if (dbErr) return apiError(res, 500, 'Erro ao remover documento', 'DB_ERROR');
    return res.status(200).json({ success: true });
  }

  return apiError(res, 405, 'Método não permitido', 'METHOD_NOT_ALLOWED');
}
