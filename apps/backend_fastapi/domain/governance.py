"""Rules for one workspace: chart, rights, invitations.

Permission ids match the Flutter catalog in mock_access_control.dart.
Document and calendar lists stay organisation-wide. These flags are stored
and gate who may invite or rearrange the chart.
"""

from uuid import UUID

PERMISSIONS: tuple[str, ...] = (
    "calendar.read",
    "calendar.write",
    "documents.read",
    "documents.id_card",
    "documents.payslip",
    "documents.medical",
    "payments.read",
    "payments.write",
    "members.manage",
    "hierarchy.edit",
)

MEMBER_PERMISSIONS: tuple[str, ...] = ("calendar.read", "documents.read")

ICONS = frozenset(
    {
        "apartment",
        "business",
        "family",
        "groups",
        "diversity",
        "soccer",
        "school",
        "volunteer",
        "church",
        "hospital",
        "account",
        "handshake",
        "home",
        "hiking",
        "theater",
        "pets",
        "people",
        "premium",
        "hub",
        "interests",
        "castle",
        "forest",
        "music",
        "science",
    }
)

KINDS = frozenset({"personal", "family", "club", "org"})
LINK_TYPES = frozenset({"reportsTo", "dottedLine", "delegate"})
ASSIGNABLE_ROLES = frozenset({"admin", "member"})


class GovernanceError(Exception):
    def __init__(self, status_code: int, detail: str) -> None:
        self.status_code = status_code
        self.detail = detail
        super().__init__(detail)


def clean_permissions(values: list[str]) -> list[str]:
    seen: list[str] = []
    for item in values:
        if item in PERMISSIONS and item not in seen:
            seen.append(item)
    return seen


def displayed_permissions(role: str, stored: list[str]) -> list[str]:
    if role == "owner" and not stored:
        return list(PERMISSIONS)
    return list(stored)


def clean_level_labels(raw: dict[str, str]) -> dict[str, str]:
    cleaned: dict[str, str] = {}
    for key, value in raw.items():
        if not str(key).isdigit():
            continue
        depth = int(key)
        if depth < 0 or depth > 12:
            continue
        label = str(value).strip()
        if not label:
            continue
        cleaned[str(depth)] = label[:40]
    return cleaned


def would_cycle(parent_of: dict[UUID, UUID | None], node_id: UUID, new_parent: UUID | None) -> bool:
    if new_parent is None:
        return False
    cursor: UUID | None = new_parent
    seen: set[UUID] = set()
    while cursor is not None:
        if cursor == node_id or cursor in seen:
            return True
        seen.add(cursor)
        cursor = parent_of.get(cursor)
    return False
