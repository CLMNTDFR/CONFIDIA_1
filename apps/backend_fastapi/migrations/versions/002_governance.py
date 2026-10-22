"""Workspace chart fields and invitations.

Revision ID: 002_governance
Revises: 001_mvp_schema
Create Date: 2026-10-19
"""

from alembic import op

revision = "002_governance"
down_revision = "001_mvp_schema"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        """
        ALTER TABLE organizations
          ADD COLUMN IF NOT EXISTS icon TEXT NOT NULL DEFAULT 'family'
        """
    )
    op.execute(
        """
        ALTER TABLE organizations
          ADD COLUMN IF NOT EXISTS level_labels JSONB NOT NULL DEFAULT '{}'::jsonb
        """
    )
    op.execute(
        """
        ALTER TABLE memberships
          ADD COLUMN IF NOT EXISTS parent_id UUID
        """
    )
    op.execute(
        """
        DO $$ BEGIN
          ALTER TABLE memberships
            ADD CONSTRAINT memberships_parent_id_fkey
            FOREIGN KEY (parent_id) REFERENCES memberships (id) ON DELETE SET NULL;
        EXCEPTION WHEN duplicate_object THEN NULL;
        END $$
        """
    )
    op.execute(
        """
        ALTER TABLE memberships
          ADD COLUMN IF NOT EXISTS permissions TEXT[] NOT NULL DEFAULT '{}'
        """
    )
    op.execute(
        """
        ALTER TABLE memberships
          ADD COLUMN IF NOT EXISTS link_type TEXT NOT NULL DEFAULT 'reportsTo'
        """
    )
    op.execute(
        """
        DO $$ BEGIN
          ALTER TABLE memberships
            ADD CONSTRAINT memberships_link_type_chk
            CHECK (link_type IN ('reportsTo', 'dottedLine', 'delegate'));
        EXCEPTION WHEN duplicate_object THEN NULL;
        END $$
        """
    )
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS invitations (
          id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          organization_id  UUID NOT NULL REFERENCES organizations (id),
          inviter_id       TEXT NOT NULL REFERENCES users (id),
          invitee_id       TEXT NOT NULL REFERENCES users (id),
          status           TEXT NOT NULL DEFAULT 'pending'
                             CHECK (status IN ('pending', 'accepted', 'refused', 'cancelled')),
          created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
          updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
          UNIQUE (organization_id, invitee_id)
        )
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS invitations_invitee_idx ON invitations (invitee_id)
        """
    )
    op.execute("DROP TRIGGER IF EXISTS invitations_set_updated_at ON invitations")
    op.execute(
        """
        CREATE TRIGGER invitations_set_updated_at
          BEFORE UPDATE ON invitations
          FOR EACH ROW EXECUTE PROCEDURE set_updated_at()
        """
    )


def downgrade() -> None:
    op.execute("DROP TRIGGER IF EXISTS invitations_set_updated_at ON invitations")
    op.execute("DROP TABLE IF EXISTS invitations")
    op.execute(
        """
        ALTER TABLE memberships DROP CONSTRAINT IF EXISTS memberships_link_type_chk
        """
    )
    op.execute(
        """
        ALTER TABLE memberships DROP CONSTRAINT IF EXISTS memberships_parent_id_fkey
        """
    )
    op.execute("ALTER TABLE memberships DROP COLUMN IF EXISTS link_type")
    op.execute("ALTER TABLE memberships DROP COLUMN IF EXISTS permissions")
    op.execute("ALTER TABLE memberships DROP COLUMN IF EXISTS parent_id")
    op.execute("ALTER TABLE organizations DROP COLUMN IF EXISTS level_labels")
    op.execute("ALTER TABLE organizations DROP COLUMN IF EXISTS icon")
