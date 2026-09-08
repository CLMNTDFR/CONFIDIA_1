from pathlib import Path

from core.config import get_settings

MAX_AVATAR_BYTES = 2 * 1024 * 1024
AVATAR_API_PATH = "/api/v1/users/me/avatar"
_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}


def _safe_user_id(user_id: str) -> str:
    return "".join(ch if ch.isalnum() or ch in "-_" else "_" for ch in user_id)


def _root() -> Path:
    path = Path(get_settings().documents_storage_dir) / "avatars"
    path.mkdir(parents=True, exist_ok=True)
    return path


def existing_paths(user_id: str) -> list[Path]:
    return list(_root().glob(f"{_safe_user_id(user_id)}.*"))


def read_avatar(user_id: str) -> tuple[bytes, str] | None:
    paths = existing_paths(user_id)
    if not paths:
        return None
    path = paths[0]
    suffix = path.suffix.lower()
    mime = next((m for m, ext in _TYPES.items() if ext == suffix), "application/octet-stream")
    return path.read_bytes(), mime


def save_avatar(user_id: str, payload: bytes, content_type: str, filename: str = "") -> str:
    mime = (content_type or "").split(";")[0].strip().lower()
    suffix = _TYPES.get(mime)
    if suffix is None:
        lower = filename.lower()
        if lower.endswith(".png"):
            suffix = ".png"
        elif lower.endswith(".webp"):
            suffix = ".webp"
        elif lower.endswith(".jpg") or lower.endswith(".jpeg"):
            suffix = ".jpg"
    if suffix is None:
        raise ValueError("Format d'image non pris en charge (jpeg, png ou webp)")
    if len(payload) > MAX_AVATAR_BYTES:
        raise ValueError("L'image est trop lourde (maximum 2 Mo)")
    for old in existing_paths(user_id):
        old.unlink(missing_ok=True)
    dest = _root() / f"{_safe_user_id(user_id)}{suffix}"
    dest.write_bytes(payload)
    return AVATAR_API_PATH


def delete_avatar(user_id: str) -> None:
    for path in existing_paths(user_id):
        path.unlink(missing_ok=True)
