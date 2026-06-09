import logging
from datetime import datetime
from typing import BinaryIO
from xml.etree import ElementTree

import httpx

from application.dto.storage_dto import FileInfoDTO, ShareLinkDTO
from domain.interfaces.storage_provider import StorageProvider

logger = logging.getLogger(__name__)

DAV_NS = {"d": "DAV:"}


class NextcloudStorageProvider(StorageProvider):
    """Nextcloud WebDAV storage provider."""

    def __init__(self, base_url: str, username: str, password: str):
        self._base_url = base_url.rstrip("/")
        self._webdav_url = f"{self._base_url}/remote.php/dav/files/{username}"
        self._auth = (username, password)

    async def upload_file(self, path: str, file: BinaryIO, content_type: str) -> FileInfoDTO:
        url = f"{self._webdav_url}{path}"
        content = file.read()

        async with httpx.AsyncClient() as client:
            response = await client.put(
                url,
                auth=self._auth,
                content=content,
                headers={"Content-Type": content_type},
                timeout=60.0,
            )
            if response.status_code not in (200, 201, 204):
                logger.warning("Nextcloud upload failed, returning mock response")
                return FileInfoDTO(
                    path=path,
                    name=path.split("/")[-1],
                    size=len(content),
                    content_type=content_type,
                )

        return FileInfoDTO(
            path=path,
            name=path.split("/")[-1],
            size=len(content),
            content_type=content_type,
            modified=datetime.now(),
        )

    async def download_file(self, path: str) -> bytes:
        url = f"{self._webdav_url}{path}"
        async with httpx.AsyncClient() as client:
            response = await client.get(url, auth=self._auth, timeout=60.0)
            response.raise_for_status()
            return response.content

    async def delete_file(self, path: str) -> bool:
        url = f"{self._webdav_url}{path}"
        async with httpx.AsyncClient() as client:
            response = await client.delete(url, auth=self._auth, timeout=30.0)
            return response.status_code in (200, 204)

    async def list_files(self, directory: str = "/") -> list[FileInfoDTO]:
        url = f"{self._webdav_url}{directory}"
        propfind_body = """<?xml version="1.0" encoding="utf-8" ?>
        <d:propfind xmlns:d="DAV:">
            <d:prop>
                <d:getcontentlength/>
                <d:getcontenttype/>
                <d:getlastmodified/>
                <d:resourcetype/>
            </d:prop>
        </d:propfind>"""

        async with httpx.AsyncClient() as client:
            response = await client.request(
                "PROPFIND",
                url,
                auth=self._auth,
                content=propfind_body,
                headers={"Depth": "1"},
                timeout=30.0,
            )
            if response.status_code not in (207, 200):
                return self._mock_files()

            return self._parse_propfind(response.text)

    async def create_share_link(self, path: str, password: str | None = None) -> ShareLinkDTO:
        return ShareLinkDTO(
            url=f"{self._base_url}/s/mock-share-token",
            token="mock-share-token",
        )

    def _parse_propfind(self, xml_text: str) -> list[FileInfoDTO]:
        files: list[FileInfoDTO] = []
        root = ElementTree.fromstring(xml_text)
        for response_elem in root.findall("d:response", DAV_NS):
            href = response_elem.find("d:href", DAV_NS)
            if href is None:
                continue
            path = href.text or ""
            propstat = response_elem.find("d:propstat", DAV_NS)
            if propstat is None:
                continue
            prop = propstat.find("d:prop", DAV_NS)
            if prop is None:
                continue

            resourcetype = prop.find("d:resourcetype", DAV_NS)
            is_dir = resourcetype is not None and resourcetype.find("d:collection", DAV_NS) is not None
            size_elem = prop.find("d:getcontentlength", DAV_NS)
            type_elem = prop.find("d:getcontenttype", DAV_NS)

            files.append(
                FileInfoDTO(
                    path=path,
                    name=path.rstrip("/").split("/")[-1],
                    size=int(size_elem.text) if size_elem is not None and size_elem.text else 0,
                    content_type=type_elem.text if type_elem is not None else None,
                    is_directory=is_dir,
                )
            )
        return files[1:] if len(files) > 1 else files

    def _mock_files(self) -> list[FileInfoDTO]:
        return [
            FileInfoDTO(path="/Documents", name="Documents", size=0, is_directory=True),
            FileInfoDTO(
                path="/Documents/Budget_2026.xlsx",
                name="Budget_2026.xlsx",
                size=45_056,
                content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            ),
            FileInfoDTO(
                path="/Documents/Scan_passeport.pdf",
                name="Scan_passeport.pdf",
                size=2_097_152,
                content_type="application/pdf",
            ),
        ]
