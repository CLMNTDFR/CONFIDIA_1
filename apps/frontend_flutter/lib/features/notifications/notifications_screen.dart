import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_page_reveal.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/mobile_shell_insets.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConfidiaPageReveal(
          index: 0,
          staggerCount: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(ConfidiaSpacing.lg, ConfidiaSpacing.sm, ConfidiaSpacing.lg, ConfidiaSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    unread > 0
                        ? '$unread notification${unread > 1 ? 's' : ''} non lue${unread > 1 ? 's' : ''}'
                        : 'Tout est à jour',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ConfidiaColors.textSecondary(isDark),
                          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                        ),
                  ),
                ),
                if (unread > 0) ...[
                  const SizedBox(width: ConfidiaSpacing.sm),
                  ConfidiaGlowButton(
                    label: 'Tout marquer comme lu',
                    icon: Icons.done_all_rounded,
                    primary: false,
                    onPressed: _markAllRead,
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
                padding: ConfidiaInsets.page(context).copyWith(top: ConfidiaSpacing.xs),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  final stagger = ConfidiaPageRevealTiming.staggerCount(
                    context,
                    _notifications.length,
                    itemExtent: 108,
                    overhead: 300,
                  );
                  return ConfidiaPageReveal(
                    index: index,
                    staggerCount: stagger,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
                      child: _NotificationCard(
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

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;
    final accent = _colorForType(notification.type, palette);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusLg),
        child: Stack(
          children: [
            if (!notification.read)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusLg),
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: isDark ? 0.08 : 0.05),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            GlassCard(
              highlighted: !notification.read,
              clipContent: false,
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: accent.withValues(alpha: 0.2)),
                        ),
                        child: Icon(_iconForType(notification.type), color: accent, size: 20),
                      ),
                      if (!notification.read)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: context.palette.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? ConfidiaColors.darkSurfaceElevated : Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _TypePill(type: notification.type, color: accent),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.message,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ConfidiaColors.textSecondary(isDark),
                                height: 1.45,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _timeAgo(notification.createdAt),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: ConfidiaColors.textSecondary(isDark).withValues(alpha: 0.85),
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (notification.actionUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 10),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: ConfidiaColors.textSecondary(isDark).withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForType(NotificationType type, ConfidiaPalette palette) {
    return switch (type) {
      NotificationType.warning => ConfidiaColors.warning,
      NotificationType.success => ConfidiaColors.success,
      NotificationType.error => ConfidiaColors.error,
      NotificationType.document => palette.primary,
      NotificationType.calendar => palette.accent,
      _ => ConfidiaColors.info,
    };
  }

  IconData _iconForType(NotificationType type) {
    return switch (type) {
      NotificationType.warning => Icons.warning_amber_rounded,
      NotificationType.success => Icons.check_circle_outline_rounded,
      NotificationType.error => Icons.error_outline_rounded,
      NotificationType.document => Icons.description_outlined,
      NotificationType.calendar => Icons.calendar_month_outlined,
      NotificationType.system => Icons.system_update_outlined,
      _ => Icons.info_outline_rounded,
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

class _TypePill extends StatelessWidget {
  final NotificationType type;
  final Color color;

  const _TypePill({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      NotificationType.warning => 'Alerte',
      NotificationType.success => 'Succès',
      NotificationType.error => 'Erreur',
      NotificationType.document => 'Document',
      NotificationType.calendar => 'Calendrier',
      NotificationType.system => 'Système',
      _ => 'Info',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}
