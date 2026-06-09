# Architecture CONFIDIA

## Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Frontend                          │
│  Riverpod · GoRouter · Dio · Design System                  │
│  (Android · iOS · Windows · macOS · Linux)                  │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS / REST
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI Backend                           │
│  Clean Architecture · DI · Guards · DTOs                    │
├─────────────┬──────────────┬──────────────┬─────────────────┤
│   Keycloak  │  Paperless   │  Nextcloud   │  MockAIProvider │
│  OAuth2/OIDC│  Documents   │  WebDAV      │  (futur LLM)    │
└─────────────┴──────────────┴──────────────┴─────────────────┘
```

## Principe fondamental

**Flutter ne communique jamais directement avec Paperless, Nextcloud ou Keycloak.** Tout passe par l'API FastAPI qui agit comme couche d'orchestration et d'abstraction.

## Backend — Clean Architecture

```
apps/backend_fastapi/
├── api/                  # Couche présentation (routes, dépendances)
│   └── v1/
├── application/          # Cas d'usage, services, DTOs
│   ├── dto/
│   └── services/
├── domain/               # Entités, interfaces (ports)
│   └── interfaces/
├── infrastructure/       # Implémentations (adaptateurs)
│   ├── keycloak/
│   ├── paperless/
│   ├── nextcloud/
│   └── ai/
└── core/                 # Config, sécurité, DI
```

### Couches

| Couche | Responsabilité |
|--------|----------------|
| `api/` | Endpoints REST, validation entrée, guards |
| `application/` | Logique métier, orchestration, DTOs |
| `domain/` | Interfaces abstraites (ports) |
| `infrastructure/` | Intégrations concrètes (adaptateurs) |
| `core/` | Configuration, sécurité, injection de dépendances |

### Interfaces clés

```python
class DocumentRepository(ABC):      # Port documents (Paperless)
class StorageProvider(ABC):         # Port stockage (Nextcloud → S3, etc.)
class DocumentAIProvider(ABC):      # Port IA (OpenAI, Claude, Mistral, local)
```

## Authentification

- **Keycloak** realm `confidia` avec import automatique
- Flux : Password Grant (MVP) → Refresh Token automatique
- Rôles : `ADMIN`, `USER`, `MANAGER`
- Guards backend : `require_roles(Role.ADMIN)`
- Guards frontend : vérification rôles via `authStateProvider`

## Intégration Paperless-ngx

`PaperlessClient` implémente `DocumentRepository` :
- Liste, détail, upload, suppression, recherche
- Fallback automatique sur données mock si service indisponible
- Token API configurable via `PAPERLESS_TOKEN`

## Intégration Nextcloud

`NextcloudStorageProvider` implémente `StorageProvider` :
- WebDAV pour upload/download/list
- Partage de fichiers
- Remplaçable par S3, MinIO, etc. sans modifier l'application

## Architecture IA

```python
class DocumentAIProvider(ABC):
    async def summarize(document_id, content) -> SummaryDTO
    async def classify(document_id, content) -> ClassificationDTO
    async def extract_dates(document_id, content) -> DateExtractionDTO
    async def extract_amounts(document_id, content) -> AmountExtractionDTO
```

`MockAIProvider` retourne des données simulées. Pour brancher un vrai LLM :
1. Créer `OpenAIProvider(DocumentAIProvider)`
2. Enregistrer dans `core/di.py`
3. Aucune modification frontend nécessaire

## Frontend

### Design System

```
lib/core/theme/
├── colors.dart       # Palette (#d20050, #af73f7, #4b96b4)
├── spacing.dart      # Espacements et rayons
├── typography.dart   # Inter via Google Fonts
└── theme.dart        # Thèmes dark/light
```

### Architecture feature-based

```
lib/
├── core/             # API, auth, router, theme
├── features/         # Un dossier par écran/fonctionnalité
│   ├── auth/
│   ├── dashboard/
│   ├── documents/
│   ├── calendar/
│   ├── notifications/
│   ├── profile/
│   ├── settings/
│   └── admin/
└── shared/           # Modèles, widgets, mock data
```

### API Client (Dio)

- Intercepteur auth (Bearer token)
- Refresh automatique sur 401
- Stockage sécurisé des tokens (`flutter_secure_storage`)

## Décisions techniques

| Décision | Choix | Justification |
|----------|-------|---------------|
| Monorepo | Oui | Cohérence, CI unifiée |
| Clean Architecture | Oui | Évolutivité, testabilité |
| Mock fallback | Oui | MVP exécutable sans tous les services |
| Paperless direct | Non | Sécurité, abstraction |
| Provider classique | Non | Riverpod (requirement) |
