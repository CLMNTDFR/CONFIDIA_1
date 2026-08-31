# CONFIDIA — Kanban (4 weeks)

Solo · Holberton Webstack portfolio · **27 days**  
Board principle: one visible deliverable per week. Scope locked to the pitch MVP.

**MVP in:** auth · dashboard · merged calendar · documents (upload / list / detail) · layered API · PostgreSQL · Docker docs  
**MVP out:** multi-mailbox · third-party calendar sync · payments · e-signature · advanced org chart · production AI

Status legend: `[ ]` To do · `[~]` Doing · `[x]` Done  
In the tables, tick the matching status column when you move a card.

---

## Backlog (out of MVP — do not pull in)

| Card | Description | Note |
|------|-------------|------|
| Multi-mailbox sync | Connect several email providers and sync messages | Perspective only |
| Google / Outlook / Apple calendar sync | Live sync with external calendar accounts | Perspective only |
| Payments | Pay invoices from inside the app | Perspective only |
| E-signature | Sign documents digitally in-app | Perspective only |
| Advanced org chart | Roles, hierarchy and fine-grained access for orgs | Perspective only |
| Real AI in production | Live LLM analysis / chat in production | Mock OK for architecture illustration only |

---

## Week 1 — Framing & foundations

**Weekly deliverable:** project framed, Kanban live, API skeleton + auth started, SQL schema ready.

| Card | Description | To do | Doing | Done |
|------|-------------|:-----:|:-----:|:----:|
| Final framing | Lock the MVP in writing so scope cannot drift | [ ] | | |
| MVP mockups | Screen mockups for in-scope flows only | [ ] | | |
| SQL schema | Tables for users, documents and core relations | [ ] | | |
| API skeleton | Layered FastAPI project ready to receive routes | [ ] | | |
| Auth skeleton | Login/session path via Keycloak **or** FastAPI JWT (plan B) | [ ] | | |
| Kanban board ready | This board usable and shared as the week plan | [ ] | | |

```
[ ] Final framing — lock MVP in writing
[ ] MVP mockups — in-scope screens only
[ ] SQL schema — users, documents, core links
[ ] API skeleton — layered FastAPI
[ ] Auth skeleton — Keycloak or JWT plan B
[ ] Kanban board ready
```

---

## Week 2 — Documents end-to-end

**Weekly deliverable:** upload / list / detail works through API + Flutter.

| Card | Description | To do | Doing | Done |
|------|-------------|:-----:|:-----:|:----:|
| Document endpoints | REST routes to create, list and fetch documents | [ ] | | |
| Profile endpoints | REST routes to read/update the user profile | [ ] | | |
| Front ↔ API connection | Wire Flutter client to the real API base URL | [ ] | | |
| Upload | User can send a file and it is stored/persisted | [ ] | | |
| List | User can see their documents in a list screen | [ ] | | |
| Detail | User can open one document and see its page | [ ] | | |

```
[ ] Document endpoints — create / list / fetch
[ ] Profile endpoints — read / update profile
[ ] Front connection — Flutter talks to the API
[ ] Upload — file send + persist
[ ] List — documents list screen
[ ] Detail — document detail screen
```

---

## Week 3 — Dashboard, calendar, harden, share

**Weekly deliverable:** minimal dashboard + merged calendar usable; tests; Docker Compose that someone else can run; demo checklist started.

| Card | Description | To do | Doing | Done |
|------|-------------|:-----:|:-----:|:----:|
| Minimal dashboard | Home screen with the main entry points for the demo | [ ] | | |
| Merged calendar (MVP) | Single in-app calendar view (no third-party sync) | [ ] | | |
| Basic security hardening | Tighten auth checks, secrets handling, obvious gaps | [ ] | | |
| Tests | Cover critical API paths with useful automated tests | [ ] | | |
| Docker Compose (third-party usable) | One-command stack that another person can start | [ ] | | |
| Demo checklist | Written path for the live demo, started this week | [ ] | | |

```
[ ] Minimal dashboard — demo home entry points
[ ] Merged calendar (MVP) — in-app only, no external sync
[ ] Basic security hardening — auth / secrets / gaps
[ ] Tests — critical API paths
[ ] Docker Compose — usable by someone else
[ ] Demo checklist — live demo path written
```

---

## Week 4 — Polish, ship, rehearse

**Weekly deliverable:** stable demo path; docs; CI; buffer used only for blockers.

| Card | Description | To do | Doing | Done |
|------|-------------|:-----:|:-----:|:----:|
| UI polish | Clean only MVP screens; no new features | [ ] | | |
| Documentation | README + deploy steps clear enough for a reviewer | [ ] | | |
| CI | Minimal GitHub Actions pipeline (lint/tests) | [ ] | | |
| Demo rehearsal | Full dry-run of the demo checklist, timed | [ ] | | |
| Buffer | Spare time for blockers only, not scope creep | [ ] | | |

```
[ ] UI polish — MVP screens only
[ ] Documentation — README + deploy
[ ] CI — minimal GitHub Actions
[ ] Demo rehearsal — timed dry-run
[ ] Buffer — blockers only
```

---

## Demo checklist (must work)

From the pitch — keep this list green before pitching day:

| Step | Description | Done |
|------|-------------|:----:|
| Account creation / login | Create an account or sign in successfully | [ ] |
| Open dashboard | Land on the home/dashboard after login | [ ] |
| Import a document | Upload a file from the UI | [ ] |
| Open document detail | Open the uploaded document page | [ ] |
| Logout | End the session cleanly | [ ] |
| API responds | Backend answers the demo calls | [ ] |
| Database persists | Data still there after refresh/restart | [ ] |
| Docker starts what is needed | Required services come up via Compose | [ ] |

Optional (only if time; clearly **out of MVP**):

| Step | Description | Done |
|------|-------------|:----:|
| “What’s next” peek | Short calendar polish / AI mock, labeled out of MVP | [ ] |

---

## How to use this board

1. Move cards week by week; don’t steal Week 4 polish into Week 1.
2. If a card grows: cut scope, don’t stretch the week.
3. Auth/storage stuck → switch to the written plan B, don’t burn the sprint.
4. Update checkboxes as you go (`[ ]` → `[~]` → `[x]`).
