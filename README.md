# <p align="center">CONFIDIA</p>
<p align="center">
  A secure digital hub for administrative documents, identity, calendar and daily actions.
</p>
<p align="center">
  <strong>Holberton Webstack</strong> portfolio · <strong>RNCP 37873</strong> Concepteur Développeur d'Applications (level 6)<br>
  Solo project · Clément Defer
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white" alt="Python 3.12">
  <img src="https://img.shields.io/badge/FastAPI-async-009688?logo=fastapi&logoColor=white" alt="FastAPI">
  <img src="https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white" alt="PostgreSQL 16">
  <img src="https://img.shields.io/badge/Keycloak-OIDC-4D4D4D?logo=keycloak&logoColor=white" alt="Keycloak">
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white" alt="Docker Compose">
</p>

---

## Table of contents

1. [Overview](#overview)
2. [Need analysis and scope](#need-analysis-and-scope)
3. [RNCP 6 competency mapping](#rncp-6-competency-mapping)
4. [Main features](#main-features)
5. [Technologies and tools](#technologies-and-tools)
6. [Architecture](#architecture)
7. [Data model](#data-model)
8. [Security](#security)
9. [User flow](#user-flow)
10. [Installation and configuration](#installation-and-configuration)
11. [Usage](#usage)
12. [Tests and CI](#tests-and-ci)
13. [Project management](#project-management)
14. [Repository structure](#repository-structure)
15. [Resources](#resources)
16. [Future features](#future-features)
17. [Contributing](#contributing)
18. [Author](#author)
19. [License](#license)

---

## Overview

Administrative life is split across email, cloud drives, paper scans and calendars. Deadlines are easy to miss. Documents are hard to find when they matter.

**CONFIDIA** is a single, calm place to act: sign in, keep a profile, open a dashboard, store documents, and manage an in-app calendar. The Flutter client never talks to identity or storage providers directly. Every call goes through a layered FastAPI backend that owns authentication, validation, persistence and isolation between households.

This repository is a **strict 4-week MVP** for a Holberton / RNCP 6 jury, not the full product vision. What ships is a real login, a real PostgreSQL workspace, and a demonstrable document path. Messaging, payments, third-party calendar sync, advanced governance and production AI stay out of scope (preview screens are labelled as demo).

Official title reference: [RNCP 37873](https://www.francecompetences.fr/recherche/rncp/37873/).

---

## Need analysis and scope

| Actor | Need | MVP answer |
|-------|------|------------|
| Household user | One login, one place for files and dates | Keycloak account `user` / `user`, Flutter app on port 8082 |
| Same user | Keep a document and open it later | Upload, list, detail and file download, scoped to the household |
| Same user | See what happens this week | Dashboard week overview + merged in-app calendar |
| Reviewer / peer | Reproduce the stack from a clone | Docker Compose, Alembic, this README, `./scripts/test.sh` |
| Future club / family admin | Roles and sharing | Keycloak roles exist; advanced org chart is a mock, out of MVP |

**In the Holberton MVP**

- Authentication (register, login, refresh, logout) and session
- User profile persisted in PostgreSQL (names, phone, organisation label, avatar)
- Dashboard (week overview)
- Documents: upload, list, detail, file download
- Merged in-app calendar (create, list, update, delete; no Google / Outlook sync)
- Layered REST API, PostgreSQL 16, Alembic
- Docker Compose, automated tests, GitHub Actions CI

**Out of the MVP** (product preview only, `ConfidiaDemoBadge`)

- Multi-mailbox messaging
- Payments and e-signature
- External calendar sync
- Advanced organisation chart and consent workflows
- Live LLM (the API exposes a `MockAIProvider` to show the port)

---

## RNCP 6 competency mapping

The title is built on three blocks. The README, the code and the demo are organised against them.

| Block | Competency | Evidence in this project |
|-------|------------|--------------------------|
| **BC01** Develop a secure application | Work environment | Python 3.12, Flutter stable, Docker / Colima, `.env.example` |
| BC01 | User interfaces | Flutter design system (dark-first, two brand palettes), GoRouter, form validation |
| BC01 | Business components | Identity, documents, calendar, dashboard services behind ports |
| BC01 | Project management | 4-week Kanban, locked scope, Git history |
| **BC02** Layered secure application | Need analysis and mockups | This section + [docs/pitch-holberton](docs/pitch-holberton/README.md) |
| BC02 | Software architecture | `api` → `application` → `domain` → `infrastructure` |
| BC02 | Relational database | PostgreSQL schema (users, organisations, memberships, documents, calendars) |
| BC02 | Data access | SQLAlchemy 2 async + repository adapters; Keycloak for passwords |
| **BC03** Prepare a secure deployment | Test plans | pytest (API + security + integration), `flutter test`, demo-path test |
| BC03 | Deployment documentation | This file + [docs/Installation.md](docs/Installation.md) |
| BC03 | DevOps | Docker Compose, GitHub Actions (Postgres, Alembic, pytest, Flutter) |

---

## Main features

- **Secure sign-in** with Keycloak (OAuth2 / OIDC password grant + refresh). Roles: `USER`, `MANAGER`, `ADMIN`.
- **Workspace bootstrap** on first live login: one `Famille` organisation, no duplicate user row on the next login.
- **Profile** stored in PostgreSQL (not only in the JWT).
- **Documents** for the current organisation: sniff MIME types, size limits, household isolation.
- **Calendar** month / week / day, stored in Postgres, isolated per organisation.
- **Dashboard** week overview built from the same calendar data.
- **Demo mode** in Flutter: explore the UI with mock data, no Docker. This is not the Holberton live path.
- **API contract** documented by FastAPI / OpenAPI at `/docs` when the backend is running.

---

## Technologies and tools

Choices are justified against a realistic alternative, as expected by a CDA jury.

### Frontend

| Choice | Role | Alternative considered |
|--------|------|------------------------|
| **Flutter** (stable) | One UI for web (demo) and later mobile / desktop | React web only: faster for a site, weaker for the multi-device product |
| **Riverpod** | App state | `provider`: less testable, weaker compile-time safety |
| **GoRouter** | Declarative routes | Imperative `Navigator`: harder to keep deep links and MVP vs demo paths |
| **Dio** | HTTP client | `http`: less control over interceptors and errors |

### Backend

| Choice | Role | Alternative considered |
|--------|------|------------------------|
| **FastAPI** + Python 3.12 | REST API, OpenAPI, async | Django: heavier for an API-first hub; Express: weaker typing for this stack |
| **Pydantic v2** | Request / response DTOs | Manual validation: more error-prone |
| **SQLAlchemy 2** (async) + **Alembic** | ORM and migrations | Raw SQL only: harder to evolve the schema safely |
| **Keycloak 26** | Passwords, roles, tokens | Homemade JWT in Postgres: more security work, weaker OIDC story |
| **dependency-injector** | Composition root | Service locator in routes: leaks infrastructure into `api/` |

### Data and infrastructure

| Choice | Role | Alternative considered |
|--------|------|------------------------|
| **PostgreSQL 16** | System of record | MongoDB: weaker relational integrity for orgs / memberships |
| **Docker Compose** | Reproducible local stack | Manual installs: not acceptable for a third-party reviewer |
| **GitHub Actions** | CI | Local tests only: no proof on every push |
| Paperless-ngx / Nextcloud | Optional compose services | Not used by the Holberton document path (local disk + Postgres metadata) |

---

## Architecture

Flutter never calls Keycloak, Paperless or Nextcloud. The API is the only orchestrator.

```mermaid
flowchart LR
  user[User]
  flutter[FlutterClient]
  api[FastAPI]
  keycloak[Keycloak]
  postgres[PostgreSQL]
  disk[LocalDocumentStore]

  user --> flutter
  flutter -->|"HTTPS REST /api/v1"| api
  api -->|"token grant and JWKS"| keycloak
  api -->|"identity documents calendar"| postgres
  api -->|"file bytes"| disk
```

### Layered backend (BC02)

```mermaid
flowchart TB
  presentation[api: routes, guards, HTTP]
  application[application: use cases, DTOs]
  domain[domain: ports and rules]
  infrastructure[infrastructure: Keycloak, Postgres, disk]

  presentation --> application
  application --> domain
  infrastructure --> domain
```

| Layer | Directory | Responsibility |
|-------|-----------|----------------|
| Presentation | `apps/backend_fastapi/api/` | REST routes, status codes, `Depends` |
| Application | `apps/backend_fastapi/application/` | Use cases, DTOs, orchestration |
| Domain | `apps/backend_fastapi/domain/` | Ports (interfaces), no framework |
| Infrastructure | `apps/backend_fastapi/infrastructure/` | Keycloak client, SQLAlchemy repositories, file store |
| Cross-cutting | `apps/backend_fastapi/core/` | Settings, JWT, upload sniffing, DI |

Patterns in use: **repository**, **port / adapter**, **DTO**, **dependency injection**. A rule change (for example document isolation) lives in the application / domain layer, not in a Flutter widget.

---

## Data model

Passwords are **not** stored in CONFIDIA. `users.id` is the Keycloak `sub`. Soft delete (`deleted_at`) is reserved for later GDPR erasure. Full DDL: [docs/pitch-holberton/SQL_SCHEMA_MVP.md](docs/pitch-holberton/SQL_SCHEMA_MVP.md).

```mermaid
erDiagram
  ORGANIZATIONS ||--o{ MEMBERSHIPS : includes
  USERS ||--o{ MEMBERSHIPS : joins
  ORGANIZATIONS ||--o{ DOCUMENTS : owns
  ORGANIZATIONS ||--o{ CALENDARS : owns
  ORGANIZATIONS ||--o{ NOTIFICATIONS : owns
  CALENDARS ||--o{ CALENDAR_EVENTS : contains
  DOCUMENTS ||--o{ DOCUMENT_TAGS : tagged
  TAGS ||--o{ DOCUMENT_TAGS : used
  USERS {
    text id PK
    citext email
    text first_name
    text last_name
  }
  ORGANIZATIONS {
    uuid id PK
    text name
    text kind
  }
  DOCUMENTS {
    uuid id PK
    uuid organization_id FK
    text title
    text storage_path
  }
```

---

## Security

Aligned with a defensive reading of OWASP / ANSSI for an MVP (not a production hardening audit).

| Control | Implementation |
|---------|----------------|
| Authentication | Keycloak RS256 access tokens, JWKS verification (`APP_ENV=test` uses HS256 with a test secret) |
| Session end | Logout revokes the refresh token; the access token stays valid until `exp` |
| Authorisation | Household isolation on documents and calendar (`organization_id`); Keycloak roles in the JWT |
| Uploads | MIME sniffing, 15 MiB documents / 2 MiB avatars, HTML and SVG rejected |
| Downloads | `Content-Disposition: inline` only for PDF and images |
| Injection / traversal | Parameterised SQL via SQLAlchemy; Nextcloud paths reject `..` |
| HTTP | `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `Cache-Control: no-store` |
| Secrets | `.env` gitignored; reviewers copy `.env.example` |
| CORS | Restricted to the Flutter origin (`http://localhost:8082`) |

Seed passwords (`user` / `user`) stay simple **on purpose** for the jury demo. They are not a production policy.

---

## User flow

Holberton live path (the one to rehearse):

```mermaid
sequenceDiagram
  actor User
  participant Flutter
  participant API
  participant Keycloak
  participant Postgres

  User->>Flutter: open localhost:8082
  User->>Flutter: login user / user
  Flutter->>API: POST /api/v1/auth/login
  API->>Keycloak: password grant
  API->>Postgres: upsert user and Famille workspace
  API-->>Flutter: access_token and refresh_token
  Flutter->>API: GET /dashboard/week-overview
  Flutter->>API: POST /documents/upload
  Flutter->>API: GET /documents/{id}
  User->>Flutter: logout
  Flutter->>API: POST /auth/logout
```

Demo mode skips Keycloak and Postgres. Use it to show UI chrome, not persistence.

---

## Installation and configuration

Another developer must be able to start from a clean machine. Run **one command at a time**. Do not paste comment lines that start with `# 1)` into zsh (that causes `parse error near ')'`).

### Prerequisites

| Tool | Version | Check |
|------|---------|--------|
| Git | 2.30+ | `git --version` |
| Docker Engine + Compose v2 | 24+ / 2.20+ | `docker info` |
| Flutter | stable | `flutter doctor` |
| Python | 3.12+ | `python3 --version` |
| curl | any | `curl --version` |

On macOS without Docker Desktop: `brew install colima docker docker-compose`, then `colima start`. The start scripts try to launch Colima when `docker info` fails.

### Ports

| Service | URL | Notes |
|---------|-----|--------|
| Flutter web | http://localhost:8082 | What the jury sees |
| FastAPI | http://localhost:8000 | Swagger: `/docs`, health: `/health` |
| Keycloak | http://localhost:8080 | Admin console: `admin` / `admin` |
| PostgreSQL | localhost:5432 | User `confidia` / `confidia_secret` |
| Paperless (full stack) | http://localhost:8001 | Optional, not required for documents MVP |
| Nextcloud (full stack) | http://localhost:8081 | Optional, not required for documents MVP |

The Flutter web client calls **`http://localhost:8000/api/v1`**. Only one process may bind port 8000.

### Path 1: full stack for a reviewer (recommended)

From the repository root (the folder that contains this `README.md`):

```bash
git clone https://github.com/CLMNTDFR/CONFIDIA_1.git
cd CONFIDIA_1
chmod +x scripts/*.sh
./scripts/start.sh
```

`start.sh` starts PostgreSQL, Keycloak, Redis, Paperless, Nextcloud **and** the API container on port 8000. It waits until the Keycloak realm (`http://localhost:8080/realms/confidia`) and the API (`http://localhost:8000/health`) both return HTTP 200 before it returns. First boot takes about 3-5 minutes (image download). No `docker/.env` file is required.

Then, in a second terminal:

```bash
cd apps/frontend_flutter
flutter pub get
flutter run -d chrome --web-port=8082
```

Open http://localhost:8082 and sign in with `user` / `user`.

If you use `start.sh`, **do not** also run local `uvicorn` (port clash).

### Path 2: daily development (API hot reload)

Lighter stack: only Postgres + Keycloak in Docker, API on the host.

```bash
./scripts/dev-mvp.sh
```

The script creates `apps/backend_fastapi/.env` and `.venv` if needed, waits until the Keycloak realm answers, and runs `alembic upgrade head`. It does **not** start the API or Flutter.

Terminal API (leave it open):

```bash
cd apps/backend_fastapi
source .venv/bin/activate
uvicorn api.main:app --reload --port 8000
```

`source .venv/bin/activate` must be run from `apps/backend_fastapi`, not from the repository root.

Terminal Flutter (leave it open):

```bash
cd apps/frontend_flutter
flutter run -d chrome --web-port=8082
```

### Environment

```bash
cp apps/backend_fastapi/.env.example apps/backend_fastapi/.env
```

Main variables (host API):

```env
APP_ENV=development
DATABASE_URL=postgresql+asyncpg://confidia:confidia_secret@localhost:5432/confidia
KEYCLOAK_URL=http://localhost:8080
KEYCLOAK_REALM=confidia
CORS_ORIGINS=http://localhost:3000,http://localhost:8082
```

Inside Compose, the API uses `KEYCLOAK_URL=http://keycloak:8080` and `DATABASE_URL=...@postgres:5432/confidia`.

### Stop

- Flutter and `uvicorn`: `Ctrl+C` in their terminals
- Containers: `./scripts/stop.sh` (`docker compose down`, volumes kept)
- Wipe the database: `docker compose -f docker/docker-compose.yml down -v` (destructive, not a daily command)

### Troubleshooting

| Symptom | What to check |
|---------|----------------|
| `docker info` fails | `colima start` or open Docker Desktop |
| `start.sh` times out waiting for Keycloak or `/health` | `docker logs confidia-keycloak` and `docker logs confidia-backend`. `curl` is required (the wait loop uses it). |
| Keycloak connection error on login | Wait for `http://localhost:8080/realms/confidia` to return 200 |
| `alembic` connection refused | Postgres is not healthy yet |
| Flutter login fails, Swagger works | API is not on port 8000, or Flutter is not on 8082 (CORS) |
| Port 8000 already used | Stop local uvicorn **or** `docker compose -f docker/docker-compose.yml stop backend` |
| `No such file or directory` / cannot install `.[dev]` | You are not in `apps/backend_fastapi` |
| Prompt shows `(.venv)` in the wrong folder | `deactivate`, then `cd` to the repo root |

More detail (Paperless token, Nextcloud): [docs/Installation.md](docs/Installation.md).

---

## Usage

### Demo accounts (Keycloak realm `confidia`)

| Username | Password | Roles |
|----------|----------|--------|
| `user` | `user` | USER |
| `admin` | `admin` | ADMIN, USER |
| `manager` | `manager` | MANAGER, USER |

Do not rotate `user` / `user`. The jury path depends on it.

### Live demo script (about 3 minutes)

Click-by-click path (French UI labels, what to skip): [docs/pitch-holberton/DEMO_CHECKLIST.md](docs/pitch-holberton/DEMO_CHECKLIST.md).

1. Open http://localhost:8082. Press **Se connecter** with `user` / `user`. Do not press **Mode démo**.
2. Stay on **Accueil** and show the week overview.
3. **Documents**, then **Importer**, then open the row and **Télécharger**.
4. Profile chip or **Paramètres**, then **Se déconnecter**.
5. Optional if time: create one **Calendrier** event. Do not open screens marked **Démo**.

### Demo mode (UI only)

```bash
cd apps/frontend_flutter
flutter run -d chrome --web-port=8082
```

On the login screen, click **Mode démo**. No API, no database. Out-of-MVP screens keep a demo badge.

### Main API surface

Base URL: `http://localhost:8000/api/v1`. Interactive contract: http://localhost:8000/docs

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/auth/register` | no | Create Keycloak user + tokens |
| POST | `/auth/login` | no | Password grant + workspace upsert |
| POST | `/auth/logout` | no | Revoke refresh token |
| GET / PUT | `/users/me` | yes | Profile |
| GET / POST | `/documents/` and `/documents/upload` | yes | List and upload |
| GET | `/documents/{id}` and `/documents/{id}/file` | yes | Detail and bytes |
| GET / POST | `/calendar/events` | yes | In-app calendar |
| GET | `/dashboard/week-overview` | yes | Home week |

---

## Tests and CI

The test plan follows business risk, not coverage vanity: forged tokens, household isolation, upload sniffing, and the Holberton happy path.

```mermaid
flowchart LR
  push[git push]
  ci[GitHub Actions]
  pg[CI PostgreSQL]
  py[pytest]
  fl[flutter analyze and test]
  push --> ci
  ci --> pg
  pg --> py
  ci --> fl
```

| Layer | Tool | What it protects |
|-------|------|------------------|
| API unit / HTTP | pytest + TestClient, in-memory fakes | Auth, profile, documents, calendar, dashboard, JWT |
| Holberton path | `tests/test_demo_path.py` | health → register → login → dashboard → upload → detail → file → logout |
| Integration | `pytest -m integration` | Real PostgreSQL upsert, documents, calendar (skipped if Postgres is down) |
| Security | `tests/test_security.py` | Forged HS256, empty `sub`, `alg: none`, expired token, HTML upload |
| Flutter | `flutter test` | Live login / logout, demo vs empty live workspace, validators, MVP routes |

From the repository root, after each iteration:

```bash
./scripts/test.sh
```

That runs backend pytest then `flutter test`.

```bash
cd apps/backend_fastapi
source .venv/bin/activate
pytest -q
pytest -m integration -q
```

```bash
cd apps/frontend_flutter
flutter test
```

CI ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)): GitHub-hosted Postgres, `alembic upgrade head`, full pytest (including integration), `flutter analyze`, `flutter test`. `ruff` is informational (`continue-on-error`) for now.

---

## Project management

- **Method:** Kanban, one visible weekly deliverable, scope locked in writing.
- **Horizon:** 4 weeks / 27 days (Holberton Webstack pitch).
- **Board:** [docs/pitch-holberton/KANBAN.md](docs/pitch-holberton/KANBAN.md)
- **Git:** feature work on branches, merge into `main`. `.env` files are gitignored. No secrets in the tree.
- **Solo constraint:** product framing, UX, backend, frontend and DevOps are owned by one author. Scope stays small on purpose.

| Week | Deliverable |
|------|-------------|
| 1 | Framing, MVP mockups, SQL, API skeleton, auth |
| 2 | Documents end to end (API + Flutter) |
| 3 | Dashboard, calendar, security, tests, Docker |
| 4 | UI polish, deployment docs, stricter CI, demo rehearsal |

---

## Repository structure

```
CONFIDIA_1/
├── apps/
│   ├── frontend_flutter/      # Flutter client (Riverpod, GoRouter, Dio)
│   └── backend_fastapi/       # FastAPI, layers, Alembic, pytest
├── services/keycloak/         # Realm export (users, roles, clients)
├── docker/                    # Compose: Postgres, Keycloak, API, extras
├── docs/                      # Architecture, installation, pitch, SQL
├── scripts/                   # start.sh, dev-mvp.sh, stop.sh, test.sh
└── .github/workflows/ci.yml
```

---

## Resources

- [Flutter](https://docs.flutter.dev/)
- [FastAPI](https://fastapi.tiangolo.com/)
- [SQLAlchemy 2](https://docs.sqlalchemy.org/)
- [Alembic](https://alembic.sqlalchemy.org/)
- [Keycloak](https://www.keycloak.org/documentation)
- [PostgreSQL 16](https://www.postgresql.org/docs/16/)
- [Docker Compose](https://docs.docker.com/compose/)
- [RNCP 37873](https://www.francecompetences.fr/recherche/rncp/37873/)
- [Architecture notes](docs/Architecture.md)
- [SQL schema](docs/pitch-holberton/SQL_SCHEMA_MVP.md)
- [Flutter design system](apps/frontend_flutter/README.md)
- [Full-stack install extras](docs/Installation.md)
- [Access-control preview](docs/AccessControl.md)
- [Roadmap](docs/Roadmap.md)

---

## Future features

Kept in the backlog on purpose. They must not leak into the MVP demo.

- Google / Outlook / Apple calendar sync
- Multi-mailbox inbox
- Payments and e-signature
- Fine-grained organisation roles and consent
- Production LLM behind the existing `DocumentAIProvider` port
- Paperless token and Nextcloud WebDAV as real document backends

---

## Contributing

This is a solo portfolio repository. External contributions are welcome as a clean GitHub workflow:

1. Fork the repository.
2. Create a branch (`feature/...` or `fix/...`).
3. Keep layers intact (`api` must not import infrastructure adapters directly).
4. Run `./scripts/test.sh`.
5. Open a pull request against `main`.

Details: [docs/Contributing.md](docs/Contributing.md).

---

## Author

**Clément Defer** · Holberton Webstack · RNCP 6 CDA candidate

- LinkedIn: [linkedin.com/in/clmntdfr](https://www.linkedin.com/in/clmntdfr/)
- Portfolio: [clementdefer.netlify.app](https://clementdefer.netlify.app/)
- Email: deferclement59@gmail.com

Roles covered on this project: product framing, UX mockups, backend, frontend, security, tests, Docker and documentation.

---

## License

Proprietary. CONFIDIA. All rights reserved.
