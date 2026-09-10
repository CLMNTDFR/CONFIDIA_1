"""Limites et sniffing des fichiers utilisateur."""

from pathlib import Path

MAX_DOCUMENT_BYTES = 15 * 1024 * 1024
MAX_AVATAR_BYTES = 2 * 1024 * 1024
DOCUMENT_TOO_LARGE = "Fichier trop volumineux (15 Mo maximum)"
AVATAR_TOO_LARGE = "L'image est trop lourde (maximum 2 Mo)"

_PDF = "application/pdf"
_PNG = "image/png"
_JPEG = "image/jpeg"
_WEBP = "image/webp"
_DOC = "application/msword"
_DOCX = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
_XLSX = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

_INLINE_MIME = {_PDF, _PNG, _JPEG, _WEBP}


def sniff_mime(payload: bytes) -> str | None:
    if payload.startswith(b"%PDF"):
        return _PDF
    if payload.startswith(b"\x89PNG\r\n\x1a\n"):
        return _PNG
    if payload.startswith(b"\xff\xd8\xff"):
        return _JPEG
    if len(payload) >= 12 and payload.startswith(b"RIFF") and payload[8:12] == b"WEBP":
        return _WEBP
    if payload.startswith(b"\xd0\xcf\x11\xe0"):
        return _DOC
    if payload.startswith(b"PK"):
        return "zip"
    return None


def inspect_document(filename: str, payload: bytes) -> str:
    if not payload:
        raise ValueError("Fichier vide")
    if len(payload) > MAX_DOCUMENT_BYTES:
        raise ValueError(DOCUMENT_TOO_LARGE)
    sniffed = sniff_mime(payload)
    suffix = Path(filename or "document").suffix.lower()
    if sniffed == _PDF:
        return _PDF
    if sniffed in {_PNG, _JPEG, _WEBP, _DOC}:
        return sniffed
    if sniffed == "zip" and suffix == ".docx":
        return _DOCX
    if sniffed == "zip" and suffix == ".xlsx":
        return _XLSX
    raise ValueError("Type de fichier non autorisé")


def inspect_avatar(payload: bytes) -> str:
    if not payload:
        raise ValueError("Fichier vide")
    if len(payload) > MAX_AVATAR_BYTES:
        raise ValueError(AVATAR_TOO_LARGE)
    sniffed = sniff_mime(payload)
    if sniffed in {_PNG, _JPEG, _WEBP}:
        return sniffed
    raise ValueError("Format d'image non pris en charge (jpeg, png ou webp)")


def suffix_for_mime(mime: str, filename: str) -> str:
    mapping = {
        _PDF: ".pdf",
        _PNG: ".png",
        _JPEG: ".jpg",
        _WEBP: ".webp",
        _DOC: ".doc",
        _DOCX: ".docx",
        _XLSX: ".xlsx",
    }
    if mime in mapping:
        return mapping[mime]
    suffix = Path(filename or "document").suffix.lower()[:12]
    return suffix if suffix.startswith(".") else ""


def download_disposition(mime_type: str) -> str:
    return "inline" if mime_type in _INLINE_MIME else "attachment"


def upload_error_status(message: str) -> int:
    if "volumineux" in message or "trop lourde" in message:
        return 413
    if "vide" in message:
        return 400
    return 415


async def read_limited(file, max_bytes: int, *, too_large: str) -> bytes:
    payload = await file.read(max_bytes + 1)
    if len(payload) > max_bytes:
        raise ValueError(too_large)
    return payload
