import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/glass_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationModel> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = List.from(MockData.notifications);
  }

  void _markAllRead() {
    setState(() {
      _notifications = _notifications.map((n) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          read: true,
          createdAt: n.createdAt,
          actionUrl: n.actionUrl,
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.read).length;

    return Column(
      children: [
        if (unread > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(ConfidiaSpacing.lg, ConfidiaSpacing.md, ConfidiaSpacing.lg, ConfidiaSpacing.sm),
            child: Align(
              alignment: Alignment.centerRight,
              child: ConfidiaGlowButton(
                label: 'Tout marquer comme lu',
                icon: Icons.done_all_rounded,
                primary: false,
                onPressed: _markAllRead,
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(ConfidiaSpacing.lg),
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notif = _notifications[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
                child: GlassCard(
                  highlighted: !notif.read,
                  padding: EdgeInsets.zero,
                  child: _NotificationTile(
                    notification: notif,
                    onTap: () {
                      setState(() {
                        _notifications[index] = NotificationModel(
                          id: notif.id,
                          title: notif.title,
                          message: notif.message,
                          type: notif.type,
                          read: true,
                          createdAt: notif.createdAt,
                          actionUrl: notif.actionUrl,
                        );
                      });
                      if (notif.actionUrl != null) context.go(notif.actionUrl!);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _colorForType(notification.type).withValues(alpha: 0.15),
          child: Icon(_iconForType(notification.type), color: _colorForType(notification.type), size: 20),
        ),
        title: Text(
          notification.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: notification.read ? FontWeight.w500 : FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _timeAgo(notification.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: notification.read
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ConfidiaColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
    );
  }

  Color _colorForType(NotificationType type) {
    return switch (type) {
      NotificationType.warning => ConfidiaColors.warning,
      NotificationType.success => ConfidiaColors.success,
      NotificationType.error => ConfidiaColors.error,
      NotificationType.document => ConfidiaColors.primary,
      NotificationType.calendar => ConfidiaColors.accent,
      _ => ConfidiaColors.info,
    };
  }

  IconData _iconForType(NotificationType type) {
    return switch (type) {
      NotificationType.warning => Icons.warning_amber,
      NotificationType.success => Icons.check_circle_outline,
      NotificationType.error => Icons.error_outline,
      NotificationType.document => Icons.description_outlined,
      NotificationType.calendar => Icons.calendar_month_outlined,
      NotificationType.system => Icons.system_update_outlined,
      _ => Icons.info_outline,
    };
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return DateFormat('d MMM yyyy', 'fr_FR').format(date);
  }
}
