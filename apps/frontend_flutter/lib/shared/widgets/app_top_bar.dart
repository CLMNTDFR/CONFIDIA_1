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
import '../../core/theme/theme_context.dart';
import '../../features/dashboard/serenity_briefing_provider.dart';
import '../../features/day_start/day_start_provider.dart';
import '../../features/onboarding/onboarding_targets.dart';
import '../../features/profile/profile_avatar_provider.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/utils/serenity_palette.dart';
import 'confidia_button.dart';
import 'confidia_chrome_material.dart';
import 'confidia_page_header.dart';
import 'confidia_tooltip.dart';
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
    final width = MediaQuery.of(context).size.width;
    final showDate = width >= 720;
    final path = GoRouterState.of(context).matchedLocation;
    final backRoute = confidiaParentRoute(path);

    return ConfidiaChromeMaterial(
      child: SizedBox(
        height: ConfidiaSpacing.topBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg),
          child: Row(
        children: [
          Expanded(
            child: Row(
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
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ConfidiaColors.textSecondary(isDark),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showDate) ...[
            const _TopBarDate(),
            const SizedBox(width: 12),
          ],
          const _SerenityScoreChip(),
          const SizedBox(width: 8),
          if (showNotifications)
            KeyedSubtree(
              key: OnboardingTargets.notifications,
              child: ConfidiaIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notifications',
                showBadge: unread > 0,
                onPressed: () => context.go('/notifications'),
              ),
            ),
          const SizedBox(width: 6),
          const ThemeToggleButton(compact: true),
          const SizedBox(width: 6),
          if (auth.user != null)
            _ProfileChip(user: auth.user!, imageBase64: avatarBase64, onTap: () => context.go('/profile')),
        ],
          ),
        ),
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

class _SerenityScoreChip extends ConsumerWidget {
  const _SerenityScoreChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(serenityBriefingProvider.select((b) => b.score));
    final accent = SerenityPalette.forScore(score, palette: context.palette);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.go('/dashboard');
          ref.read(dayStartSessionProvider.notifier).openFromChip();
        },
        borderRadius: BorderRadius.circular(10),
        child: ConfidiaTooltip(
          message: 'Briefing du jour',
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, size: 14, color: accent),
                const SizedBox(width: 4),
                Text(
                  '$score',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ],
            ),
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showName = MediaQuery.of(context).size.width >= 1100;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: showName ? 8 : 4),
          decoration: BoxDecoration(
            color: isDark ? ConfidiaColors.darkSurfaceVariant : ConfidiaColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ConfidiaColors.border(isDark)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(user: user, radius: 14, imageBase64: imageBase64),
              if (showName) ...[
                const SizedBox(width: 8),
                Text(user.firstName, style: Theme.of(context).textTheme.labelMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
