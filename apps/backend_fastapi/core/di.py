from dependency_injector import containers, providers

from core.config import Settings, get_settings
from infrastructure.ai.mock_ai_provider import MockAIProvider
from infrastructure.nextcloud.nextcloud_client import NextcloudStorageProvider
from infrastructure.paperless.paperless_client import PaperlessClient


class Container(containers.DeclarativeContainer):
    wiring_config = containers.WiringConfiguration(
        modules=[
            "api.v1.auth",
            "api.v1.documents",
            "api.v1.calendar",
            "api.v1.notifications",
            "api.v1.users",
            "api.v1.ai",
        ]
    )

    config = providers.Singleton(get_settings)

    paperless_client = providers.Singleton(
        PaperlessClient,
        base_url=providers.Callable(lambda s: s.paperless_url, config),
        token=providers.Callable(lambda s: s.paperless_token, config),
    )

    storage_provider = providers.Singleton(
        NextcloudStorageProvider,
        base_url=providers.Callable(lambda s: s.nextcloud_url, config),
        username=providers.Callable(lambda s: s.nextcloud_user, config),
        password=providers.Callable(lambda s: s.nextcloud_password, config),
    )

    ai_provider = providers.Singleton(MockAIProvider)


container = Container()
