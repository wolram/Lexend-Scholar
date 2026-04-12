-- ============================================================
-- LS-79 — Migration 003: Tabela de comunicados por turma/escola
-- Run order: after 002-soft-delete-indexes.sql
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- ANNOUNCEMENTS — comunicados enviados por professores/equipe
-- class_id NULL = comunicado para toda a escola
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS announcements (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  class_id    UUID REFERENCES classes(id) ON DELETE SET NULL,  -- NULL = escola toda
  titulo      TEXT NOT NULL,
  conteudo    TEXT NOT NULL,
  fixado      BOOLEAN NOT NULL DEFAULT FALSE,
  created_by  UUID NOT NULL REFERENCES users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at  TIMESTAMPTZ DEFAULT NULL
);

-- Índices de performance
CREATE INDEX IF NOT EXISTS idx_announcements_school
  ON announcements(school_id, created_at DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_announcements_class
  ON announcements(class_id, created_at DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_announcements_fixado
  ON announcements(school_id, fixado, created_at DESC)
  WHERE deleted_at IS NULL;

-- Trigger updated_at
DO $$
BEGIN
  CREATE TRIGGER trg_announcements_updated_at
    BEFORE UPDATE ON announcements
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL;
END;
$$;

-- RLS
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  CREATE POLICY announcements_school_isolation ON announcements
    FOR ALL TO authenticated
    USING (school_id = (auth.jwt() ->> 'school_id')::UUID);
EXCEPTION WHEN duplicate_object THEN NULL;
END;
$$;
