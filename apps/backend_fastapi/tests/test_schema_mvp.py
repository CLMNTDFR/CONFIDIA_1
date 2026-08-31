"""SQL MVP contract: required tables, no backlog tables, Alembic + docs stay aligned."""

from __future__ import annotations

import re
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = BACKEND_ROOT.parents[1]

BACKEND_SQL = BACKEND_ROOT / "infrastructure" / "db" / "sql" / "schema_mvp.sql"
DOCS_SQL = REPO_ROOT / "docs" / "pitch-holberton" / "schema_mvp.sql"
MIGRATION = BACKEND_ROOT / "migrations" / "versions" / "001_mvp_schema.py"

REQUIRED_TABLES = {
    "organizations",
    "users",
    "memberships",
    "documents",
    "tags",
    "document_tags",
    "calendars",
    "calendar_events",
    "reminders",
    "notifications",
}

BACKLOG_TABLES = {
    "payments",
    "mailboxes",
    "emails",
    "email_attachments",
    "signatures",
    "org_nodes",
    "ai_analyses",
    "ai_conversations",
    "calendar_sources",
    "roles",
    "permissions",
}


def _create_tables(sql: str) -> set[str]:
    return {name.lower() for name in re.findall(r"CREATE TABLE\s+(\w+)", sql, flags=re.I)}


def test_backend_schema_file_exists():
    assert BACKEND_SQL.is_file()
    assert DOCS_SQL.is_file()
    assert MIGRATION.is_file()


def test_alembic_revision_applies_schema_sql():
    text = MIGRATION.read_text(encoding="utf-8")
    assert 'revision = "001_mvp_schema"' in text
    assert "schema_mvp.sql" in text
    assert "op.get_bind().exec_driver_sql" in text


def test_mvp_tables_present_and_backlog_absent():
    sql = BACKEND_SQL.read_text(encoding="utf-8")
    created = _create_tables(sql)
    assert REQUIRED_TABLES == created
    assert created.isdisjoint(BACKLOG_TABLES)


def test_docs_sql_matches_backend_table_list():
    backend = _create_tables(BACKEND_SQL.read_text(encoding="utf-8"))
    docs = _create_tables(DOCS_SQL.read_text(encoding="utf-8"))
    assert backend == docs


def test_users_pk_is_keycloak_sub_text():
    sql = BACKEND_SQL.read_text(encoding="utf-8")
    assert re.search(r"CREATE TABLE users\s*\(", sql, flags=re.I)
    assert re.search(r"id\s+TEXT PRIMARY KEY", sql)
    assert "Keycloak" in sql


def test_membership_and_calendar_constraints():
    sql = BACKEND_SQL.read_text(encoding="utf-8")
    assert "CHECK (role IN ('owner', 'admin', 'member'))" in sql
    assert "CHECK (source IN ('confidia', 'google', 'outlook', 'apple', 'microsoft365'))" in sql
    assert "payment_id       UUID" in sql
    assert "email_id         UUID" in sql
    assert "REFERENCES payments" not in sql
    assert "REFERENCES emails" not in sql


def test_to_sync_url_rewrites_asyncpg_for_alembic():
    from infrastructure.db.urls import to_sync_url

    async_url = "postgresql+asyncpg://confidia:secret@localhost:5432/confidia"
    assert to_sync_url(async_url) == "postgresql+psycopg://confidia:secret@localhost:5432/confidia"
    already = "postgresql+psycopg://confidia:secret@localhost:5432/confidia"
    assert to_sync_url(already) == already
