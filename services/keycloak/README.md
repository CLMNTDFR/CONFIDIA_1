# Keycloak Integration

Keycloak provides OAuth2 / OpenID Connect authentication for CONFIDIA.

## Configuration

- **URL**: http://localhost:8080
- **Realm**: confidia
- **Admin Console**: admin / admin

## Clients

| Client | Type | Purpose |
|--------|------|---------|
| confidia-frontend | Public | Present in the realm. The live app does not call it, and the API rejects its tokens |
| confidia-backend | Confidential | FastAPI service account. The API accepts an access token only when `azp` is this client |

## Test Users

| Username | Password | Roles |
|----------|----------|-------|
| admin | admin | ADMIN, USER |
| user | user | USER |
| manager | manager | MANAGER, USER |

## Realm Import

The realm is auto-imported from `realm-export.json` on first startup.

The API also checks `iss` (`http://localhost:8080/realms/confidia` from the host, `http://keycloak:8080/realms/confidia` inside Compose). Keycloak sets `aud` to `account`, so audience is not the filter. A token signed by the realm but issued for `confidia-frontend` is rejected.
