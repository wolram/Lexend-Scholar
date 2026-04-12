-- ============================================================
-- LS-82 — Migration 004: Tabela event_rsvp para confirmações de presença
-- Run order: after 003-comunicados-events.sql
-- A tabela events já existe (criada em 001-add-missing-tables.sql).
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- EVENT_RSVP — confirmações de presença por usuário por evento
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS event_rsvp (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id   UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id  UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  status     TEXT NOT NULL DEFAULT 'confirmado'
               CHECK (status IN ('confirmado', 'recusado', 'talvez')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (event_id, user_id)
);

-- Índices de performance
CREATE INDEX IF NOT EXISTS idx_event_rsvp_event
  ON event_rsvp(event_id, status);

CREATE INDEX IF NOT EXISTS idx_event_rsvp_user
  ON event_rsvp(user_id, event_id);

CREATE INDEX IF NOT EXISTS idx_event_rsvp_school
  ON event_rsvp(school_id, event_id);

-- Trigger updated_at
DO $$
BEGIN
  CREATE TRIGGER trg_event_rsvp_updated_at
    BEFORE UPDATE ON event_rsvp
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL;
END;
$$;

-- RLS
ALTER TABLE event_rsvp ENABLE ROW LEVEL SECURITY;

-- Qualquer usuário autenticado da escola pode ver RSVPs de eventos da sua escola
DO $$
BEGIN
  CREATE POLICY event_rsvp_school_isolation ON event_rsvp
    FOR ALL TO authenticated
    USING (school_id = (auth.jwt() ->> 'school_id')::UUID);
EXCEPTION WHEN duplicate_object THEN NULL;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- Adicionar coluna deleted_at em events (soft delete)
-- ──────────────────────────────────────────────────────────────
ALTER TABLE events
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_events_active
  ON events(school_id, start_date)
  WHERE deleted_at IS NULL;
