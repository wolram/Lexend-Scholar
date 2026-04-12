-- ============================================================
-- LS-78 — Migration 001: Add missing tables to school schema
-- Run order: after initial schema (database_schema.sql)
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- ACADEMIC YEARS (if not present — safe CREATE IF NOT EXISTS)
-- already in database_schema.sql but re-declared safely here
-- ──────────────────────────────────────────────────────────────

-- ──────────────────────────────────────────────────────────────
-- NOTIFICATIONS — in-app notification inbox per user
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  type        TEXT NOT NULL DEFAULT 'info',        -- info | warning | error | success
  data        JSONB,                               -- arbitrary payload
  read        BOOLEAN NOT NULL DEFAULT FALSE,
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_school ON notifications(school_id, created_at DESC);

-- ──────────────────────────────────────────────────────────────
-- CLASS SCHEDULE — weekly timetable slots per class/subject
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS class_schedule (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  class_id        UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id      UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  teacher_id      UUID NOT NULL REFERENCES users(id),
  day_of_week     SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sun, 1=Mon ... 6=Sat
  start_time      TIME NOT NULL,
  end_time        TIME NOT NULL,
  room            TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT class_schedule_no_overlap UNIQUE (class_id, day_of_week, start_time)
);

CREATE INDEX IF NOT EXISTS idx_class_schedule_class ON class_schedule(class_id, day_of_week);
CREATE INDEX IF NOT EXISTS idx_class_schedule_teacher ON class_schedule(teacher_id, day_of_week);

-- ──────────────────────────────────────────────────────────────
-- EVENTS / CALENDAR — school events visible to guardians/students
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS events (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id    UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  description  TEXT,
  event_type   TEXT NOT NULL DEFAULT 'general',    -- general | holiday | exam | meeting | activity
  start_date   TIMESTAMPTZ NOT NULL,
  end_date     TIMESTAMPTZ NOT NULL,
  all_day      BOOLEAN NOT NULL DEFAULT FALSE,
  class_ids    UUID[],                             -- NULL = school-wide
  created_by   UUID REFERENCES users(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_events_school_date ON events(school_id, start_date);

-- ──────────────────────────────────────────────────────────────
-- ASSIGNMENTS / TAREFAS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS assignments (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id          UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  class_id           UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id         UUID NOT NULL REFERENCES subjects(id),
  teacher_id         UUID NOT NULL REFERENCES users(id),
  title              TEXT NOT NULL,
  description        TEXT,
  due_date           DATE NOT NULL,
  max_score          NUMERIC(5,2) NOT NULL DEFAULT 10.00,
  attachment_url     TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_assignments_class ON assignments(class_id, due_date);
CREATE INDEX IF NOT EXISTS idx_assignments_teacher ON assignments(teacher_id);

-- ──────────────────────────────────────────────────────────────
-- ASSIGNMENT SUBMISSIONS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS assignment_submissions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id UUID NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  student_id    UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  submitted_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  file_url      TEXT,
  notes         TEXT,
  score         NUMERIC(5,2),
  graded_at     TIMESTAMPTZ,
  graded_by     UUID REFERENCES users(id),
  UNIQUE(assignment_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_submissions_assignment ON assignment_submissions(assignment_id);
CREATE INDEX IF NOT EXISTS idx_submissions_student ON assignment_submissions(student_id);

-- ──────────────────────────────────────────────────────────────
-- MESSAGES — internal messaging between staff
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id    UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  sender_id    UUID NOT NULL REFERENCES users(id),
  recipient_id UUID NOT NULL REFERENCES users(id),
  subject      TEXT,
  body         TEXT NOT NULL,
  read         BOOLEAN NOT NULL DEFAULT FALSE,
  read_at      TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages(recipient_id, read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id, created_at DESC);

-- ──────────────────────────────────────────────────────────────
-- AUDIT LOG — track record-level changes
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_log (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id    UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  user_id      UUID REFERENCES users(id),
  table_name   TEXT NOT NULL,
  record_id    UUID NOT NULL,
  operation    TEXT NOT NULL CHECK (operation IN ('INSERT','UPDATE','DELETE')),
  old_data     JSONB,
  new_data     JSONB,
  ip_address   INET,
  user_agent   TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_school ON audit_log(school_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_record ON audit_log(table_name, record_id);

-- ──────────────────────────────────────────────────────────────
-- ACADEMIC PERIOD GRADES SUMMARY (materialized-style computed)
-- Stores final aggregated grade per student per subject per period.
-- Populated by application logic after each grading period closes.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS period_grade_summaries (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id           UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id          UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  class_id            UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id          UUID NOT NULL REFERENCES subjects(id),
  academic_period_id  UUID NOT NULL REFERENCES academic_periods(id),
  final_score         NUMERIC(5,2),
  attendance_rate     NUMERIC(5,2),                -- percentage 0-100
  passed              BOOLEAN,
  computed_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(student_id, class_id, subject_id, academic_period_id)
);

CREATE INDEX IF NOT EXISTS idx_period_grade_summaries_student ON period_grade_summaries(student_id, academic_period_id);
CREATE INDEX IF NOT EXISTS idx_period_grade_summaries_class ON period_grade_summaries(class_id, academic_period_id);

-- ──────────────────────────────────────────────────────────────
-- Helper function: update updated_at automatically
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables with updated_at that are missing it
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['events', 'assignments'] LOOP
    EXECUTE format(
      'CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION set_updated_at()', tbl
    );
  END LOOP;
EXCEPTION WHEN duplicate_object THEN NULL;
END;
$$;
