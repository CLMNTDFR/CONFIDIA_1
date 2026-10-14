# Roadmap CONFIDIA

## v0.1.0: MVP (current)

- [x] Monorepo architecture
- [x] Keycloak authentication (OAuth2/OIDC)
- [x] FastAPI API (Clean Architecture)
- [x] Paperless-ngx integration (with mock fallback)
- [x] Nextcloud integration (WebDAV)
- [x] Cross-platform Flutter application
- [x] Complete Design System (dark/light)
- [x] Dashboard, Documents, Calendar, Notifications
- [x] MockAIProvider (AI architecture)
- [x] Docker Compose one-command
- [x] CI/CD GitHub Actions
- [x] Documentation

## v0.2.0: Real integrations

- [ ] Paperless connection with production API token
- [ ] CalDAV calendar sync (Nextcloud)
- [ ] Push notifications (FCM/APNs)
- [ ] Desktop drag & drop upload
- [ ] Advanced full-text search
- [ ] Persistent user profile (DB)

## v0.3.0: Artificial intelligence

- [ ] `OpenAIProvider` (GPT-4)
- [ ] `ClaudeProvider` (Anthropic)
- [ ] `MistralProvider`
- [ ] `LocalLLMProvider` (Ollama)
- [ ] Advanced OCR (Tesseract + AI)
- [ ] Automatic document classification
- [ ] Smart extraction (dates, amounts, entities)

## v0.4.0: Identity & compliance

- [ ] Advanced digital identity (France Identité)
- [ ] Electronic signature (DocuSign / Yousign)
- [ ] GDPR compliance (export, deletion)
- [ ] Full audit trail
- [ ] End-to-end encryption

## v0.5.0: Financial services

- [ ] Bill payment
- [ ] Bank reconciliation
- [ ] Budget alerts
- [ ] Financial dashboard

## v1.0.0: Production

- [ ] Multi-tenant SaaS
- [ ] Billing (Stripe)
- [ ] User onboarding
- [ ] Monitoring (Datadog/Prometheus)
- [ ] High availability
- [ ] App Store / Play Store

## Guiding principles

1. **Do not reinvent**: orchestrate what already exists
2. **Abstraction**: every service is replaceable
3. **Security**: Flutter never touches services directly
4. **Scalability**: Clean Architecture, interfaces, DI
5. **Quality**: tests, linting, CI on every commit
