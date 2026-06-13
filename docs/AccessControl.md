# Gouvernance, rôles et droits d'accès

CONFIDIA permet à chaque utilisateur d'organiser son espace personnel **ou** de le partager avec un groupe (famille, association, club…) en définissant lui-même :

- l'**organigramme** (hiérarchie visuelle),
- les **rôles** de chaque membre,
- les **droits** granulaires (calendrier, documents sensibles, paiements…),
- les **demandes de partage** avec consentement explicite,
- un **assistant IA** pour résoudre les conflits de planning.

> **MVP démo** : l'interface et les données sont simulées côté Flutter (`MockAccessControl`). Les routes API existent côté backend et reflètent le même modèle pour une intégration future.

---

## Cas d'usage illustrés

### Famille partagée

Sophie (admin) partage son CONFIDIA avec Marc pour coordonner :

- calendriers des conjoints et des enfants,
- documents médicaux / scolaires,
- détection IA des **créneaux qui se chevauchent** ou des **trajets impossibles** (ex. récupération à l'école vs réunion professionnelle).

L'IA propose un réajustement en texte. L'utilisateur peut **accepter**, **refuser** ou envoyer un **prompt correctif** pour affiner la proposition.

### Club / association

Le directeur configure un organigramme (entraîneur, trésorier, secrétaire, licenciés…) et demande l'accès à des documents sensibles :

- pièces d'identité des licenciés,
- bulletins de salaire du staff.

Les personnes concernées reçoivent une **notification de consentement** et peuvent accepter ou refuser.

---

## Modèle de données

| Entité | Description |
|--------|-------------|
| `Organization` | Groupe (famille, club) avec scénario et nœuds hiérarchiques |
| `OrgNode` | Membre ou groupe dans l'organigramme (`parent_id` pour l'arbre) |
| `RoleTemplate` | Modèle de rôle (admin, directeur, parent, entraîneur…) avec niveau |
| `Permission` | Droit atomique (`calendar.read`, `documents.payslip`, …) |
| `Member` | Utilisateur rattaché à un nœud, avec liste de permissions |
| `SharingRequest` | Demande d'accès à un type de document, avec statut |
| `PlanningProposal` | Réponse IA : conflits + proposition + alternatives |

---

## API (`/api/v1/access-control`)

| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/scenarios` | Scénarios démo (famille, club) |
| `GET` | `/permissions` | Catalogue des permissions |
| `GET` | `/roles` | Modèles de rôles |
| `GET` | `/organization?scenario=` | Organigramme courant |
| `PUT` | `/organization` | Mettre à jour l'organigramme |
| `GET` | `/members?scenario=` | Membres et droits |
| `PATCH` | `/members/{id}` | Modifier rôle / permissions |
| `GET` | `/sharing-requests` | Demandes de partage |
| `POST` | `/sharing-requests` | Créer une demande (ADMIN/MANAGER) |
| `POST` | `/sharing-requests/{id}/respond` | Accepter / refuser |
| `POST` | `/ai/planning-analyze` | Analyse IA des conflits calendrier |
| `POST` | `/ai/planning-refine` | Affiner la proposition avec un prompt |

Toutes les routes requièrent un JWT valide (sauf documentation Swagger).

**Fichiers backend :**

- `apps/backend_fastapi/api/v1/access_control.py`
- `apps/backend_fastapi/application/services/access_control_service.py`
- `apps/backend_fastapi/application/dto/access_control_dto.py`

---

## Frontend

| Route | Écran |
|-------|-------|
| `/access-control` | Hub à 4 onglets : Organigramme, Membres & droits, Demandes, IA Planning |

**Accès :** Paramètres → *Gouvernance & accès*, ou Administration → carte dédiée.

**Fichiers :**

- `lib/features/access_control/access_control_screen.dart`
- `lib/features/access_control/access_control_provider.dart`
- `lib/features/access_control/widgets/org_chart_widget.dart`
- `lib/shared/data/mock_access_control.dart`
- `lib/shared/models/access_control_models.dart`

### Organigramme interactif

- Affichage en arbre avec indentation visuelle.
- **Glisser-déposer** : maintenir un nœud puis le déposer sur un autre pour changer le rattachement hiérarchique (`parent_id`).

### Droits granulaires

Chaque membre dispose d'une liste de permissions activables via des chips. Les permissions sont groupées par catégorie (Calendrier, Documents, Paiements, Organisation).

---

## Évolutions prévues

- Persistance en base (PostgreSQL) des organisations et consentements
- Synchronisation temps réel des demandes de partage → notifications push
- Moteur IA réel branché sur le calendrier fusionné et les APIs de géolocalisation / temps de trajet
- Héritage automatique des droits selon la position dans l'organigramme
