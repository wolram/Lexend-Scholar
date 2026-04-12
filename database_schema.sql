-- ============================================================
-- Lexend Scholar — PostgreSQL/Supabase Database Schema
-- ============================================================

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE plan_type AS ENUM ('starter', 'pro', 'enterprise');
CREATE TYPE subscription_status AS ENUM ('trialing', 'active', 'past_due', 'canceled', 'unpaid');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed', 'refunded');
CREATE TYPE invoice_status AS ENUM ('draft', 'open', 'paid', 'void', 'uncollectible');
CREATE TYPE attendance_status AS ENUM ('present', 'absent', 'late', 'excused');
CREATE TYPE gender_type AS ENUM ('M', 'F', 'other');
CREATE TYPE role_type AS ENUM ('admin', 'teacher', 'secretary', 'guardian', 'student');

-- ============================================================
-- SCHOOLS (tenants)
-- ============================================================

CREATE TABLE schools (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                   TEXT NOT NULL,
  cnpj                   TEXT UNIQUE,
  email                  TEXT NOT NULL UNIQUE,
  phone                  TEXT,
  address                TEXT,
  city                   TEXT,
  state                  CHAR(2),
  zip_code               TEXT,
  plan                   plan_type NOT NULL DEFAULT 'starter',
  max_students           INTEGER NOT NULL DEFAULT 100,
  -- Stripe integration
  stripe_customer_id     TEXT UNIQUE,
  stripe_subscription_id TEXT UNIQUE,
  stripe_price_id        TEXT,
  subscription_status    subscription_status NOT NULL DEFAULT 'trialing',
  trial_ends_at          TIMESTAMPTZ,
  current_period_start   TIMESTAMPTZ,
  current_period_end     TIMESTAMPTZ,
  -- Metadata
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- USERS
-- ============================================================

CREATE TABLE users (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id    UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  email        TEXT NOT NULL UNIQUE,
  full_name    TEXT NOT NULL,
  role         role_type NOT NULL DEFAULT 'teacher',
  avatar_url   TEXT,
  fcm_token    TEXT,                    -- Firebase Cloud Messaging token
  active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- ACADEMIC PERIODS
-- ============================================================

CREATE TABLE academic_years (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,            -- e.g. "2025"
  start_date  DATE NOT NULL,
  end_date    DATE NOT NULL,
  active      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE academic_periods (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id        UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,       -- e.g. "1º Bimestre"
  start_date       DATE NOT NULL,
  end_date         DATE NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- GRADES & CLASSES
-- ============================================================

CREATE TABLE grades (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,            -- e.g. "1º Ano EM"
  level       TEXT,                     -- "fundamental", "medio"
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE classes (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id        UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  grade_id         UUID NOT NULL REFERENCES grades(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,       -- e.g. "10A", "10B"
  teacher_id       UUID REFERENCES users(id),
  max_students     INTEGER NOT NULL DEFAULT 40,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STUDENTS
-- ============================================================

CREATE TABLE students (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  enrollment_code TEXT NOT NULL,
  full_name       TEXT NOT NULL,
  birth_date      DATE,
  gender          gender_type,
  cpf             TEXT,
  email           TEXT,
  phone           TEXT,
  address         TEXT,
  city            TEXT,
  state           CHAR(2),
  zip_code        TEXT,
  photo_url       TEXT,
  active          BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(school_id, enrollment_code)
);

CREATE TABLE student_class_enrollments (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  class_id   UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  enrolled_at DATE NOT NULL DEFAULT CURRENT_DATE,
  left_at     DATE,
  active      BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE(student_id, class_id)
);

-- ============================================================
-- GUARDIANS
-- ============================================================

CREATE TABLE guardians (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id  UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  full_name  TEXT NOT NULL,
  cpf        TEXT,
  email      TEXT,
  phone      TEXT,
  relation   TEXT,                      -- "pai", "mãe", "responsável"
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE student_guardians (
  student_id  UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  guardian_id UUID NOT NULL REFERENCES guardians(id) ON DELETE CASCADE,
  PRIMARY KEY (student_id, guardian_id)
);

-- ============================================================
-- SUBJECTS & TEACHERS
-- ============================================================

CREATE TABLE subjects (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id  UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  code       TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE class_subjects (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id   UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES users(id),
  weekly_hours INTEGER NOT NULL DEFAULT 2,
  UNIQUE(class_id, subject_id)
);

-- ============================================================
-- ATTENDANCE
-- ============================================================

CREATE TABLE attendance_records (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id        UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  class_id         UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id       UUID NOT NULL REFERENCES subjects(id),
  student_id       UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  date             DATE NOT NULL,
  status           attendance_status NOT NULL DEFAULT 'present',
  notes            TEXT,
  recorded_by      UUID REFERENCES users(id),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(class_id, subject_id, student_id, date)
);

-- ============================================================
-- GRADES / NOTAS
-- ============================================================

CREATE TABLE grade_records (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id        UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id       UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  class_id         UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id       UUID NOT NULL REFERENCES subjects(id),
  academic_period_id UUID NOT NULL REFERENCES academic_periods(id),
  score            NUMERIC(5,2),
  max_score        NUMERIC(5,2) NOT NULL DEFAULT 10.00,
  grade_type       TEXT NOT NULL DEFAULT 'prova',  -- prova, trabalho, participacao
  description      TEXT,
  recorded_by      UUID REFERENCES users(id),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- FINANCIAL — MENSALIDADES
-- ============================================================

CREATE TABLE financial_records (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id      UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  description     TEXT NOT NULL,       -- "Mensalidade Maio/2025"
  amount          NUMERIC(10,2) NOT NULL,
  due_date        DATE NOT NULL,
  paid_date       DATE,
  payment_method  TEXT,                -- "boleto", "pix", "cartao"
  payment_status  payment_status NOT NULL DEFAULT 'pending',
  days_overdue    INTEGER GENERATED ALWAYS AS (
                    CASE WHEN paid_date IS NULL AND due_date < CURRENT_DATE
                    THEN (CURRENT_DATE - due_date) ELSE 0 END
                  ) STORED,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STRIPE — INVOICES / RECEIPTS (SaaS billing)
-- ============================================================

CREATE TABLE billing_invoices (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  stripe_invoice_id     TEXT UNIQUE,
  stripe_payment_intent TEXT,
  amount_due            INTEGER NOT NULL,  -- in centavos
  amount_paid           INTEGER NOT NULL DEFAULT 0,
  currency              CHAR(3) NOT NULL DEFAULT 'brl',
  status                invoice_status NOT NULL DEFAULT 'draft',
  invoice_url           TEXT,             -- Stripe hosted invoice URL
  invoice_pdf           TEXT,             -- Stripe PDF URL
  period_start          TIMESTAMPTZ,
  period_end            TIMESTAMPTZ,
  paid_at               TIMESTAMPTZ,
  due_date              DATE,
  description           TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STRIPE WEBHOOK EVENTS (idempotency log)
-- ============================================================

CREATE TABLE stripe_webhook_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id    TEXT NOT NULL UNIQUE,     -- Stripe event ID (evt_xxx)
  event_type  TEXT NOT NULL,
  payload     JSONB NOT NULL,
  processed   BOOLEAN NOT NULL DEFAULT FALSE,
  error       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PUSH NOTIFICATIONS LOG
-- ============================================================

CREATE TABLE push_notification_log (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id    UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  user_id      UUID REFERENCES users(id),
  title        TEXT NOT NULL,
  body         TEXT NOT NULL,
  data         JSONB,
  fcm_message_id TEXT,
  sent_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  error        TEXT
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_students_school ON students(school_id);
CREATE INDEX idx_students_active ON students(school_id, active);
CREATE INDEX idx_attendance_class_date ON attendance_records(class_id, date);
CREATE INDEX idx_attendance_student ON attendance_records(student_id);
CREATE INDEX idx_grade_records_student ON grade_records(student_id, subject_id, academic_period_id);
CREATE INDEX idx_financial_school_status ON financial_records(school_id, payment_status);
CREATE INDEX idx_financial_student ON financial_records(student_id);
CREATE INDEX idx_financial_due_date ON financial_records(school_id, due_date);
CREATE INDEX idx_billing_school ON billing_invoices(school_id);
CREATE INDEX idx_stripe_events_type ON stripe_webhook_events(event_type, processed);
CREATE INDEX idx_users_school ON users(school_id);
CREATE INDEX idx_class_enrollments_student ON student_class_enrollments(student_id);
CREATE INDEX idx_class_enrollments_class ON student_class_enrollments(class_id);
