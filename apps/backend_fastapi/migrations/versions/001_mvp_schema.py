"""Apply CONFIDIA MVP PostgreSQL schema.

Revision ID: 001_mvp_schema
Revises:
Create Date: 2026-08-31
"""

from pathlib import Path

from alembic import op

revision = "001_mvp_schema"
down_revision = None
branch_labels = None
depends_on = None

_SQL_FILE = Path(__file__).resolve().parents[2] / "infrastructure" / "db" / "sql" / "schema_mvp.sql"


def upgrade() -> None:
    sql = _SQL_FILE.read_text(encoding="utf-8")
    op.get_bind().exec_driver_sql(sql)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS notifications CASCADE")
    op.execute("DROP TABLE IF EXISTS reminders CASCADE")
    op.execute("DROP TABLE IF EXISTS calendar_events CASCADE")
    op.execute("DROP TABLE IF EXISTS calendars CASCADE")
    op.execute("DROP TABLE IF EXISTS document_tags CASCADE")
    op.execute("DROP TABLE IF EXISTS tags CASCADE")
    op.execute("DROP TABLE IF EXISTS documents CASCADE")
    op.execute("DROP TABLE IF EXISTS memberships CASCADE")
    op.execute("DROP TABLE IF EXISTS users CASCADE")
    op.execute("DROP TABLE IF EXISTS organizations CASCADE")
    op.execute("DROP FUNCTION IF EXISTS set_updated_at() CASCADE")
