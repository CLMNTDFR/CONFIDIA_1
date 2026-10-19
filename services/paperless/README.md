# Paperless-ngx Integration

Paperless-ngx is deployed via Docker Compose (`docker/docker-compose.yml`).

## Configuration

- **URL**: http://localhost:8001
- **Admin**: admin / admin

## API Token

After first startup, generate an API token in Paperless admin panel and set `PAPERLESS_TOKEN` in your environment.

## Backend Integration

The FastAPI backend can talk to Paperless through `infrastructure/paperless/paperless_client.py`.

The Holberton Documents screen does not use it. That path stores the file on the API disk (`var/documents`) and the metadata in PostgreSQL. Flutter never accesses Paperless directly.
