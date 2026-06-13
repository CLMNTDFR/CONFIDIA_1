import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../navigation/confidia_parent_route.dart';
import '../navigation/confidia_route_labels.dart';
import '../../shared/models/user_model.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../features/profile/profile_avatar_provider.dart';
import '../../shared/data/mock_data.dart';
import 'confidia_button.dart';
import 'confidia_logo.dart';
import 'confidia_page_header.dart';
import 'theme_toggle_button.dart';
import 'user_avatar.dart';

class AppTopBar extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final bool showNotifications;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showNotifications = true,
  });

  static AppTopBar fromRoute(BuildContext context, {bool showNotifications = true}) {
    final path = GoRouterState.of(context).matchedLocation;
    final meta = routeMeta(path);
    return AppTopBar(title: meta.$1, subtitle: meta.$2, showNotifications: showNotifications);
  }

  static (String, String?) routeMeta(String path) {
    if (path.startsWith('/dashboard')) return (ConfidiaRouteLabels.home, 'Widgets personnalisables');
    if (path.startsWith('/documents/')) return ('Document', 'Détail et analyse');
    if (path.startsWith('/documents')) return (ConfidiaRouteLabels.documents, 'Bibliothèque');
    if (path.startsWith('/scan')) return ('Scanner', 'Capture photo');
    if (path.startsWith('/upload')) return ('Importer', 'Ajout de fichiers');
    if (path.startsWith('/payments/')) return ('Paiement', 'Détail et règlement');
    if (path.startsWith('/payments')) return (ConfidiaRouteLabels.payments, 'Factures et échéances');
    if (path.startsWith('/messaging/')) return ('Message', 'Analyse IA');
    if (path.startsWith('/messaging')) return (ConfidiaRouteLabels.messaging, 'Boîte unifiée');
    if (path.startsWith('/calendar')) return (ConfidiaRouteLabels.calendar, 'Échéances fusionnées');
    if (path.startsWith('/notifications')) return (ConfidiaRouteLabels.notifications, 'Centre d\'alertes');
    if (path.startsWith('/profile')) return ('Profil', 'Compte et identité');
    if (path.startsWith('/settings')) return (ConfidiaRouteLabels.settings, 'Préférences');
    if (path.startsWith('/access-control')) return ('Gouvernance', 'Rôles, droits & IA planning');
    if (path.startsWith('/admin')) return ('Administration', 'Plateforme');
    return ('CONFIDIA', null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authStateProvider);
    final avatarBase64 = ref.watch(profileAvatarProvider);
    final unread = MockData.notifications.where((n) => !n.read).length;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final path = GoRouterState.of(context).matchedLocation;
    final backRoute = confidiaParentRoute(path);

    return Container(
      height: ConfidiaSpacing.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? ConfidiaColors.darkSurface.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: isDark ? ConfidiaColors.darkBorderSubtle : ConfidiaColors.lightBorderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      if (backRoute != null) ...[
                        ConfidiaBackButton(parentRoute: backRoute),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: Theme.of(context).textTheme.titleLarge),
                            if (subtitle != null)
                              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  )
                : const Align(
                    alignment: Alignment.centerLeft,
                    child: ConfidiaLogo(size: 26, showText: true),
                  ),
          ),
          const _TopBarDate(),
          const SizedBox(width: 12),
          if (showNotifications)
            ConfidiaIconButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Notifications',
              showBadge: unread > 0,
              onPressed: () => context.go('/notifications'),
            ),
          const SizedBox(width: 6),
          const ThemeToggleButton(compact: true),
          const SizedBox(width: 6),
          if (auth.user != null)
            _ProfileChip(user: auth.user!, imageBase64: avatarBase64, onTap: () => context.go('/profile')),
        ],
      ),
    );
  }
}

class _TopBarDate extends StatelessWidget {
  const _TopBarDate();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final raw = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    final label = raw.isNotEmpty ? '${raw[0].toUpperCase()}${raw.substring(1)}' : raw;

    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: ConfidiaColors.textSecondary(isDark),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final UserModel user;
  final String? imageBase64;
  final VoidCallback onTap;

  const _ProfileChip({required this.user, this.imageBase64, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(user: user, radius: 16, imageBase64: imageBase64),
              if (MediaQuery.of(context).size.width >= 1100) ...[
                const SizedBox(width: 8),
                Text(user.firstName, style: Theme.of(context).textTheme.labelLarge),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
