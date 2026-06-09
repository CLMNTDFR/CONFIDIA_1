# Nextcloud Integration

Nextcloud is deployed via Docker Compose (`docker/docker-compose.yml`).

## Configuration

- **URL**: http://localhost:8081
- **Admin**: admin / admin

## Backend Integration

The FastAPI backend communicates with Nextcloud through WebDAV via `infrastructure/nextcloud/nextcloud_client.py`.

The `StorageProvider` abstraction allows replacing Nextcloud with another storage backend in the future.
