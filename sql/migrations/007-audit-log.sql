-- ============================================================
-- LS-106: Auditoria de ações críticas
-- Migration: 007-audit-log.sql
-- ============================================================

-- ------------------------------------------------------------
-- TABELA: audit_log
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.audit_log (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID        NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  user_id     UUID        REFERENCES public.users(id) ON DELETE SET NULL,
  auth_id     UUID,                          -- auth.users.id snapshot
  action      TEXT        NOT NULL,          -- 'INSERT' | 'UPDATE' | 'DELETE'
  table_name  TEXT        NOT NULL,
  record_id   UUID        NOT NULL,
  old_values  JSONB,
  new_values  JSONB,
  ip_address  INET,
  user_agent  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices para consultas frequentes
CREATE INDEX IF NOT EXISTS idx_audit_log_school_id   ON public.audit_log (school_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_user_id     ON public.audit_log (user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_table_name  ON public.audit_log (table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_record_id   ON public.audit_log (record_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at  ON public.audit_log (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_action      ON public.audit_log (action);

-- Proteger audit_log: leitura apenas por admin; ninguém pode deletar
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "audit_log_select_admin" ON public.audit_log;
DROP POLICY IF EXISTS "audit_log_insert_deny"  ON public.audit_log;

CREATE POLICY "audit_log_select_admin" ON public.audit_log
  FOR SELECT USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() = 'admin'
  );

-- INSERT apenas via função SECURITY DEFINER (trigger)
-- Usuários normais não podem inserir diretamente

-- ------------------------------------------------------------
-- FUNÇÃO: log_audit_action()
-- Trigger function chamada em INSERT/UPDATE/DELETE nas tabelas críticas
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.log_audit_action()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_school_id  UUID;
  v_user_id    UUID;
  v_record_id  UUID;
  v_old_values JSONB;
  v_new_values JSONB;
BEGIN
  -- Identificar school_id e user_id do registro
  IF TG_OP = 'DELETE' THEN
    v_school_id  := (row_to_json(OLD)->>'school_id')::UUID;
    v_record_id  := (row_to_json(OLD)->>'id')::UUID;
    v_old_values := row_to_json(OLD)::JSONB;
    v_new_values := NULL;
  ELSIF TG_OP = 'INSERT' THEN
    v_school_id  := (row_to_json(NEW)->>'school_id')::UUID;
    v_record_id  := (row_to_json(NEW)->>'id')::UUID;
    v_old_values := NULL;
    v_new_values := row_to_json(NEW)::JSONB;
  ELSE -- UPDATE
    v_school_id  := (row_to_json(NEW)->>'school_id')::UUID;
    v_record_id  := (row_to_json(NEW)->>'id')::UUID;
    v_old_values := row_to_json(OLD)::JSONB;
    v_new_values := row_to_json(NEW)::JSONB;
  END IF;

  -- Obter user_id do usuário autenticado
  v_user_id := public.get_current_user_id();

  INSERT INTO public.audit_log (
    school_id,
    user_id,
    auth_id,
    action,
    table_name,
    record_id,
    old_values,
    new_values,
    created_at
  ) VALUES (
    v_school_id,
    v_user_id,
    auth.uid(),
    TG_OP,
    TG_TABLE_NAME,
    v_record_id,
    v_old_values,
    v_new_values,
    NOW()
  );

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$;

-- ------------------------------------------------------------
-- TRIGGERS: aplicar log_audit_action nas tabelas críticas
-- ------------------------------------------------------------

-- students
DROP TRIGGER IF EXISTS audit_students ON public.students;
CREATE TRIGGER audit_students
  AFTER INSERT OR UPDATE OR DELETE ON public.students
  FOR EACH ROW EXECUTE FUNCTION public.log_audit_action();

-- users (staff / professores)
DROP TRIGGER IF EXISTS audit_users ON public.users;
CREATE TRIGGER audit_users
  AFTER INSERT OR UPDATE OR DELETE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.log_audit_action();

-- student_class_enrollments (matrículas)
DROP TRIGGER IF EXISTS audit_enrollments ON public.student_class_enrollments;
CREATE TRIGGER audit_enrollments
  AFTER INSERT OR UPDATE OR DELETE ON public.student_class_enrollments
  FOR EACH ROW EXECUTE FUNCTION public.log_audit_action();

-- financial_records (financeiro)
DROP TRIGGER IF EXISTS audit_financial ON public.financial_records;
CREATE TRIGGER audit_financial
  AFTER INSERT OR UPDATE OR DELETE ON public.financial_records
  FOR EACH ROW EXECUTE FUNCTION public.log_audit_action();

-- grade_records (notas — permissões críticas)
DROP TRIGGER IF EXISTS audit_grade_records ON public.grade_records;
CREATE TRIGGER audit_grade_records
  AFTER INSERT OR UPDATE OR DELETE ON public.grade_records
  FOR EACH ROW EXECUTE FUNCTION public.log_audit_action();

-- attendance_records (frequência)
DROP TRIGGER IF EXISTS audit_attendance ON public.attendance_records;
CREATE TRIGGER audit_attendance
  AFTER INSERT OR UPDATE OR DELETE ON public.attendance_records
  FOR EACH ROW EXECUTE FUNCTION public.log_audit_action();

COMMENT ON TABLE public.audit_log IS
  'Log imutável de todas as ações críticas por tabela. Somente admins podem consultar.';

COMMENT ON FUNCTION public.log_audit_action() IS
  'Trigger function que registra INSERT/UPDATE/DELETE nas tabelas críticas no audit_log.';
