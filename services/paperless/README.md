# Paperless-ngx Integration

Paperless-ngx is deployed via Docker Compose (`docker/docker-compose.yml`).

## Configuration

- **URL**: http://localhost:8001
- **Admin**: admin / admin

## API Token

After first startup, generate an API token in Paperless admin panel and set `PAPERLESS_TOKEN` in your environment.

## Backend Integration

The FastAPI backend communicates with Paperless through `infrastructure/paperless/paperless_client.py`.

Flutter never accesses Paperless directly.
