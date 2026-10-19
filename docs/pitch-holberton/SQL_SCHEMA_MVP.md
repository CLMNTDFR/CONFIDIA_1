# Schéma PostgreSQL MVP (Holberton)

Périmètre : **auth, profil, dashboard, documents, calendrier fusionné interne, notifications**.  
Hors MVP (messagerie, paiements, sync calendriers, gouvernance avancée, IA production) : **pas de tables créées**, mais le schéma MVP est pensé pour les accueillir sans casser les FKs.

Sources : cadrage technique (`docs/cadrage/4-CONFIDIA_Architecture_technique.pdf`), `docs/Architecture.md`, `docs/AccessControl.md`, DTOs FastAPI et modèles Flutter.

DDL exécutable : [`schema_mvp.sql`](./schema_mvp.sql), appliqué par Alembic (`apps/backend_fastapi/migrations`, copie `apps/backend_fastapi/infrastructure/db/sql/schema_mvp.sql`).

---

## Principes (cadrage)

| Principe | Choix MVP | Évolution |
|----------|-----------|-----------|
| Multi-tenant | `organization_id` sur toute donnée métier | Plusieurs orgs / utilisateur via `memberships` |
| Identité | `users.id` = sujet Keycloak (`sub`) | Profil CONFIDIA, mots de passe restent dans Keycloak |
| Soft delete | `deleted_at TIMESTAMPTZ NULL` | Purge / RGPD plus tard |
| Audit léger | `created_at`, `updated_at`, `created_by` | Table `audit_logs` hors MVP |
| Fichiers | Métadonnées dans Postgres, binaire via Paperless | `paperless_id` (et plus tard Nextcloud / S3) |
| IA | Aucune table | `ai_analyses` / `ai_conversations` plus tard ; mock OK en démo |

---

## Tables MVP (à créer)

```
organizations ──┬── memberships ── users
                ├── calendars ── calendar_events ── reminders
                │                      │
                │                      └── documents
                ├── documents ── document_tags ── tags
                └── notifications
```

### `organizations`

Espace de travail. Au premier login, une org « Famille » est créée. Le nom, le `kind` et l'icône se modifient. L'organigramme est le `parent_id` des memberships, pas une table `org_nodes`.

| Colonne | Type | Notes |
|---------|------|--------|
| `id` | `UUID` PK | |
| `name` | `TEXT` | |
| `slug` | `TEXT` UNIQUE | `famille-{user}` |
| `kind` | `TEXT` | `personal` \| `family` \| `club` \| `org` |
| `icon` | `TEXT` | identifiant d'icône, défaut `family` |
| `level_labels` | `JSONB` | libellés des niveaux, `{}` par défaut |
| `created_at` / `updated_at` / `deleted_at` | timestamptz | |

### `users`

Profil applicatif. Auth = Keycloak.

| Colonne | Type | Notes |
|---------|------|--------|
| `id` | `TEXT` PK | `sub` Keycloak |
| `email` | `CITEXT` UNIQUE | |
| `first_name` / `last_name` | `TEXT` | |
| `phone` | `TEXT` NULL | Profil MVP |
| `avatar_url` | `TEXT` NULL | |
| `locale` | `TEXT` | défaut `fr-FR` |
| `timezone` | `TEXT` | défaut `Europe/Paris` |
| `created_at` / `updated_at` / `deleted_at` | timestamptz | |

Le champ Flutter `organization` (libellé libre) n’est **pas** dupliqué ici : le nom d’org vient de `organizations` via `memberships`.

### `memberships`

Lien user ↔ org. Le rôle reste une chaîne (`owner`, `admin`, `member`). Les droits affichés sont un tableau d'identifiants, pas une table `permissions`.

| Colonne | Type | Notes |
|---------|------|--------|
| `id` | `UUID` PK | |
| `organization_id` | `UUID` FK | |
| `user_id` | `TEXT` FK | |
| `role` | `TEXT` | `owner` \| `admin` \| `member` |
| `parent_id` | `UUID` FK NULL | autre membership du même espace, `ON DELETE SET NULL` |
| `permissions` | `TEXT[]` | droits enregistrés, `{}` par défaut |
| `link_type` | `TEXT` | `reportsTo` \| `dottedLine` \| `delegate` |
| `is_default` | `BOOLEAN` | org ouverte au login |
| UNIQUE `(organization_id, user_id)` | | |

Les rôles plateforme Keycloak (`ADMIN`, `MANAGER`, `USER`) restent dans le JWT (écran `/admin`, hors MVP). L'accès aux documents et à l'agenda reste celui de l'organisation, même si `permissions` liste des droits plus fins.

### `invitations`

Une ligne par espace et par personne invitée. Le statut est le dernier état connu.

| Colonne | Type | Notes |
|---------|------|--------|
| `id` | `UUID` PK | |
| `organization_id` | `UUID` FK | espace qui invite |
| `inviter_id` | `TEXT` FK | |
| `invitee_id` | `TEXT` FK | profil Confidia déjà créé |
| `status` | `TEXT` | `pending` \| `accepted` \| `refused` \| `cancelled` |
| `created_at` / `updated_at` | timestamptz | |
| UNIQUE `(organization_id, invitee_id)` | | |

Accepter crée ou réactive un membership `member`. L'espace par défaut de l'invité ne change pas.

### `documents`

Cœur métier MVP (upload / liste / détail). Aligné sur `DocumentDTO` / `DocumentModel`.

| Colonne | Type | Notes |
|---------|------|--------|
| `id` | `UUID` PK | |
| `organization_id` | `UUID` FK | isolation tenant |
| `owner_id` | `TEXT` FK | uploader |
| `title` | `TEXT` | |
| `content` | `TEXT` NULL | extrait / OCR optionnel |
| `correspondent` | `TEXT` NULL | |
| `document_type` | `TEXT` NULL | facture, contrat… |
| `category` | `TEXT` NULL | string MVP ; table `categories` plus tard |
| `mime_type` | `TEXT` NULL | |
| `file_size` | `INTEGER` NULL | octets |
| `is_important` | `BOOLEAN` | |
| `paperless_id` | `INTEGER` UNIQUE NULL | id Paperless-ngx |
| `storage_path` | `TEXT` NULL | si hors Paperless |
| `created_at` / `updated_at` / `deleted_at` | timestamptz | |

Pas de `document_versions` en MVP (Paperless versionne le fichier). Colonne prête : on n’ajoute pas de FK vers une table absente.

### `tags` + `document_tags`

Les DTOs exposent déjà `tags: list[str]`. Normaliser maintenant évite une migration douloureuse.

### `calendars`

Agendas **internes** Confidia (Famille, Club…). Pas de sync Google/Outlook/Apple.

| Colonne | Type | Notes |
|---------|------|--------|
| `id` | `UUID` PK | |
| `organization_id` | `UUID` FK | |
| `name` | `TEXT` | |
| `slug` | `TEXT` | `family`, `club` (unique par org) |
| `color` | `TEXT` NULL | |
| `is_default` | `BOOLEAN` | |

### `calendar_events`

Calendrier fusionné MVP = événements `source = 'confidia'`.  
Les autres valeurs de `source` sont **autorisées en CHECK** pour la démo UI, sans table `calendar_sources`.

| Colonne | Type | Notes |
|---------|------|--------|
| `id` | `UUID` PK | |
| `calendar_id` | `UUID` FK | |
| `organization_id` | `UUID` FK | dénormalisé pour les filtres tenant |
| `title` / `description` / `location` | | |
| `starts_at` / `ends_at` | timestamptz | |
| `all_day` | `BOOLEAN` | |
| `event_type` | `TEXT` | `deadline` \| `meeting` \| `reminder` \| `appointment` |
| `color` | `TEXT` NULL | |
| `document_id` | `UUID` NULL FK | échéance liée à un doc |
| `source` | `TEXT` | défaut `confidia` ; aussi `google`, `outlook`, `apple`, `microsoft365` |
| `week_scope` | `TEXT` NULL | `personal` \| `family` \| `professional` |
| `payment_id` | `UUID` NULL | **pas de FK** (table paiements hors MVP) |
| `email_id` | `UUID` NULL | **pas de FK** (table mails hors MVP) |

### `reminders`

Rappels d’événement (cadrage : entité `reminders`). Sert les notifications d’échéances MVP.

| Colonne | Type | Notes |
|---------|------|--------|
| `id` | `UUID` PK | |
| `event_id` | `UUID` FK | |
| `remind_at` | timestamptz | |
| `channel` | `TEXT` | `in_app` (plus tard `push`, `email`) |
| `sent_at` | timestamptz NULL | |

### `notifications`

Centre d’alertes. Aligné `NotificationDTO`.

| Colonne | Type | Notes |
|---------|------|--------|
| `id` | `UUID` PK | |
| `organization_id` | `UUID` FK | |
| `user_id` | `TEXT` FK | destinataire |
| `title` / `message` | `TEXT` | |
| `notification_type` | `TEXT` | `info`, `warning`, `success`, `error`, `document`, `calendar`, `system` |
| `read_at` | timestamptz NULL | |
| `action_url` | `TEXT` NULL | |
| `metadata` | `JSONB` | `{}` par défaut |
| `created_at` | timestamptz | |
| `deleted_at` | timestamptz NULL | |

---

## Hors MVP (ne pas créer maintenant)

Documenté pour ne pas peindre dans un coin. Quand une table arrive, on **ajoute la FK** sur la colonne UUID déjà prévue.

| Domaine | Tables prévues | Accroches déjà dans le MVP |
|---------|----------------|----------------------------|
| Gouvernance avancée | `roles`, `permissions`, `role_permissions`, `org_nodes`, `sharing_requests` | le chart réel est `memberships.parent_id` + `invitations` |
| Messagerie | `mailboxes`, `emails`, `email_attachments` | `calendar_events.email_id` |
| Sync calendrier | `calendar_sources` (tokens OAuth, `provider`) | `calendar_events.source` ≠ `confidia` |
| Paiements | `payments` (`document_id`, `due_date`, `amount`, `status`) | `calendar_events.payment_id` |
| Signature | `signatures` (`document_id`, provider) | — |
| IA | `ai_analyses` (`document_id`, provider, payload JSON), `ai_conversations` | mock uniquement |
| Docs avancés | `categories`, `document_versions` | `documents.category` string |
| Conformité | `audit_logs` | timestamps + `created_by` |

---

## Index MVP

- `documents (organization_id, created_at DESC)` + `deleted_at` partiel (`WHERE deleted_at IS NULL`)
- `calendar_events (calendar_id, starts_at)` et `(organization_id, starts_at)`
- `notifications (user_id, created_at DESC)` où `deleted_at IS NULL`
- `memberships (user_id)` pour résoudre l’org courante
- `invitations (invitee_id)` pour les invitations reçues

---

## Seed de démo

Une org `Famille`, un user Keycloak `user`, membership `owner`, un calendrier `family`, quelques documents + événements `source = confidia`.  
Les événements Google/Outlook de la maquette restent **mock front** tant que `calendar_sources` n’existe pas.
