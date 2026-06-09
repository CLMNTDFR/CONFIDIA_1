# Guide de contribution CONFIDIA

## Prérequis développeur

- Flutter SDK stable
- Python 3.12+
- Docker & Docker Compose
- Compte GitHub

## Workflow

1. Fork le dépôt
2. Créer une branche : `git checkout -b feature/ma-fonctionnalite`
3. Développer en respectant l'architecture existante
4. Écrire/mettre à jour les tests
5. Vérifier le linting
6. Créer une Pull Request

## Standards de code

### Backend (Python)

- **Architecture** : respecter les couches api → application → domain → infrastructure
- **Linting** : `ruff check .`
- **Tests** : `pytest` (couverture minimale sur les services)
- **Nommage** : snake_case, type hints obligatoires
- **DTOs** : Pydantic v2 dans `application/dto/`
- **Interfaces** : ABC dans `domain/interfaces/`

### Frontend (Dart/Flutter)

- **État** : Riverpod uniquement (pas Provider classique)
- **Routing** : GoRouter déclaratif
- **Linting** : `flutter analyze`
- **Tests** : `flutter test`
- **Nommage** : camelCase (Dart), snake_case (fichiers)
- **Design** : utiliser le Design System (`core/theme/`)

## Structure des commits

```
type(scope): description courte

feat(documents): add full-text search filter
fix(auth): handle expired refresh token
docs(readme): update installation steps
test(backend): add calendar service tests
```

Types : `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `ci`

## Ajouter une intégration

1. Créer l'interface dans `domain/interfaces/`
2. Implémenter l'adaptateur dans `infrastructure/`
3. Enregistrer dans `core/di.py`
4. Créer le service dans `application/services/`
5. Exposer via `api/v1/`
6. Documenter dans `docs/Architecture.md`

## Ajouter un provider IA

```python
# infrastructure/ai/openai_provider.py
class OpenAIProvider(DocumentAIProvider):
    async def summarize(self, document_id, content) -> SummaryDTO:
        # Implémentation réelle
        ...
```

Puis dans `core/di.py` :
```python
ai_provider = providers.Singleton(OpenAIProvider, api_key=...)
```

## Tests

```bash
# Backend
cd apps/backend_fastapi && pytest -v

# Frontend
cd apps/frontend_flutter && flutter test
```

## CI

Chaque PR déclenche :
- `ruff check` (backend)
- `pytest` (backend)
- `flutter analyze` (frontend)
- `flutter test` (frontend)

## Questions

Ouvrir une issue GitHub avec le label approprié.
