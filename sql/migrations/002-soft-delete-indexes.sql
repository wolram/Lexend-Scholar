-- ============================================================
-- LS-83 — Migration 002: Soft delete support and performance indexes
-- Run order: after 001-add-missing-tables.sql
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- 1. ADD deleted_at SOFT-DELETE COLUMNS
--    Core entities + tables from LS-79/LS-80 that need soft delete.
-- ──────────────────────────────────────────────────────────────

-- Core entity tables
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

ALTER TABLE classes
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

-- occurrences (ocorrencias)
ALTER TABLE occurrences
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

-- messages — already created in 001; add deleted_at for soft delete
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

-- Supporting tables
ALTER TABLE grade_records
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

ALTER TABLE financial_records
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

ALTER TABLE attendance_records
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

ALTER TABLE class_subjects
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

ALTER TABLE guardians
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

ALTER TABLE subjects
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

ALTER TABLE grades
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

ALTER TABLE academic_periods
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

ALTER TABLE academic_years
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

-- ──────────────────────────────────────────────────────────────
-- 2. PARTIAL INDEXES — only index active / non-deleted rows
--    This significantly reduces index size for large schools.
-- ──────────────────────────────────────────────────────────────

-- Students (active only — deleted records excluded from normal queries)
CREATE INDEX IF NOT EXISTS idx_students_active_name
  ON students(school_id, full_name)
  WHERE active = TRUE;

CREATE INDEX IF NOT EXISTS idx_students_enrollment_code
  ON students(school_id, enrollment_code)
  WHERE active = TRUE;

-- Users (active staff only)
CREATE INDEX IF NOT EXISTS idx_users_active_role
  ON users(school_id, role)
  WHERE active = TRUE;

-- Attendance (non-deleted)
CREATE INDEX IF NOT EXISTS idx_attendance_active
  ON attendance_records(school_id, class_id, date)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_attendance_student_active
  ON attendance_records(student_id, date)
  WHERE deleted_at IS NULL;

-- Grade records (non-deleted)
CREATE INDEX IF NOT EXISTS idx_grade_records_active
  ON grade_records(school_id, student_id, subject_id, academic_period_id)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_grade_records_class_period
  ON grade_records(class_id, academic_period_id, subject_id)
  WHERE deleted_at IS NULL;

-- Financial (pending only — most queried state)
CREATE INDEX IF NOT EXISTS idx_financial_pending
  ON financial_records(school_id, due_date)
  WHERE payment_status = 'pending' AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_financial_overdue
  ON financial_records(school_id, student_id)
  WHERE payment_status = 'pending' AND due_date < CURRENT_DATE AND deleted_at IS NULL;

-- Enrollments (active only)
CREATE INDEX IF NOT EXISTS idx_enrollments_active_class
  ON student_class_enrollments(class_id)
  WHERE active = TRUE;

CREATE INDEX IF NOT EXISTS idx_enrollments_active_student
  ON student_class_enrollments(student_id)
  WHERE active = TRUE;

-- ──────────────────────────────────────────────────────────────
-- 3. COMPOSITE PERFORMANCE INDEXES for common query patterns
-- ──────────────────────────────────────────────────────────────

-- Classes lookup by school + academic year (most common filter combo)
CREATE INDEX IF NOT EXISTS idx_classes_school_year
  ON classes(school_id, academic_year_id, grade_id);

-- Subjects by school
CREATE INDEX IF NOT EXISTS idx_subjects_school
  ON subjects(school_id)
  WHERE deleted_at IS NULL;

-- Notifications (unread per user — hot path)
CREATE INDEX IF NOT EXISTS idx_notifications_unread
  ON notifications(user_id, created_at DESC)
  WHERE read = FALSE;

-- Events upcoming
CREATE INDEX IF NOT EXISTS idx_events_upcoming
  ON events(school_id, start_date)
  WHERE start_date >= CURRENT_DATE;

-- Assignments due soon
CREATE INDEX IF NOT EXISTS idx_assignments_due
  ON assignments(class_id, due_date)
  WHERE due_date >= CURRENT_DATE;

-- Period grade summaries (student boletim lookup)
CREATE INDEX IF NOT EXISTS idx_pgs_student_period
  ON period_grade_summaries(student_id, academic_period_id)
  WHERE final_score IS NOT NULL;

-- ──────────────────────────────────────────────────────────────
-- 4. FULL-TEXT SEARCH INDEX on students.full_name
-- ──────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_students_fulltext
  ON students USING gin(to_tsvector('portuguese', full_name))
  WHERE active = TRUE;

CREATE INDEX IF NOT EXISTS idx_users_fulltext
  ON users USING gin(to_tsvector('portuguese', full_name))
  WHERE active = TRUE;

-- ──────────────────────────────────────────────────────────────
-- 5. SOFT-DELETE HELPER FUNCTION
--    Use: SELECT soft_delete('grade_records', '<uuid>');
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION soft_delete(p_table TEXT, p_id UUID)
RETURNS VOID AS $$
BEGIN
  EXECUTE format('UPDATE %I SET deleted_at = NOW() WHERE id = $1 AND deleted_at IS NULL', p_table)
  USING p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ──────────────────────────────────────────────────────────────
-- 6. ROW LEVEL SECURITY HELPERS
--    Enable RLS on all tenant tables (assumes Supabase RLS is managed
--    via dashboard, but we establish policies here for completeness).
--    The service_role key bypasses RLS — anon/authenticated must satisfy policies.
-- ──────────────────────────────────────────────────────────────

-- Enable RLS on core tables (idempotent)
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'students', 'users', 'classes', 'grades', 'subjects',
    'student_class_enrollments', 'attendance_records', 'grade_records',
    'financial_records', 'academic_years', 'academic_periods',
    'class_subjects', 'guardians', 'student_guardians',
    'notifications', 'class_schedule', 'events', 'assignments',
    'assignment_submissions', 'messages', 'period_grade_summaries'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);
  END LOOP;
END;
$$;

-- School-scoped read policy for authenticated users
-- (Each table needs a policy; this creates a generic one for each)
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'students', 'classes', 'grades', 'subjects',
    'student_class_enrollments', 'attendance_records', 'grade_records',
    'academic_years', 'academic_periods', 'class_subjects', 'guardians',
    'class_schedule', 'events', 'assignments', 'period_grade_summaries'
  ] LOOP
    BEGIN
      EXECUTE format(
        'CREATE POLICY %I ON %I FOR ALL TO authenticated
         USING (school_id = (auth.jwt() ->> ''school_id'')::UUID)',
        'school_isolation_' || tbl, tbl
      );
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
  END LOOP;
END;
$$;

-- Users table: users can only see users in their school
DO $$
BEGIN
  CREATE POLICY users_school_isolation ON users FOR ALL TO authenticated
    USING (school_id = (auth.jwt() ->> 'school_id')::UUID);
EXCEPTION WHEN duplicate_object THEN NULL;
END;
$$;

-- Financial records: only admin/secretary can read all; teachers see none
DO $$
BEGIN
  CREATE POLICY financial_records_admin_only ON financial_records FOR ALL TO authenticated
    USING (
      school_id = (auth.jwt() ->> 'school_id')::UUID AND
      (auth.jwt() ->> 'role') IN ('admin', 'secretary')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END;
$$;

-- Notifications: users see only their own
DO $$
BEGIN
  CREATE POLICY notifications_own ON notifications FOR ALL TO authenticated
    USING (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL;
END;
$$;

-- Messages: sender or recipient
DO $$
BEGIN
  CREATE POLICY messages_own ON messages FOR ALL TO authenticated
    USING (sender_id = auth.uid() OR recipient_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- 7. INDEXES FOR NEW SOFT-DELETE COLUMNS (LS-83)
-- ──────────────────────────────────────────────────────────────

-- students with deleted_at
CREATE INDEX IF NOT EXISTS idx_students_deleted_at
  ON students(school_id, deleted_at)
  WHERE deleted_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_students_school_created
  ON students(school_id, created_at DESC)
  WHERE deleted_at IS NULL;

-- users with deleted_at
CREATE INDEX IF NOT EXISTS idx_users_school_created
  ON users(school_id, created_at DESC)
  WHERE deleted_at IS NULL;

-- classes with deleted_at
CREATE INDEX IF NOT EXISTS idx_classes_deleted_at
  ON classes(school_id, deleted_at)
  WHERE deleted_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_classes_school_created
  ON classes(school_id, created_at DESC)
  WHERE deleted_at IS NULL;

-- occurrences
CREATE INDEX IF NOT EXISTS idx_occurrences_school
  ON occurrences(school_id, created_at DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_occurrences_student
  ON occurrences(student_id, created_at DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_occurrences_class
  ON occurrences(class_id, created_at DESC)
  WHERE deleted_at IS NULL;

-- messages with deleted_at
CREATE INDEX IF NOT EXISTS idx_messages_recipient_active
  ON messages(recipient_id, read, created_at DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_messages_sender_active
  ON messages(sender_id, created_at DESC)
  WHERE deleted_at IS NULL;

-- ──────────────────────────────────────────────────────────────
-- 8. VIEW: alunos_ativos — exclui registros com deleted_at
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW alunos_ativos AS
  SELECT *
  FROM students
  WHERE deleted_at IS NULL
    AND active = TRUE;

COMMENT ON VIEW alunos_ativos IS
  'Alunos ativos e não excluídos logicamente. Use esta view para consultas de negócio padrão.';
