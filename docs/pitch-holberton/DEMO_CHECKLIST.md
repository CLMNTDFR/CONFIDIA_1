# CONFIDIA live demo checklist

Holberton pitch path. About 3 minutes once the stack is up. UI labels stay in French; this script is in English.

Required beats: login, dashboard, import, detail, logout. Do not open screens marked Démo.

## Before you start

1. From the repo root, `./scripts/start.sh` has returned. It waits until both of these are HTTP 200:
   - http://localhost:8080/realms/confidia
   - http://localhost:8000/health
2. Flutter is on http://localhost:8082 (`flutter run -d chrome --web-port=8082`).
3. A small PDF is ready on the machine (any invoice-like file).
4. Sign-in account: `user` / `user`. Do not change that password.

If port 8000 is already taken, stop the other process. Do not start a second `uvicorn` next to `start.sh`.

## Required path

| # | Beat | What you do | What you should see |
|---|------|-------------|---------------------|
| 1 | Login | On the login screen, type `user` / `user` and press **Se connecter**. Do not press **Mode démo**. | The home screen **Accueil** (dashboard). The week strip is there. |
| 2 | Dashboard | Stay on **Accueil**. Point at the week overview. | A real home, not the login page. Live session starts empty of fake history. |
| 3 | Import | Open **Documents**. Press **Importer** (not **Scanner** on a laptop). **Choisir des fichiers**, pick the PDF, set a title, press **Importer**. | The file appears in the documents list. |
| 4 | Detail | Open that row. Press **Télécharger**. | The detail page shows the title. The download is the same file. |
| 5 | Logout | Open the profile chip (top bar) or **Paramètres**. Press **Se déconnecter**, then **Déconnexion**. | Back on the login screen. |

Say this out loud if useful: the file is stored by CONFIDIA (Postgres metadata + local disk), not by Paperless.

## If the jury asks "is it really saved?"

- Refresh the documents list. The file is still there.
- Optional: http://localhost:8000/docs shows the same API the app just called (`/auth/login`, `/documents/upload`, `/documents/{id}`).

## If something fails

| Symptom | Move |
|---------|------|
| Login spinner, then an error | Keycloak is not ready. Wait, then retry `curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/realms/confidia` until `200`. |
| Flutter cannot reach the API | Nothing is listening on port 8000, or a second API is. `./scripts/start.sh` owns 8000. |
| **Scanner** does nothing useful on a laptop | Use **Importer**. The camera path is for a phone. |
| You opened **Messagerie**, **Paiements**, or governance | Those screens wear a **Démo** badge. Go back to **Accueil** or **Documents**. They are not the live path. |

## Do not show

- **Mode démo** (mock data, no database).
- **Messagerie**, **Paiements**, advanced access control.
- Paperless (http://localhost:8001) and Nextcloud (http://localhost:8081). They may be up with the full stack. The Holberton document path does not use them.

## Only if time remains

- **Calendrier**: press **Événement**, create one event, then glance at **Accueil**. No Google, Outlook, or Apple sync.
- Profile: edit the phone, then refresh. The value comes back from PostgreSQL.

Rehearsal timing is a later step. This file is the path to follow, not the dry-run log.
