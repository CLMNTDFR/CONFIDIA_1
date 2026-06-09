# CONFIDIA

**Hub numérique intelligent** — centralisez vos documents administratifs, calendrier, identité numérique et notifications dans une application unifiée.

CONFIDIA orchestre des solutions open source matures (Paperless-ngx, Nextcloud, Keycloak) derrière une API FastAPI et une application Flutter multiplateforme.

## Fonctionnalités MVP

- Authentification OAuth2/OIDC via Keycloak (rôles ADMIN, USER, MANAGER)
- Gestion des profils utilisateurs
- Consultation, upload et classement documentaire (Paperless-ngx)
- Stockage sécurisé (Nextcloud via WebDAV)
- Calendrier (mois / semaine / jour)
- Centre de notifications
- Tableau de bord premium
- Architecture IA prête (MockAIProvider)

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Frontend | Flutter (Android, iOS, Windows, macOS, Linux) |
| Backend | FastAPI + Python 3.12+ |
| Auth | Keycloak (OAuth2, OIDC, Refresh Tokens) |
| Documents | Paperless-ngx |
| Stockage | Nextcloud |
| État | Riverpod |
| Routing | GoRouter |
| HTTP | Dio |

## Structure du monorepo

```
CONFIDIA/
├── apps/
│   ├── frontend_flutter/     # Application Flutter
│   └── backend_fastapi/      # API FastAPI (Clean Architecture)
├── services/
│   ├── keycloak/             # Configuration realm Keycloak
│   ├── paperless/            # Documentation Paperless
│   └── nextcloud/            # Documentation Nextcloud
├── docker/                   # Docker Compose (tous les services)
├── docs/                     # Documentation détaillée
└── scripts/                  # Scripts de démarrage
```

## Démarrage rapide

### Prérequis

- Docker & Docker Compose
- Flutter SDK (stable)
- Python 3.12+

### 1. Lancer l'infrastructure

```bash
./scripts/start.sh
```

### 2. Lancer le frontend

```bash
cd apps/frontend_flutter
flutter pub get
flutter run
```

Utilisez **Mode démo** pour tester sans backend, ou connectez-vous avec `user/user`.

### 3. API Backend

- API : http://localhost:8000
- Docs Swagger : http://localhost:8000/docs
- Keycloak : http://localhost:8080 (admin/admin)

## Comptes de test

| Utilisateur | Mot de passe | Rôles |
|-------------|--------------|-------|
| admin | admin | ADMIN, USER |
| user | user | USER |
| manager | manager | MANAGER, USER |

## Documentation

- [Architecture](docs/Architecture.md)
- [Installation](docs/Installation.md)
- [Roadmap](docs/Roadmap.md)
- [Contributing](docs/Contributing.md)

## Identité visuelle

| Couleur | Hex | Usage |
|---------|-----|-------|
| Primary | `#d20050` | Actions, accents |
| Secondary | `#af73f7` | Highlights |
| Accent | `#4b96b4` | Informations |

Dark mode par défaut, light mode disponible.

## Licence

Propriétaire — CONFIDIA SAS
