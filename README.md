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
- **Gouvernance & accès** — organigramme, rôles, droits granulaires, consentement documentaire, assistant IA planning (démo)

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Frontend | Flutter (Android, iOS, Windows, macOS, Linux, Web) |
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

- Docker & Docker Compose (ou Colima sur macOS)
- Flutter SDK (stable)
- Python 3.12+

### 1. Lancer l'infrastructure

```bash
./scripts/start.sh
```

Si Docker n'est pas démarré sur macOS :

```bash
colima start
./scripts/start.sh
```

### 2. Lancer le frontend (web local)

```bash
cd apps/frontend_flutter
flutter pub get
flutter run -d chrome --web-port=8082
```

L'application est accessible sur **http://localhost:8082**.

Autres plateformes :

```bash
flutter run -d macos    # macOS
flutter run             # appareil / émulateur par défaut
```

Connectez-vous avec `user` / `user`, ou utilisez le **mode démo** sans backend.

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

## Gouvernance, rôles & droits

CONFIDIA vise des usages **personnels** et **collectifs** (famille, club, association). L'utilisateur configure lui-même :

| Capacité | Description |
|----------|-------------|
| **Organigramme** | Hiérarchie visuelle drag-and-drop (directeur → staff → licenciés…) |
| **Rôles** | Modèles prédéfinis (admin, parent, entraîneur, trésorier…) |
| **Permissions** | Droits fins : calendrier, pièces d'identité, bulletins de salaire… |
| **Consentement** | Notification + acceptation/refus avant partage de documents sensibles |
| **IA Planning** | Détection de conflits calendrier / trajets, proposition ajustable par prompt |

**Dans l'app :** Paramètres → *Gouvernance & accès* (`/access-control`)

**Documentation complète :** [docs/AccessControl.md](docs/AccessControl.md)

**API :** `GET/PUT /api/v1/access-control/*` (voir Swagger)

## Documentation

- [Architecture](docs/Architecture.md)
- [Installation](docs/Installation.md)
- [Gouvernance & accès](docs/AccessControl.md)
- [Design system Flutter](apps/frontend_flutter/README.md)
- [Roadmap](docs/Roadmap.md)
- [Contributing](docs/Contributing.md)

## Identité visuelle

Deux palettes interchangeables (Paramètres → Apparence) :

| | Thème bleu (défaut) | Thème rose |
|---|---|---|
| Primary | `#015AAB` | `#D20050` |
| Secondary | `#06E5EF` | `#AF73F7` |

Dark mode par défaut, light mode disponible. Voir le [design system](apps/frontend_flutter/README.md).

## Licence

Propriétaire — CONFIDIA SAS
