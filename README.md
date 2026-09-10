# CONFIDIA

Hub numérique pour centraliser documents administratifs, calendrier, identité et notifications.

L’interface est en **Flutter**. Derrière, une API **FastAPI** parle à **PostgreSQL** (données CONFIDIA) et à **Keycloak** (mots de passe). Tu n’as pas besoin de tout comprendre pour lancer le projet : suis les étapes ci-dessous dans l’ordre.

## Lancer l’application (à relire à chaque session)

Tu as **deux façons** d’ouvrir CONFIDIA. Ce n’est pas la même chose.

| Mode | Quand l’utiliser | Ce qu’il faut lancer |
|------|------------------|----------------------|
| **Mode démo** | Voir l’interface sans base ni login réel | **Uniquement Flutter** |
| **Stack réelle** | Compte `user` / `user`, profil enregistré en base | **Docker** (Postgres + Keycloak) **+** API **+** Flutter |

Les commandes du type `docker compose` + `alembic` + `uvicorn` démarrent **le serveur** (API + base + login). Elles **ne remplacent pas** Flutter. L’écran dans Chrome, c’est toujours :

```bash
cd ~/CONFIDIA_1/apps/frontend_flutter
flutter run -d chrome --web-port=8082
```

Sans cette commande (ou sans le bouton **Mode démo**), tu n’as pas l’application visuelle.

### Les trois programmes (stack réelle)

Imagine trois étages. Ils doivent tourner **en même temps**, donc **plusieurs fenêtres de terminal** (une commande bloquante par fenêtre).

1. **Docker** : PostgreSQL (tables et données) + Keycloak (vérifie `user` / `user`). Tu le laisses tourner en arrière-plan (`-d`).
2. **FastAPI (`uvicorn`)** : l’API sur le port **8000**. Flutter lui envoie login, profil, etc. **Laisse ce terminal ouvert.**
3. **Flutter** : l’interface sur **http://localhost:8082**. **Laisse ce terminal ouvert aussi.**

`alembic upgrade head` n’est **pas** un quatrième service. C’est une commande **ponctuelle** qui crée les tables dans Postgres (première fois, ou après un changement de schéma SQL). Tu n’as pas besoin de la relancer tous les matins si les tables existent déjà.

### Ports à retenir

Flutter web appelle **toujours** `http://localhost:8000/api/v1`. Si l’API n’écoute pas sur **8000**, le login depuis l’app échoue.

| Service | URL | Rôle |
|---------|-----|------|
| Application (Flutter) | http://localhost:8082 | Ce que tu vois |
| API FastAPI | http://localhost:8000 | Cerveau (Swagger : http://localhost:8000/docs) |
| Keycloak | http://localhost:8080 | Login (admin console : `admin` / `admin`) |
| PostgreSQL | localhost:5432 | Données (user `confidia`, mot de passe `confidia_secret`) |

**Ne lance pas l’API sur le port 8010** sauf si le 8000 est déjà pris **et** que tu changes aussi l’URL dans l’app. Le 8010 a servi un jour de contournement (un autre conteneur occupait 8000). Pour CONFIDIA, libère le 8000 :

```bash
lsof -nP -iTCP:8000 -sTCP:LISTEN
```

### Où coller les commandes (sinon rien ne marche)

Le prompt zsh affiche **le dossier courant** (`apps %`, `~ %`, `/ %`…). Les chemins `apps/...` et `scripts/...` ne marchent **que** depuis la racine du dépôt.

1. Le bon dossier s’appelle `CONFIDIA_1`. Il contient `README.md`, `apps`, `docker` et `scripts`.
2. Colle **une commande à la fois**, jamais un pavé avec des lignes qui commencent par `#`. Sous zsh, `# 1)` n’est **pas** un commentaire et déclenche `parse error near ')'`.
3. Si le prompt commence par `(.venv)` alors que tu n’es pas dans `apps/backend_fastapi`, tape `deactivate` puis repars de la racine.

```bash
cd ~/CONFIDIA_1
pwd
ls README.md apps docker scripts
```

`pwd` doit finir par `/CONFIDIA_1`. Si tu vois `.../CONFIDIA_1/apps`, tu es **un étage trop bas** : `cd ..`

### Prérequis (une fois sur la machine)

- **Docker** (Docker Desktop, ou **Colima** sur macOS : `brew install colima docker docker-compose`)
- **Flutter** (canal stable) : `flutter doctor`
- **Python 3.12+** : `python3 --version`

### Premier lancement (une fois)

Le plus simple : un seul script, depuis la racine. Il crée le `.env` et le `.venv` s’ils manquent, démarre Postgres + Keycloak, applique les tables.

```bash
cd ~/CONFIDIA_1
chmod +x scripts/*.sh
./scripts/dev-mvp.sh
```

Ce script **ne lance pas** Flutter et **ne lance pas** `uvicorn` : il prépare le terrain, puis affiche les deux commandes à coller.

À la main, seulement si tu préfères (toujours depuis `~/CONFIDIA_1`). D’abord le fichier d’environnement de l’API :

```bash
cp apps/backend_fastapi/.env.example apps/backend_fastapi/.env
```

Si le fichier existe déjà, `cp` peut demander confirmation : ce n’est pas grave, tu peux refuser.

Ensuite Python (le `.venv` doit être **dans** `backend_fastapi`, pas dans `apps`) :

```bash
cd ~/CONFIDIA_1/apps/backend_fastapi
python3 -m venv .venv
source .venv/bin/activate
pip install ".[dev]"
```

Puis Flutter :

```bash
cd ~/CONFIDIA_1/apps/frontend_flutter
flutter pub get
```

Sur macOS, si `docker info` échoue, démarre le moteur Docker :

```bash
colima start
```

### Tous les jours : stack réelle (3 terminaux)

Chaque bloc commence par `cd ~/CONFIDIA_1/...` : tu peux le coller même si tu étais dans le mauvais dossier.

**Terminal 1** (base + login ; une fois lancé, les conteneurs tournent tout seuls) :

```bash
cd ~/CONFIDIA_1/docker
docker compose up -d postgres keycloak
```

Attends que Keycloak soit prêt (le premier démarrage peut prendre une minute). Test simple :

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/realms/confidia
```

Tu dois voir `200`. Si tu as `000` ou une erreur de connexion, attends et réessaie.

**Tables** (première fois, ou après modification du SQL) :

```bash
cd ~/CONFIDIA_1/apps/backend_fastapi
source .venv/bin/activate
alembic upgrade head
```

**Terminal 2** (API, reste ouvert, tu y vois les logs) :

```bash
cd ~/CONFIDIA_1/apps/backend_fastapi
source .venv/bin/activate
uvicorn api.main:app --reload --port 8000
```

Vérifie : http://localhost:8000/health doit répondre `healthy`.

**Terminal 3** (interface, reste ouvert) :

```bash
cd ~/CONFIDIA_1/apps/frontend_flutter
flutter run -d chrome --web-port=8082
```

Ouvre **http://localhost:8082**, connecte-toi avec `user` / `user` (ou `admin` / `admin`). Le profil est alors écrit dans PostgreSQL (organisation **Famille**, sans dupliquer l’utilisateur au second login).

### Tous les jours : mode démo (1 terminal)

```bash
cd ~/CONFIDIA_1/apps/frontend_flutter
flutter run -d chrome --web-port=8082
```

Sur l’écran de connexion, clique **Mode démo**. Aucun Docker, aucune API. Les données sont fictives. C’est pratique pour l’UI ; ce n’est **pas** le parcours Holberton « vrai login + vraie base ».

### Deux pièges fréquents

**1. `./scripts/start.sh` vs le lancement léger**

`./scripts/start.sh` démarre **toute** la stack Docker : Postgres, Keycloak, Paperless, Nextcloud, **et** l’API dans un conteneur sur le port **8000**.

- Si tu utilises `start.sh`, **ne lance pas** `uvicorn` en local (le port 8000 serait pris deux fois). Lance seulement Flutter.
- Pour le MVP quotidien (login + profil + UI), le lancement léger suffit : **seulement** `postgres` + `keycloak` dans Docker, API avec `uvicorn`, Flutter à part. Paperless et Nextcloud ne sont pas nécessaires pour te connecter.

**2. Tes données ne disparaissent pas quand tu arrêtes Docker**

Postgres écrit dans un **volume** Docker (`postgres_data`). `docker compose stop` ou `./scripts/stop.sh` (`docker compose down`) **garde** les utilisateurs déjà créés. Seul `docker compose down -v` **efface** la base. Ne l’utilise pas par habitude.

### Arrêter

- Flutter et `uvicorn` : `Ctrl+C` dans leur terminal.
- Conteneurs :

```bash
cd ~/CONFIDIA_1
./scripts/stop.sh
```

ou, si tu n’avais lancé que Postgres et Keycloak :

```bash
cd ~/CONFIDIA_1/docker
docker compose stop postgres keycloak
```

### Si quelque chose refuse de démarrer

| Symptôme | Piste |
|----------|--------|
| `docker info` échoue | `colima start` (macOS) ou ouvrir Docker Desktop |
| Keycloak injoignable | Attendre le premier boot ; `docker compose -f docker/docker-compose.yml ps` et `docker logs confidia-keycloak` |
| `alembic` : connexion refusée | Postgres n’est pas up ou pas `healthy` |
| Login KO depuis Flutter, Swagger OK | API pas sur **8000**, ou Flutter pas sur **8082** (CORS) |
| Port 8000 déjà utilisé | Un autre projet (souvent un conteneur `backend`). Arrête-le, ou `docker compose stop backend` dans `docker/` si `start.sh` a été lancé |
| `zsh: parse error near ')'` | Tu as collé un commentaire du type `# 1)`. Colle seulement les lignes de commande. |
| `No such file or directory` / `.[dev]` not installable | Mauvais dossier. `cd ~/CONFIDIA_1` puis `ls README.md` |

Détail Paperless / Nextcloud / variables d’environnement : [docs/Installation.md](docs/Installation.md).

## Vérifier qu’on n’a rien cassé (à chaque itération)

Avant de considérer une modification terminée, lance :

```bash
cd ~/CONFIDIA_1
./scripts/test.sh
```

Cela enchaîne, depuis la racine du repo :

1. **pytest** dans `apps/backend_fastapi` : health, register/login, profil, documents (upload / liste / détail / fichier), dashboard, calendrier, isolation entre foyers, JWT, et le parcours de démo Holberton (`tests/test_demo_path.py`). Les tests marqués `integration` s’exécutent si PostgreSQL répond (sinon ils sont skippés).
2. **flutter test** dans `apps/frontend_flutter` : login live mocké, session démo vs live, validateurs d'inscription, périmètre Démo.

À la main :

```bash
cd ~/CONFIDIA_1/apps/backend_fastapi
source .venv/bin/activate
pytest -q
```

Frontend (pas besoin de Postgres) :

```bash
cd ~/CONFIDIA_1/apps/frontend_flutter
flutter test
```

Avec Postgres déjà lancé (`./scripts/dev-mvp.sh`) :

```bash
cd ~/CONFIDIA_1/apps/backend_fastapi
source .venv/bin/activate
pytest -m integration -q
```

Sur GitHub, [`.github/workflows/ci.yml`](.github/workflows/ci.yml) installe un Postgres de CI, applique Alembic, lance pytest (y compris l’intégration), puis `flutter analyze` et `flutter test`.

## Fonctionnalités MVP

- Authentification OAuth2/OIDC via Keycloak (rôles ADMIN, USER, MANAGER)
- Gestion des profils utilisateurs
- Consultation, upload et classement documentaire (Paperless-ngx)
- Stockage sécurisé (Nextcloud via WebDAV)
- Calendrier (mois / semaine / jour)
- Centre de notifications
- Tableau de bord premium
- Architecture IA prête (MockAIProvider)
- **Gouvernance & accès** : organigramme, rôles, droits, consentement, assistant planning (maquette, hors MVP Holberton)

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Frontend | Flutter (Android, iOS, Windows, macOS, Linux, Web) |
| Backend | FastAPI + Python 3.12+ |
| Auth | Keycloak (OAuth2, OIDC, Refresh Tokens) |
| Données CONFIDIA | PostgreSQL 16 (schéma MVP + Alembic) |
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
└── scripts/                  # Démarrage, arrêt, tests
```

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

- [Installation (stack complète, Paperless, Nextcloud)](docs/Installation.md)
- [Architecture](docs/Architecture.md)
- [Gouvernance & accès](docs/AccessControl.md)
- [Design system Flutter](apps/frontend_flutter/README.md)
- [Schéma SQL MVP](docs/pitch-holberton/SQL_SCHEMA_MVP.md)
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

Propriétaire. CONFIDIA SAS.
