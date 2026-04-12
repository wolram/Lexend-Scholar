-- ============================================================
-- LS-78 — Migration 001: Add missing tables to school schema
-- Run order: after initial schema (database_schema.sql)
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- OCORRÊNCIAS — registro de ocorrências disciplinares/administrativas
-- Campos em PT-BR conforme spec LS-78 + LS-73
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS occurrences (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id        UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id       UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  class_id         UUID REFERENCES classes(id),
  reported_by      UUID NOT NULL REFERENCES users(id),
  tipo             TEXT NOT NULL DEFAULT 'outro',
    CONSTRAINT chk_occurrences_tipo CHECK (
      tipo IN ('disciplinar','elogio','saude','outro','administrativo','academico')
    ),
  severity         TEXT NOT NULL DEFAULT 'low',
    CONSTRAINT chk_occurrences_severity CHECK (severity IN ('low','medium','high')),
  descricao        TEXT NOT NULL,
  data             DATE NOT NULL DEFAULT CURRENT_DATE,
  resolved         BOOLEAN NOT NULL DEFAULT FALSE,
  resolved_at      TIMESTAMPTZ,
  resolved_by      UUID REFERENCES users(id),
  resolution_notes TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_occurrences_school   ON occurrences(school_id, data DESC);
CREATE INDEX IF NOT EXISTS idx_occurrences_student  ON occurrences(student_id, data DESC);
CREATE INDEX IF NOT EXISTS idx_occurrences_reporter ON occurrences(reported_by);
CREATE INDEX IF NOT EXISTS idx_occurrences_resolved ON occurrences(school_id, resolved, data DESC);

-- RLS para occurrences
ALTER TABLE occurrences ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "occurrences_school_isolation"
  ON occurrences
  USING (school_id = (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid);

CREATE POLICY IF NOT EXISTS "occurrences_insert_school"
  ON occurrences FOR INSERT
  WITH CHECK (school_id = (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid);

-- ──────────────────────────────────────────────────────────────
-- COMUNICADOS — avisos e comunicados para turmas ou escola toda
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS comunicados (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  turma_id    UUID REFERENCES classes(id),   -- NULL = comunicado escola toda
  titulo      TEXT NOT NULL,
  conteudo    TEXT NOT NULL,
  autor_id    UUID NOT NULL REFERENCES users(id),
  fixado      BOOLEAN NOT NULL DEFAULT FALSE,
  publicado   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comunicados_school ON comunicados(school_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comunicados_turma  ON comunicados(turma_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comunicados_autor  ON comunicados(autor_id);

ALTER TABLE comunicados ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "comunicados_school_isolation"
  ON comunicados
  USING (school_id = (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid);

CREATE POLICY IF NOT EXISTS "comunicados_insert_school"
  ON comunicados FOR INSERT
  WITH CHECK (school_id = (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid);

-- ──────────────────────────────────────────────────────────────
-- MENSAGENS — mensagens internas entre usuários da escola
-- (complementa a tabela messages já existente com campos PT-BR)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS mensagens (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id     UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  de_user_id    UUID NOT NULL REFERENCES users(id),
  para_user_id  UUID NOT NULL REFERENCES users(id),
  assunto       TEXT,
  corpo         TEXT NOT NULL,
  lida          BOOLEAN NOT NULL DEFAULT FALSE,
  lida_em       TIMESTAMPTZ,
  arquivada     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mensagens_destinatario ON mensagens(para_user_id, lida, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mensagens_remetente     ON mensagens(de_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mensagens_school        ON mensagens(school_id, created_at DESC);

ALTER TABLE mensagens ENABLE ROW LEVEL SECURITY;

-- Usuário vê suas mensagens enviadas ou recebidas dentro da escola
CREATE POLICY IF NOT EXISTS "mensagens_school_isolation"
  ON mensagens
  USING (
    school_id = (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid
    AND (
      de_user_id   = auth.uid()
      OR para_user_id = auth.uid()
      OR (auth.jwt() -> 'app_metadata' ->> 'role') IN ('admin','secretary')
    )
  );

CREATE POLICY IF NOT EXISTS "mensagens_insert_school"
  ON mensagens FOR INSERT
  WITH CHECK (
    school_id  = (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid
    AND de_user_id = auth.uid()
  );

-- ──────────────────────────────────────────────────────────────
-- EVENTOS ESCOLARES — calendário de eventos da escola
-- (complementa a tabela events com campos PT-BR e campos extras)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS eventos_escolares (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  titulo      TEXT NOT NULL,
  descricao   TEXT,
  tipo        TEXT NOT NULL DEFAULT 'geral',
    CONSTRAINT chk_eventos_tipo CHECK (
      tipo IN ('geral','feriado','prova','reuniao','atividade','excursao','formatura')
    ),
  data_inicio TIMESTAMPTZ NOT NULL,
  data_fim    TIMESTAMPTZ NOT NULL,
  dia_inteiro BOOLEAN NOT NULL DEFAULT FALSE,
  local       TEXT,
  turma_ids   UUID[],          -- NULL = evento escola toda
  criado_por  UUID REFERENCES users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT chk_eventos_datas CHECK (data_fim >= data_inicio)
);

CREATE INDEX IF NOT EXISTS idx_eventos_school_data ON eventos_escolares(school_id, data_inicio);
CREATE INDEX IF NOT EXISTS idx_eventos_tipo        ON eventos_escolares(school_id, tipo, data_inicio);

ALTER TABLE eventos_escolares ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "eventos_school_isolation"
  ON eventos_escolares
  USING (school_id = (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid);

CREATE POLICY IF NOT EXISTS "eventos_insert_school"
  ON eventos_escolares FOR INSERT
  WITH CHECK (school_id = (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid);

-- ──────────────────────────────────────────────────────────────
-- DOCUMENTOS ALUNO — metadados de documentos no Supabase Storage
-- (complementa student_documents com campos PT-BR e tipo normalizado)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS documentos_aluno (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id    UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  aluno_id     UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  tipo         TEXT NOT NULL DEFAULT 'geral',
    CONSTRAINT chk_documentos_tipo CHECK (
      tipo IN ('rg','cpf','certidao','comprovante','laudo','historico','declaracao','foto','geral')
    ),
  nome_arquivo TEXT NOT NULL,
  url_storage  TEXT NOT NULL,
  mime_type    TEXT,
  tamanho_bytes INTEGER,
  uploaded_by  UUID NOT NULL REFERENCES users(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_documentos_aluno_school  ON documentos_aluno(school_id);
CREATE INDEX IF NOT EXISTS idx_documentos_aluno_student ON documentos_aluno(aluno_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_documentos_aluno_tipo    ON documentos_aluno(aluno_id, tipo);

ALTER TABLE documentos_aluno ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "documentos_aluno_school_isolation"
  ON documentos_aluno
  USING (school_id = (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid);

CREATE POLICY IF NOT EXISTS "documentos_aluno_insert_school"
  ON documentos_aluno FOR INSERT
  WITH CHECK (
    school_id = (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid
    AND (auth.jwt() -> 'app_metadata' ->> 'role') IN ('admin','secretary')
  );

-- ──────────────────────────────────────────────────────────────
-- Trigger updated_at para novas tabelas
-- ──────────────────────────────────────────────────────────────
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['occurrences','comunicados','eventos_escolares'] LOOP
    BEGIN
      EXECUTE format(
        'CREATE TRIGGER trg_%I_updated_at BEFORE UPDATE ON %I
         FOR EACH ROW EXECUTE FUNCTION set_updated_at()', tbl, tbl
      );
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
  END LOOP;
END;
$$;

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
