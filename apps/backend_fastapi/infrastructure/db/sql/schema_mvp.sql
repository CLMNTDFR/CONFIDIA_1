-- CONFIDIA MVP schema (PostgreSQL 15+)
-- Holberton 4-week delivery. Apply on database `confidia`.
-- Later domains (mail, payments, org chart, AI, signatures) are documented
-- in docs/pitch-holberton/SQL_SCHEMA_MVP.md and must not be created here.

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Identity & tenant
-- ---------------------------------------------------------------------------

CREATE TABLE organizations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  slug        TEXT NOT NULL,
  kind        TEXT NOT NULL DEFAULT 'family'
                CHECK (kind IN ('personal', 'family', 'club', 'org')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at  TIMESTAMPTZ
);

CREATE UNIQUE INDEX organizations_slug_alive_idx
  ON organizations (slug)
  WHERE deleted_at IS NULL;

CREATE TABLE users (
  id          TEXT PRIMARY KEY, -- Keycloak `sub`
  email       CITEXT NOT NULL,
  first_name  TEXT NOT NULL DEFAULT '',
  last_name   TEXT NOT NULL DEFAULT '',
  phone       TEXT,
  avatar_url  TEXT,
  locale      TEXT NOT NULL DEFAULT 'fr-FR',
  timezone    TEXT NOT NULL DEFAULT 'Europe/Paris',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at  TIMESTAMPTZ
);

CREATE UNIQUE INDEX users_email_alive_idx
  ON users (email)
  WHERE deleted_at IS NULL;

CREATE TABLE memberships (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id  UUID NOT NULL REFERENCES organizations (id),
  user_id          TEXT NOT NULL REFERENCES users (id),
  role             TEXT NOT NULL DEFAULT 'member'
                     CHECK (role IN ('owner', 'admin', 'member')),
  is_default       BOOLEAN NOT NULL DEFAULT false,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at       TIMESTAMPTZ,
  UNIQUE (organization_id, user_id)
);

CREATE INDEX memberships_user_idx ON memberships (user_id)
  WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- Documents
-- ---------------------------------------------------------------------------

CREATE TABLE documents (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id  UUID NOT NULL REFERENCES organizations (id),
  owner_id         TEXT NOT NULL REFERENCES users (id),
  title            TEXT NOT NULL,
  content          TEXT,
  correspondent    TEXT,
  document_type    TEXT,
  category         TEXT,
  mime_type        TEXT,
  file_size        INTEGER CHECK (file_size IS NULL OR file_size >= 0),
  is_important     BOOLEAN NOT NULL DEFAULT false,
  paperless_id     INTEGER,
  storage_path     TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at       TIMESTAMPTZ,
  created_by       TEXT REFERENCES users (id)
);

CREATE UNIQUE INDEX documents_paperless_id_idx
  ON documents (paperless_id)
  WHERE paperless_id IS NOT NULL AND deleted_at IS NULL;

CREATE INDEX documents_org_created_idx
  ON documents (organization_id, created_at DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX documents_owner_idx
  ON documents (owner_id)
  WHERE deleted_at IS NULL;

CREATE TABLE tags (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id  UUID NOT NULL REFERENCES organizations (id),
  name             TEXT NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, name)
);

CREATE TABLE document_tags (
  document_id  UUID NOT NULL REFERENCES documents (id) ON DELETE CASCADE,
  tag_id       UUID NOT NULL REFERENCES tags (id) ON DELETE CASCADE,
  PRIMARY KEY (document_id, tag_id)
);

-- ---------------------------------------------------------------------------
-- Calendar (merged in-app agenda, no third-party sync in MVP)
-- ---------------------------------------------------------------------------

CREATE TABLE calendars (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id  UUID NOT NULL REFERENCES organizations (id),
  name             TEXT NOT NULL,
  slug             TEXT NOT NULL,
  color            TEXT,
  is_default       BOOLEAN NOT NULL DEFAULT false,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at       TIMESTAMPTZ,
  UNIQUE (organization_id, slug)
);

CREATE TABLE calendar_events (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  calendar_id      UUID NOT NULL REFERENCES calendars (id),
  organization_id  UUID NOT NULL REFERENCES organizations (id),
  title            TEXT NOT NULL,
  description      TEXT,
  location         TEXT,
  starts_at        TIMESTAMPTZ NOT NULL,
  ends_at          TIMESTAMPTZ NOT NULL,
  all_day          BOOLEAN NOT NULL DEFAULT false,
  event_type       TEXT NOT NULL DEFAULT 'reminder'
                     CHECK (event_type IN ('deadline', 'meeting', 'reminder', 'appointment')),
  color            TEXT,
  document_id      UUID REFERENCES documents (id),
  -- Future providers allowed so the UI mock can persist later without a CHECK rewrite.
  source           TEXT NOT NULL DEFAULT 'confidia'
                     CHECK (source IN ('confidia', 'google', 'outlook', 'apple', 'microsoft365')),
  week_scope       TEXT CHECK (week_scope IS NULL OR week_scope IN ('personal', 'family', 'professional')),
  -- Reserved UUID columns: add FKs when payments / emails tables exist.
  payment_id       UUID,
  email_id         UUID,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at       TIMESTAMPTZ,
  created_by       TEXT REFERENCES users (id),
  CHECK (ends_at >= starts_at)
);

CREATE INDEX calendar_events_calendar_starts_idx
  ON calendar_events (calendar_id, starts_at)
  WHERE deleted_at IS NULL;

CREATE INDEX calendar_events_org_starts_idx
  ON calendar_events (organization_id, starts_at)
  WHERE deleted_at IS NULL;

CREATE INDEX calendar_events_document_idx
  ON calendar_events (document_id)
  WHERE document_id IS NOT NULL AND deleted_at IS NULL;

CREATE TABLE reminders (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id    UUID NOT NULL REFERENCES calendar_events (id) ON DELETE CASCADE,
  remind_at   TIMESTAMPTZ NOT NULL,
  channel     TEXT NOT NULL DEFAULT 'in_app'
                CHECK (channel IN ('in_app', 'push', 'email')),
  sent_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX reminders_due_idx
  ON reminders (remind_at)
  WHERE sent_at IS NULL;

-- ---------------------------------------------------------------------------
-- Notifications
-- ---------------------------------------------------------------------------

CREATE TABLE notifications (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id     UUID NOT NULL REFERENCES organizations (id),
  user_id             TEXT NOT NULL REFERENCES users (id),
  title               TEXT NOT NULL,
  message             TEXT NOT NULL,
  notification_type   TEXT NOT NULL DEFAULT 'info'
                        CHECK (notification_type IN (
                          'info', 'warning', 'success', 'error',
                          'document', 'calendar', 'system'
                        )),
  read_at             TIMESTAMPTZ,
  action_url          TEXT,
  metadata            JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at          TIMESTAMPTZ
);

CREATE INDEX notifications_user_created_idx
  ON notifications (user_id, created_at DESC)
  WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- updated_at triggers
-- ---------------------------------------------------------------------------

CREATE TRIGGER organizations_set_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

CREATE TRIGGER users_set_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

CREATE TRIGGER memberships_set_updated_at
  BEFORE UPDATE ON memberships
  FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

CREATE TRIGGER documents_set_updated_at
  BEFORE UPDATE ON documents
  FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

CREATE TRIGGER calendars_set_updated_at
  BEFORE UPDATE ON calendars
  FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

CREATE TRIGGER calendar_events_set_updated_at
  BEFORE UPDATE ON calendar_events
  FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

-- ---------------------------------------------------------------------------
-- Not in MVP (do not CREATE):
--   roles, permissions, role_permissions, org_nodes, sharing_requests
--   mailboxes, emails, email_attachments
--   calendar_sources
--   payments
--   signatures
--   ai_analyses, ai_conversations
--   categories, document_versions
--   audit_logs
-- ---------------------------------------------------------------------------
