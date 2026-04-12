-- ============================================================
-- LS-105: RLS por role e school_id
-- Migration: 006-rls-policies.sql
-- ============================================================
-- Convenção de roles:
--   admin      → diretor / admin global da escola
--   secretary  → secretaria
--   teacher    → professor / coordenador
--   guardian   → responsavel
--   student    → aluno
-- ============================================================

-- ------------------------------------------------------------
-- Habilitar RLS em todas as tabelas principais
-- ------------------------------------------------------------
ALTER TABLE public.students              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grades                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_subjects        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grade_records         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_records     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_years        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_periods      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guardians             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_guardians     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_class_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users                 ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- TABELA: students (alunos)
-- ============================================================
DROP POLICY IF EXISTS "students_select_school" ON public.students;
DROP POLICY IF EXISTS "students_insert_staff"  ON public.students;
DROP POLICY IF EXISTS "students_update_staff"  ON public.students;
DROP POLICY IF EXISTS "students_delete_admin"  ON public.students;

-- SELECT: escola inteira (admin, secretaria, professor) ou próprio aluno / guardião
CREATE POLICY "students_select_school" ON public.students
  FOR SELECT USING (
    school_id = public.get_current_school_id()
    AND (
      public.get_current_user_role() IN ('admin', 'secretary', 'teacher', 'coordinator')
      OR id IN (
        SELECT sg.student_id FROM public.student_guardians sg
        WHERE sg.guardian_id = public.get_current_user_id()
      )
    )
  );

-- INSERT: admin e secretaria
CREATE POLICY "students_insert_staff" ON public.students
  FOR INSERT WITH CHECK (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() IN ('admin', 'secretary')
  );

-- UPDATE: admin e secretaria
CREATE POLICY "students_update_staff" ON public.students
  FOR UPDATE USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() IN ('admin', 'secretary')
  );

-- DELETE: apenas admin
CREATE POLICY "students_delete_admin" ON public.students
  FOR DELETE USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() = 'admin'
  );

-- ============================================================
-- TABELA: users (professores / staff)
-- ============================================================
DROP POLICY IF EXISTS "users_select_school"  ON public.users;
DROP POLICY IF EXISTS "users_insert_admin"   ON public.users;
DROP POLICY IF EXISTS "users_update_self"    ON public.users;
DROP POLICY IF EXISTS "users_delete_admin"   ON public.users;

CREATE POLICY "users_select_school" ON public.users
  FOR SELECT USING (
    school_id = public.get_current_school_id()
  );

CREATE POLICY "users_insert_admin" ON public.users
  FOR INSERT WITH CHECK (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() = 'admin'
  );

-- Usuário pode atualizar o próprio perfil; admin pode atualizar qualquer um
CREATE POLICY "users_update_self" ON public.users
  FOR UPDATE USING (
    school_id = public.get_current_school_id()
    AND (
      auth_id = auth.uid()
      OR public.get_current_user_role() = 'admin'
    )
  );

CREATE POLICY "users_delete_admin" ON public.users
  FOR DELETE USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() = 'admin'
  );

-- ============================================================
-- TABELA: classes (turmas)
-- ============================================================
DROP POLICY IF EXISTS "classes_select_school"   ON public.classes;
DROP POLICY IF EXISTS "classes_insert_admin"    ON public.classes;
DROP POLICY IF EXISTS "classes_update_admin"    ON public.classes;
DROP POLICY IF EXISTS "classes_delete_admin"    ON public.classes;

CREATE POLICY "classes_select_school" ON public.classes
  FOR SELECT USING (
    school_id = public.get_current_school_id()
  );

CREATE POLICY "classes_insert_admin" ON public.classes
  FOR INSERT WITH CHECK (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() IN ('admin', 'secretary')
  );

CREATE POLICY "classes_update_admin" ON public.classes
  FOR UPDATE USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() IN ('admin', 'secretary')
  );

CREATE POLICY "classes_delete_admin" ON public.classes
  FOR DELETE USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() = 'admin'
  );

-- ============================================================
-- TABELA: attendance_records (ocorrências / frequência)
-- ============================================================
DROP POLICY IF EXISTS "attendance_select_school"  ON public.attendance_records;
DROP POLICY IF EXISTS "attendance_insert_teacher" ON public.attendance_records;
DROP POLICY IF EXISTS "attendance_update_teacher" ON public.attendance_records;
DROP POLICY IF EXISTS "attendance_delete_admin"   ON public.attendance_records;

CREATE POLICY "attendance_select_school" ON public.attendance_records
  FOR SELECT USING (
    school_id = public.get_current_school_id()
    AND (
      public.get_current_user_role() IN ('admin', 'secretary', 'teacher', 'coordinator')
      OR student_id IN (
        SELECT sg.student_id FROM public.student_guardians sg
        WHERE sg.guardian_id = public.get_current_user_id()
      )
    )
  );

CREATE POLICY "attendance_insert_teacher" ON public.attendance_records
  FOR INSERT WITH CHECK (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() IN ('admin', 'secretary', 'teacher', 'coordinator')
  );

CREATE POLICY "attendance_update_teacher" ON public.attendance_records
  FOR UPDATE USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() IN ('admin', 'secretary', 'teacher', 'coordinator')
  );

CREATE POLICY "attendance_delete_admin" ON public.attendance_records
  FOR DELETE USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() = 'admin'
  );

-- ============================================================
-- TABELA: grade_records (comunicados / notas)
-- professor pode criar; diretor/admin pode ver todos
-- ============================================================
DROP POLICY IF EXISTS "grade_records_select" ON public.grade_records;
DROP POLICY IF EXISTS "grade_records_insert" ON public.grade_records;
DROP POLICY IF EXISTS "grade_records_update" ON public.grade_records;
DROP POLICY IF EXISTS "grade_records_delete" ON public.grade_records;

CREATE POLICY "grade_records_select" ON public.grade_records
  FOR SELECT USING (
    school_id = public.get_current_school_id()
    AND (
      public.get_current_user_role() IN ('admin', 'secretary', 'teacher', 'coordinator')
      OR student_id IN (
        SELECT sg.student_id FROM public.student_guardians sg
        WHERE sg.guardian_id = public.get_current_user_id()
      )
    )
  );

CREATE POLICY "grade_records_insert" ON public.grade_records
  FOR INSERT WITH CHECK (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() IN ('admin', 'teacher', 'coordinator')
  );

CREATE POLICY "grade_records_update" ON public.grade_records
  FOR UPDATE USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() IN ('admin', 'teacher', 'coordinator')
  );

CREATE POLICY "grade_records_delete" ON public.grade_records
  FOR DELETE USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() = 'admin'
  );

-- ============================================================
-- TABELA: financial_records (mensagens financeiras)
-- usuário vê apenas mensagens de sua escola; admin vê tudo
-- ============================================================
DROP POLICY IF EXISTS "financial_select_school"    ON public.financial_records;
DROP POLICY IF EXISTS "financial_insert_secretary" ON public.financial_records;
DROP POLICY IF EXISTS "financial_update_secretary" ON public.financial_records;
DROP POLICY IF EXISTS "financial_delete_admin"     ON public.financial_records;

CREATE POLICY "financial_select_school" ON public.financial_records
  FOR SELECT USING (
    school_id = public.get_current_school_id()
    AND (
      public.get_current_user_role() IN ('admin', 'secretary')
      OR student_id IN (
        SELECT sg.student_id FROM public.student_guardians sg
        WHERE sg.guardian_id = public.get_current_user_id()
      )
    )
  );

CREATE POLICY "financial_insert_secretary" ON public.financial_records
  FOR INSERT WITH CHECK (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() IN ('admin', 'secretary')
  );

CREATE POLICY "financial_update_secretary" ON public.financial_records
  FOR UPDATE USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() IN ('admin', 'secretary')
  );

CREATE POLICY "financial_delete_admin" ON public.financial_records
  FOR DELETE USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() = 'admin'
  );

-- ============================================================
-- TABELA: guardians
-- ============================================================
DROP POLICY IF EXISTS "guardians_select_school" ON public.guardians;
DROP POLICY IF EXISTS "guardians_insert_staff"  ON public.guardians;
DROP POLICY IF EXISTS "guardians_update_staff"  ON public.guardians;
DROP POLICY IF EXISTS "guardians_delete_admin"  ON public.guardians;

CREATE POLICY "guardians_select_school" ON public.guardians
  FOR SELECT USING (
    school_id = public.get_current_school_id()
    AND (
      public.get_current_user_role() IN ('admin', 'secretary', 'teacher', 'coordinator')
      OR id = public.get_current_user_id()
    )
  );

CREATE POLICY "guardians_insert_staff" ON public.guardians
  FOR INSERT WITH CHECK (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() IN ('admin', 'secretary')
  );

CREATE POLICY "guardians_update_staff" ON public.guardians
  FOR UPDATE USING (
    school_id = public.get_current_school_id()
    AND (
      id = public.get_current_user_id()
      OR public.get_current_user_role() IN ('admin', 'secretary')
    )
  );

CREATE POLICY "guardians_delete_admin" ON public.guardians
  FOR DELETE USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() = 'admin'
  );

-- ============================================================
-- TABELAS de leitura geral da escola (grades, subjects, etc.)
-- ============================================================

-- grades
DROP POLICY IF EXISTS "grades_select_school" ON public.grades;
DROP POLICY IF EXISTS "grades_write_admin"   ON public.grades;

CREATE POLICY "grades_select_school" ON public.grades
  FOR SELECT USING (school_id = public.get_current_school_id());

CREATE POLICY "grades_write_admin" ON public.grades
  FOR ALL USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() IN ('admin', 'secretary')
  );

-- subjects
DROP POLICY IF EXISTS "subjects_select_school" ON public.subjects;
DROP POLICY IF EXISTS "subjects_write_admin"   ON public.subjects;

CREATE POLICY "subjects_select_school" ON public.subjects
  FOR SELECT USING (school_id = public.get_current_school_id());

CREATE POLICY "subjects_write_admin" ON public.subjects
  FOR ALL USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() IN ('admin', 'secretary')
  );

-- academic_years
DROP POLICY IF EXISTS "academic_years_select" ON public.academic_years;
DROP POLICY IF EXISTS "academic_years_write"  ON public.academic_years;

CREATE POLICY "academic_years_select" ON public.academic_years
  FOR SELECT USING (school_id = public.get_current_school_id());

CREATE POLICY "academic_years_write" ON public.academic_years
  FOR ALL USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() = 'admin'
  );

-- academic_periods
DROP POLICY IF EXISTS "academic_periods_select" ON public.academic_periods;
DROP POLICY IF EXISTS "academic_periods_write"  ON public.academic_periods;

CREATE POLICY "academic_periods_select" ON public.academic_periods
  FOR SELECT USING (school_id = public.get_current_school_id());

CREATE POLICY "academic_periods_write" ON public.academic_periods
  FOR ALL USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() = 'admin'
  );
