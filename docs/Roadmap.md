# Roadmap CONFIDIA

## v0.1.0 — MVP (actuel)

- [x] Architecture monorepo
- [x] Authentification Keycloak (OAuth2/OIDC)
- [x] API FastAPI (Clean Architecture)
- [x] Intégration Paperless-ngx (avec fallback mock)
- [x] Intégration Nextcloud (WebDAV)
- [x] Application Flutter multiplateforme
- [x] Design System complet (dark/light)
- [x] Dashboard, Documents, Calendrier, Notifications
- [x] MockAIProvider (architecture IA)
- [x] Docker Compose one-command
- [x] CI/CD GitHub Actions
- [x] Documentation

## v0.2.0 — Intégrations réelles

- [ ] Connexion Paperless avec token API en production
- [ ] Synchronisation calendrier CalDAV (Nextcloud)
- [ ] Notifications push (FCM/APNs)
- [ ] Upload drag & drop desktop
- [ ] Recherche full-text avancée
- [ ] Profil utilisateur persistant (DB)

## v0.3.0 — Intelligence artificielle

- [ ] `OpenAIProvider` (GPT-4)
- [ ] `ClaudeProvider` (Anthropic)
- [ ] `MistralProvider`
- [ ] `LocalLLMProvider` (Ollama)
- [ ] OCR avancé (Tesseract + IA)
- [ ] Classification automatique des documents
- [ ] Extraction intelligente (dates, montants, entités)

## v0.4.0 — Identité & conformité

- [ ] Identité numérique avancée (France Identité)
- [ ] Signature électronique (DocuSign / Yousign)
- [ ] Conformité RGPD (export, suppression)
- [ ] Audit trail complet
- [ ] Chiffrement bout-en-bout

## v0.5.0 — Services financiers

- [ ] Paiement de factures
- [ ] Rapprochement bancaire
- [ ] Alertes budgétaires
- [ ] Tableau de bord financier

## v1.0.0 — Production

- [ ] Multi-tenant SaaS
- [ ] Facturation (Stripe)
- [ ] Onboarding utilisateur
- [ ] Monitoring (Datadog/Prometheus)
- [ ] Haute disponibilité
- [ ] App Store / Play Store

## Principes directeurs

1. **Ne pas réinventer** — orchestrer l'existant
2. **Abstraction** — chaque service est remplaçable
3. **Sécurité** — Flutter ne touche jamais aux services directement
4. **Évolutivité** — Clean Architecture, interfaces, DI
5. **Qualité** — tests, linting, CI à chaque commit
