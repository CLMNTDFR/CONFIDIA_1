# Holberton Webstack — Pitch CONFIDIA (préparation)

Projet solo · pitch max 10 min · slides en **anglais** (cursus Holberton) · docs de travail en français.

## MVP ultra-minimal (4 semaines / 27 jours)

### Dans le MVP (à livrer)

| Fonctionnalité | Pourquoi (RNCP 6 CDA) |
|----------------|------------------------|
| Auth (login / logout / session) | App sécurisée, gestion des accès |
| Profil utilisateur basique | Composant métier + persistance |
| Dashboard simple | Interface utilisateur, parcours clair |
| Documents : upload, liste, détail | Cœur métier démontrable de bout en bout |
| API REST FastAPI structurée en couches | Architecture en couches, accès données |
| PostgreSQL | BDD relationnelle |
| Docker Compose + README déploiement | DevOps / mise en production |
| Tests API (minimum) + CI légère | Plans de tests |
| Kanban + docs cadrage | Gestion de projet |

### Hors MVP (perspectives uniquement)

- Messagerie multi-comptes
- Sync calendriers Google / Outlook / Apple
- Paiements, signature électronique
- Organigramme / droits avancés
- IA réelle en production (un mock d’archi reste OK)
- Multi-tenant SaaS complet

### Alignement RNCP 37873 (CDA niveau 6)

1. **Développer une app sécurisée** — UI Flutter, composants métier, environnement projet, Kanban  
2. **Concevoir en couches** — besoin + maquettes, archi, PostgreSQL, accès données SQL  
3. **Déployer** — tests, doc de déploiement, Docker / CI (démarche DevOps)

### Planning résumé

- **S1** : cadrage, maquettes MVP, SQL, squelette API + auth  
- **S2** : documents end-to-end (API + Flutter)  
- **S3** : dashboard, sécu basique, tests, Docker  
- **S4** : polish, docs, CI, répétition démo + buffer  

---

## Prompt Canva IA (à coller tel quel)

```text
Tu es un designer de présentation pour un pitch étudiant Holberton School (Webstack specialization). Crée exactement 10 slides en ANGLAIS, style sobre et pro, fond sombre ou anthracite, accents bleu (pas de violet flashy, pas d’emojis, pas de stock photo kitsch). Typographie claire, beaucoup d’air, peu de texte par slide. Le projet s’appelle CONFIDIA. Pitch solo, max 10 minutes.

Contexte produit (à résumer, pas à tout coller) :
CONFIDIA is a digital hub for administrative life: centralize documents and key daily actions in one app. This portfolio delivery is a STRICT 4-week MVP only (not the full product vision).

Slide 1 — Title
Title: CONFIDIA
Subtitle: Portfolio Project Pitch — Holberton Webstack
Line: Solo project · Clément Defer
Small line: “A focused MVP in under 4 weeks”

Slide 2 — Team
Title: Team
Content: Solo builder — Clément Defer
Roles covered: product framing, UX mockups, backend, frontend, DevOps, demo
Note at bottom: Solo by choice to keep a tight scope and full ownership

Slide 3 — Problem
Title: The problem
3 short bullets max:
- Admin info is scattered (email, drives, calendars, paper scans)
- Easy to miss deadlines and lose documents
- People juggle too many tools for simple tasks
One-line insight: “People don’t need more apps. They need one calm place to act.”

Slide 4 — Solution / Project description
Title: What CONFIDIA is
Short paragraph (3–4 lines): CONFIDIA is a secure personal document hub with a simple dashboard. For this portfolio, the MVP lets a user sign in, upload a document, browse it, and open its details through a real API and database.
Callout box: Full vision later (calendar, messaging, AI). Not in this 4-week delivery.

Slide 5 — MVP scope
Title: MVP scope (what ships)
Two columns:
IN:
- Authentication
- Basic profile
- Simple dashboard
- Document upload / list / detail
- Layered REST API + PostgreSQL
- Docker Compose + docs
OUT:
- Multi-mailbox sync
- External calendar sync
- Payments / e-signature
- Production AI features
- Advanced access governance

Slide 6 — Learning objectives
Title: Learning objectives
5 short bullets:
- Design a secure full-stack application (not UI-only)
- Apply layered architecture (API / domain / infrastructure)
- Model and use a relational database
- Ship with Docker, tests, and basic CI
- Run a realistic solo plan with clear cut decisions

Slide 7 — Technologies
Title: Technologies
Groups:
Client: Flutter (web demo first), Riverpod, GoRouter
API: FastAPI, Python 3.12, layered architecture
Data: PostgreSQL
Auth: Keycloak (target) or FastAPI JWT (fallback)
Ops: Docker Compose, GitHub Actions
Quality: API tests, lint, deployment README

Slide 8 — Third-party services
Title: Third-party services
Primary (if time allows): Keycloak, optional Paperless-ngx / Nextcloud
Fallback plan: keep auth + storage simpler inside the API stack so the demo stays reliable
Footer note: Prefer a working end-to-end demo over half-integrated services

Slide 9 — Challenges + schedule
Title: Challenges & 27-day plan
Left — Challenges:
- Scope creep
- Auth taking longer than expected
- Docker multi-service complexity
- Keeping a stable demo
Right — Schedule:
Week 1: framing, mockups, DB, API skeleton + auth
Week 2: documents end-to-end
Week 3: dashboard, tests, Docker hardening
Week 4: polish, docs, CI, demo rehearsal + buffer
Small line: Detailed tasks tracked on a Kanban board (Trello)

Slide 10 — Closing
Title: Ready to build
Recap in 3 lines:
- Solo MVP with a strict scope
- Real stack: Flutter + FastAPI + PostgreSQL + Docker
- Demo goal: login → upload → list → open document
Final line: “Questions welcome.”
Speaker hint (tiny): keep total talk under 10 minutes, aim for 8.

Règles de design :
- Une idée forte par slide
- Pas de pavés
- Titres courts
- Cohérence visuelle sur les 10 slides
- Pas de tirets cadratins dans les textes
```

---

## Fichiers

| Fichier | Usage |
|---------|--------|
| [CONFIDIA_Pitch_Portfolio.docx](./CONFIDIA_Pitch_Portfolio.docx) | Fil conducteur oral (français, ton naturel) |
| [CONFIDIA_Pitch_Portfolio_EN.docx](./CONFIDIA_Pitch_Portfolio_EN.docx) | Même contenu, traduction pure en anglais |
| [KANBAN.md](./KANBAN.md) | Board 4 semaines (aligné pitch) |
| Ce README | MVP + prompt Canva |

Les slides Holberton doivent rester en **anglais**. Le DOCX est là pour préparer le discours sans ton “IA parfaite”.
