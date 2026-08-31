def to_sync_url(database_url: str) -> str:
    """Alembic runs synchronously; the app uses asyncpg."""
    return database_url.replace("postgresql+asyncpg://", "postgresql+psycopg://", 1)
