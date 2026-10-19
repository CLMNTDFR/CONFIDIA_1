# CONFIDIA architecture

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter frontend                          │
│  Riverpod · GoRouter · Dio · design system                  │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS / REST  /api/v1
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI backend                           │
│  Layers · DTOs · guards · FastAPI Depends                   │
├──────────────────┬──────────────────┬───────────────────────┤
│  Keycloak        │  PostgreSQL 16   │  Local disk           │
│  OAuth2 / OIDC   │  metadata        │  var/documents        │
├──────────────────┴──────────────────┴───────────────────────┤
│  Optional, not the documents screen:                        │
│  Paperless-ngx · Nextcloud (WebDAV) · MockAIProvider        │
└─────────────────────────────────────────────────────────────┘
```

## Rule

The Flutter client never calls Keycloak, Paperless, or Nextcloud. Every request goes to the FastAPI API.

## Backend

```
apps/backend_fastapi/
├── api/                  # Routes and FastAPI dependencies
│   └── v1/
├── application/          # Use cases, services, DTOs
│   ├── dto/
│   └── services/
├── domain/               # Ports (ABC interfaces)
│   └── interfaces/
├── infrastructure/       # Adapters
│   ├── db/               # SQLAlchemy models and Postgres repositories
│   ├── keycloak/
│   ├── paperless/
│   ├── nextcloud/
│   └── ai/
├── core/                 # Settings, JWT, upload checks, DI container
└── migrations/           # Alembic
```

| Layer | Responsibility |
|-------|----------------|
| `api/` | REST endpoints, input validation, role guards |
| `application/` | Use cases, orchestration, Pydantic v2 DTOs |
| `domain/` | Abstract ports, no framework |
| `infrastructure/` | Keycloak, PostgreSQL, disk, Paperless, Nextcloud, mock AI |
| `core/` | Settings, security, dependency injection |

### Documents (Holberton path)

`/documents` uses `WorkspaceDocumentService` and `PostgresDocumentRepository` (`api/deps.py`, `api/v1/documents.py`).

- Metadata lives in PostgreSQL, scoped to the current organisation.
- File bytes live on local disk (`documents_storage_dir`, default `var/documents`).
- The port is `WorkspaceDocumentRepository`: list, get, read file, create, update, delete.

`PaperlessClient` still implements the older `DocumentRepository` port (list, get, upload, delete, search). If `PAPERLESS_TOKEN` is empty, that client returns mock rows. It is registered in `core/di.py` and is not what `/documents` calls.

### Nextcloud

`NextcloudStorageProvider` implements `StorageProvider` (upload, download, delete, list, share link). `api/v1/storage.py` builds it for `/storage`. The documents screen does not use it.

### AI

```python
class DocumentAIProvider(ABC):
    async def summarize(document_id, content) -> SummaryDTO
    async def classify(document_id, content) -> ClassificationDTO
    async def extract_dates(document_id, content) -> DateExtractionDTO
    async def extract_amounts(document_id, content) -> AmountExtractionDTO
```

`MockAIProvider` returns fixed sample data. `api/v1/ai.py` constructs that class directly. A real provider would implement the same port and replace that construction. The Flutter client would keep calling the API.

### Wiring

`core/di.py` is a `dependency_injector` container for `PaperlessClient`, `NextcloudStorageProvider`, and `MockAIProvider`.

Holberton routes (documents, calendar, profile) do not read that container. They use FastAPI `Depends` and PostgreSQL repositories. Storage and AI routes construct their adapters in the route module.

## Authentication

- Keycloak realm `confidia`, imported when Compose starts.
- Login uses the OAuth2 password grant. The API refreshes the token.
- Roles: `ADMIN`, `USER`, `MANAGER`.
- Backend guard: `require_roles(...)` in `core/security.py`.
- Flutter: `authStateProvider`. Tokens sit in `flutter_secure_storage`. A 401 triggers `/auth/refresh`, then the call is retried.

## Data

PostgreSQL 16 is the system of record (users, organisations, documents, calendar). Schema changes go through Alembic (`migrations/`).

## Frontend

### Theme

```
lib/core/theme/
├── theme.dart          # Dark and light ThemeData
├── palette.dart        # Blue and rose brand palettes
├── colors.dart         # Facade over surface tokens
├── spacing.dart
├── typography.dart     # Inter via Google Fonts
└── tokens/             # Spacing, radius, type, surfaces
```

Rose brand colors in `palette.dart`: `#d20050`, `#af73f7`, `#4b96b4`. Blue is the other palette (`#015AAB`, `#06E5EF`, `#3B9AE8`).

### Features

`lib/features/` has one folder per area: `auth`, `dashboard`, `documents`, `calendar`, `profile`, `notifications`, `settings`, `admin`, `access_control`, `day_start`, `messaging`, `onboarding`, `payments`, `serenity_feedback`.

`lib/shared/` holds models, widgets, and mock data. `lib/core/` holds the API client, auth, router, and theme.

Messaging and payments are demo screens. They are not the Holberton document path. A live account stores its organisation chart and invitations in PostgreSQL.

### API client (Dio)

- Base URL from `ApiConfig` (default `http://localhost:8000/api/v1` on web and desktop).
- Bearer token on each call.
- Refresh on 401.

## Technical choices

| Decision | Choice | Why |
|----------|--------|-----|
| Repository layout | Monorepo | One clone, one CI |
| Backend shape | Layered ports and adapters | Swap an adapter without rewriting routes |
| Document bytes | Local disk + Postgres metadata | The demo does not depend on Paperless |
| Paperless and Nextcloud | Present in Compose, off the documents screen | Optional integrations |
| App state | Riverpod | Not the classic `provider` package |
