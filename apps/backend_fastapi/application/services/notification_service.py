from datetime import datetime, timedelta

from application.dto.notification_dto import (
    NotificationDTO,
    NotificationListResponse,
    NotificationType,
)


class NotificationService:
    """Notification service with mock data. Ready for push/webhook integration."""

    def __init__(self):
        self._notifications = self._generate_mock_notifications()

    def _generate_mock_notifications(self) -> list[NotificationDTO]:
        now = datetime.now()
        return [
            NotificationDTO(
                id="notif-001",
                title="Document classé",
                message="Votre facture EDF a été automatiquement classée en 'Énergie'.",
                notification_type=NotificationType.DOCUMENT,
                read=False,
                created_at=now - timedelta(minutes=15),
                action_url="/documents/1",
            ),
            NotificationDTO(
                id="notif-002",
                title="Échéance proche",
                message="L'assurance habitation expire dans 3 jours.",
                notification_type=NotificationType.WARNING,
                read=False,
                created_at=now - timedelta(hours=2),
                action_url="/calendar",
            ),
            NotificationDTO(
                id="notif-003",
                title="Upload réussi",
                message="Le document 'Attestation employeur.pdf' a été uploadé.",
                notification_type=NotificationType.SUCCESS,
                read=True,
                created_at=now - timedelta(hours=5),
                action_url="/documents/4",
            ),
            NotificationDTO(
                id="notif-004",
                title="Nouveau document partagé",
                message="Marie Martin a partagé 'Budget 2026.xlsx' avec vous.",
                notification_type=NotificationType.INFO,
                read=True,
                created_at=now - timedelta(days=1),
            ),
            NotificationDTO(
                id="notif-005",
                title="Mise à jour système",
                message="CONFIDIA v0.1.0 est disponible avec de nouvelles fonctionnalités.",
                notification_type=NotificationType.SYSTEM,
                read=True,
                created_at=now - timedelta(days=2),
            ),
            NotificationDTO(
                id="notif-006",
                title="Rappel calendrier",
                message="Rendez-vous médecin demain à 10h00.",
                notification_type=NotificationType.CALENDAR,
                read=False,
                created_at=now - timedelta(hours=8),
                action_url="/calendar",
            ),
        ]

    async def list_notifications(self, unread_only: bool = False) -> NotificationListResponse:
        items = self._notifications
        if unread_only:
            items = [n for n in items if not n.read]
        unread_count = sum(1 for n in self._notifications if not n.read)
        return NotificationListResponse(
            items=items, total=len(items), unread_count=unread_count
        )

    async def mark_as_read(self, notification_id: str) -> NotificationDTO | None:
        for notif in self._notifications:
            if notif.id == notification_id:
                notif.read = True
                return notif
        return None

    async def mark_all_as_read(self) -> int:
        count = 0
        for notif in self._notifications:
            if not notif.read:
                notif.read = True
                count += 1
        return count
