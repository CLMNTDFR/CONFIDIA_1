# Installation

The Holberton live path lives in the [root README](../README.md) (Installation and configuration). This page is the short extra: official Docker path, daily host API, optional Paperless token.

## Prerequisites

| Tool | Version | Check |
|------|---------|--------|
| Git | 2.30+ | `git --version` |
| Docker Engine + Compose v2 | 24+ / 2.20+ | `docker info` |
| Flutter | stable | `flutter doctor` |
| Python | 3.12+ | `python3 --version` |
| curl | any | `curl --version` |

On macOS without Docker Desktop: `brew install colima docker docker-compose`, then `colima start`.

## Official path (reviewer / jury)

From the repository root. `start.sh` starts the full Compose stack, including the API on port 8000. It waits until `http://localhost:8080/realms/confidia` and `http://localhost:8000/health` both return HTTP 200, then returns. First boot: about 3-5 minutes (image download). No `docker/.env` file is required.

```bash
chmod +x scripts/*.sh
./scripts/start.sh
```

Do **not** run local `uvicorn` after `start.sh` (port 8000 clash). Next step is Flutter only:

```bash
cd apps/frontend_flutter
flutter pub get
flutter run -d chrome --web-port=8082
```

Open http://localhost:8082 and sign in with `user` / `user`.

## Daily path (API hot reload)

Postgres and Keycloak in Docker, API on the host:

```bash
./scripts/dev-mvp.sh
```

Then uvicorn (leave the terminal open):

```bash
cd apps/backend_fastapi
source .venv/bin/activate
uvicorn api.main:app --reload --port 8000
```

Then Flutter (same commands as the official path). If `confidia-backend` still holds port 8000, stop it first:

```bash
docker compose -f docker/docker-compose.yml stop backend
```

`dev-mvp.sh` creates `apps/backend_fastapi/.env` from `.env.example` when missing. That host `.env` is for uvicorn, not for Compose.

## Optional: Paperless token

Not needed for Holberton documents (local disk + Postgres metadata). Only if you want the Paperless extra:

1. Open http://localhost:8001 and sign in (`admin` / `admin`).
2. Admin, then Auth Tokens: create a token.
3. Set `PAPERLESS_TOKEN` in `apps/backend_fastapi/.env` for host uvicorn, or export it before Compose.

## Compose commands

Use the project file from the repository root:

```bash
docker compose -f docker/docker-compose.yml ps
docker compose -f docker/docker-compose.yml logs paperless
```

Or `cd docker` then `docker compose ...`. `docker compose` from the repo root without `-f` will not find this stack.

## Stop and checks

```bash
./scripts/stop.sh
curl http://localhost:8000/health
./scripts/test.sh
```

Wipe volumes (destructive): `docker compose -f docker/docker-compose.yml down -v`

## Troubleshooting

| Symptom | What to check |
|---------|----------------|
| `start.sh` times out | `docker logs confidia-keycloak` and `docker logs confidia-backend`. `curl` is required for the wait loop. |
| `docker info` fails | `colima start` or open Docker Desktop |
| Keycloak connection error on login | Wait for `http://localhost:8080/realms/confidia` to return 200 |
| Port 8000 already used | Stop local uvicorn, or `docker compose -f docker/docker-compose.yml stop backend` |
| Flutter Android Studio error | `flutter config --android-studio-dir ""` |
