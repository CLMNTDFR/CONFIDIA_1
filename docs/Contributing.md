# CONFIDIA contribution guide

## Developer prerequisites

- Flutter SDK stable
- Python 3.12+
- Docker & Docker Compose
- GitHub account

## Workflow

1. Fork the repository
2. Create a branch: `git checkout -b feature/my-feature`
3. Follow the existing architecture
4. Write or update tests
5. Check linting
6. Open a Pull Request

## Code standards

### Backend (Python)

- **Architecture**: respect the layers api → application → domain → infrastructure
- **Linting**: `ruff check .`
- **Tests**: `pytest` (minimum coverage on services)
- **Naming**: snake_case, type hints required
- **DTOs**: Pydantic v2 in `application/dto/`
- **Interfaces**: ABC in `domain/interfaces/`

### Frontend (Dart/Flutter)

- **State**: Riverpod only (no classic Provider)
- **Routing**: declarative GoRouter
- **Linting**: `flutter analyze`
- **Tests**: `flutter test`
- **Naming**: camelCase (Dart), snake_case (files)
- **Design**: use the Design System (`core/theme/`)

## Commit structure

```
type(scope): short description

feat(documents): add full-text search filter
fix(auth): handle expired refresh token
docs(readme): update installation steps
test(backend): add calendar service tests
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `ci`

## Adding an integration

1. Create the interface in `domain/interfaces/`
2. Implement the adapter in `infrastructure/`
3. Register a side integration (Paperless, Nextcloud, AI) in `core/di.py`. Document, calendar, and profile routes use FastAPI `Depends` in `api/deps.py` instead.
4. Create the service in `application/services/`
5. Expose it via `api/v1/`
6. Document it in `docs/Architecture.md`

## Adding an AI provider

```python
# infrastructure/ai/openai_provider.py
class OpenAIProvider(DocumentAIProvider):
    async def summarize(self, document_id, content) -> SummaryDTO:
        # Real implementation
        ...
```

Then in `core/di.py`:
```python
ai_provider = providers.Singleton(OpenAIProvider, api_key=...)
```

`api/v1/ai.py` currently constructs `MockAIProvider()` in the module. Point that route at the new provider as well.

## Tests

```bash
# Backend
cd apps/backend_fastapi && pytest -v

# Frontend
cd apps/frontend_flutter && flutter test
```

## CI

Each PR triggers:

- `ruff check` (backend): the job runs ruff but does not fail the workflow
- `pytest` (backend)
- `flutter analyze` (frontend)
- `flutter test` (frontend)
- `docker compose config` (Compose file validation)

## Questions

Open a GitHub issue with the appropriate label.
