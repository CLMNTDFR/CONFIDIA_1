# Keycloak Integration

Keycloak provides OAuth2 / OpenID Connect authentication for CONFIDIA.

## Configuration

- **URL**: http://localhost:8080
- **Realm**: confidia
- **Admin Console**: admin / admin

## Clients

| Client | Type | Purpose |
|--------|------|---------|
| confidia-frontend | Public | Flutter app (PKCE) |
| confidia-backend | Confidential | FastAPI service account |

## Test Users

| Username | Password | Roles |
|----------|----------|-------|
| admin | admin | ADMIN, USER |
| user | user | USER |
| manager | manager | MANAGER, USER |

## Realm Import

The realm is auto-imported from `realm-export.json` on first startup.
