from abc import ABC, abstractmethod
from typing import BinaryIO

from application.dto.storage_dto import FileInfoDTO, ShareLinkDTO


class StorageProvider(ABC):
    """Abstraction layer for file storage backends (Nextcloud, S3, etc.)."""

    @abstractmethod
    async def upload_file(self, path: str, file: BinaryIO, content_type: str) -> FileInfoDTO:
        ...

    @abstractmethod
    async def download_file(self, path: str) -> bytes:
        ...

    @abstractmethod
    async def delete_file(self, path: str) -> bool:
        ...

    @abstractmethod
    async def list_files(self, directory: str = "/") -> list[FileInfoDTO]:
        ...

    @abstractmethod
    async def create_share_link(self, path: str, password: str | None = None) -> ShareLinkDTO:
        ...
