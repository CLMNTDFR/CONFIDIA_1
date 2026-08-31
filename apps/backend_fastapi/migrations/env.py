"""Alembic environment. URL comes from DATABASE_URL (asyncpg → psycopg)."""

from logging.config import fileConfig

from alembic import context
from sqlalchemy import create_engine, pool

from core.config import get_settings
from infrastructure.db.urls import to_sync_url

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = None
database_url = to_sync_url(get_settings().database_url)
config.set_main_option("sqlalchemy.url", database_url)


def run_migrations_offline() -> None:
    context.configure(
        url=database_url,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = create_engine(database_url, poolclass=pool.NullPool)
    with connectable.connect() as connection:
        context.configure(connection=connection)
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
