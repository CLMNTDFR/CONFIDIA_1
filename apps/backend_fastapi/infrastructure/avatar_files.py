from pathlib import Path

from core.config import get_settings
from core.uploads import inspect_avatar

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


def save_avatar(user_id: str, payload: bytes) -> str:
    mime = inspect_avatar(payload)
    suffix = _TYPES[mime]
    for old in existing_paths(user_id):
        old.unlink(missing_ok=True)
    dest = _root() / f"{_safe_user_id(user_id)}{suffix}"
    dest.write_bytes(payload)
    return AVATAR_API_PATH


def delete_avatar(user_id: str) -> None:
    for path in existing_paths(user_id):
        path.unlink(missing_ok=True)
