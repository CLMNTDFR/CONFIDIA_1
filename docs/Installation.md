# Installation CONFIDIA

**Lancement quotidien (débutant, mode démo vs login réel, ports, tests) :** suis le [README à la racine du dépôt](../README.md). Cette page décrit l’installation **complète** (Paperless, Nextcloud, backend dans Docker).

## Prérequis

| Outil | Version minimale |
|-------|-----------------|
| Docker | 24+ |
| Docker Compose | 2.20+ |
| Flutter | 3.7+ (stable) |
| Python | 3.12+ |
| Git | 2.30+ |

### Plateformes Flutter supportées

- Android (API 21+)
- iOS (13+)
- Windows 10+
- macOS 10.15+
- Linux (Ubuntu 20.04+)

## Installation complète

### 1. Cloner le dépôt

```bash
git clone <repo-url> confidia
cd confidia
```

### 2. Configuration environnement

```bash
cp apps/backend_fastapi/.env.example apps/backend_fastapi/.env
```

Variables principales :

```env
APP_ENV=development
DATABASE_URL=postgresql+asyncpg://confidia:confidia_secret@localhost:5432/confidia
KEYCLOAK_URL=http://localhost:8080
KEYCLOAK_REALM=confidia
PAPERLESS_URL=http://localhost:8001
PAPERLESS_TOKEN=
NEXTCLOUD_URL=http://localhost:8081
```

### 3. Démarrer l'infrastructure Docker

```bash
chmod +x scripts/*.sh
./scripts/start.sh
```

Premier démarrage : ~3-5 minutes (téléchargement images, init DB).

Le backend applique les migrations Alembic au démarrage du conteneur (`alembic upgrade head`). En local :

```bash
cd apps/backend_fastapi
source .venv/bin/activate
alembic upgrade head
```

Services disponibles :

| Service | URL | Credentials |
|---------|-----|-------------|
| Keycloak | http://localhost:8080 | admin / admin |
| Paperless | http://localhost:8001 | admin / admin |
| Nextcloud | http://localhost:8081 | admin / admin |
| Backend API | http://localhost:8000 | via Keycloak |
| PostgreSQL | localhost:5432 | confidia / confidia_secret |

### 4. Configurer Paperless (optionnel)

1. Accéder à http://localhost:8001
2. Se connecter (admin/admin)
3. Aller dans **Admin → Auth Tokens**
4. Créer un token et l'ajouter à `PAPERLESS_TOKEN`

### 5. Backend (développement local)

```bash
cd apps/backend_fastapi
python3 -m venv .venv
source .venv/bin/activate
pip install ".[dev]"
uvicorn api.main:app --reload --port 8000
```

### 6. Frontend Flutter

```bash
cd apps/frontend_flutter
flutter pub get
flutter run -d chrome --web-port=8082
```

L’app web écoute sur **http://localhost:8082** et parle à l’API sur **http://localhost:8000**. Sans Flutter, tu n’as que l’API.

#### Cibler une plateforme

```bash
flutter run -d macos        # macOS
flutter run -d chrome --web-port=8082   # Web (port attendu par l'API / CORS)
flutter run -d windows      # Windows
flutter devices             # Lister les appareils
```

#### Mode démo (sans backend)

Sur l'écran de connexion, cliquer **Mode démo** pour utiliser les données mockées.

### 7. Vérification

```bash
# Backend health
curl http://localhost:8000/health

# Suite de non-régression (API + Flutter)
./scripts/test.sh
```

## Arrêt des services

```bash
./scripts/stop.sh
```

## Dépannage

### Keycloak ne démarre pas
Vérifier que PostgreSQL est healthy : `docker compose ps`

### Paperless timeout
Le premier démarrage peut prendre plusieurs minutes. Vérifier les logs : `docker compose logs paperless`

### Flutter — erreur Android Studio
```bash
flutter config --android-studio-dir ""
```

### Port déjà utilisé
Modifier les ports dans `docker/docker-compose.yml`
