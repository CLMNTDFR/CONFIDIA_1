import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/mvp/confidia_mvp_scope.dart';
import '../navigation/confidia_parent_route.dart';
import '../navigation/confidia_route_labels.dart';
import '../../shared/models/user_model.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../features/dashboard/serenity_briefing_provider.dart';
import '../../features/day_start/day_start_provider.dart';
import '../../features/notifications/notifications_provider.dart';
import '../../features/onboarding/onboarding_targets.dart';
import '../../features/profile/profile_avatar_provider.dart';
import '../../shared/utils/serenity_palette.dart';
import 'confidia_button.dart';
import 'confidia_chrome_material.dart';
import 'confidia_demo_badge.dart';
import 'confidia_page_header.dart';
import 'confidia_tooltip.dart';
import 'serenity_score_ring.dart';
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
    final state = GoRouterState.of(context);
    final meta = routeMeta(state.matchedLocation, uri: state.uri);
    return AppTopBar(title: meta.$1, subtitle: meta.$2, showNotifications: showNotifications);
  }

  static (String, String?) routeMeta(String path, {Uri? uri}) {
    if (path.startsWith('/dashboard')) return (ConfidiaRouteLabels.home, 'Widgets personnalisables');
    // /documents/add avant /documents/ sinon titre « Document » à tort
    if (path.startsWith('/documents/add')) {
      final mode = uri?.queryParameters['mode'];
      if (mode == 'camera') return ('Scanner', 'Photo ou scan');
      if (mode == 'files') return ('Importer', 'Fichiers appareil');
      return ('Ajouter', 'Nouveau document');
    }
    if (path.startsWith('/documents/')) return ('Document', 'Détail et analyse');
    if (path.startsWith('/documents')) return (ConfidiaRouteLabels.documents, 'Bibliothèque');
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
    final unread = ref.watch(notificationsUnreadCountProvider);
    final path = GoRouterState.of(context).matchedLocation;
    final backRoute = confidiaParentRoute(path);

    return ConfidiaChromeMaterial(
      child: SizedBox(
        height: ConfidiaSpacing.topBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg),
          // Largeur disponible (colonne contenu), pas la fenêtre : la sidebar
          // ouverte réduit cette zone et provoquait des overflows.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final showDate = w >= 820;
              final showProfileName = w >= 980;

              return Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (backRoute != null) ...[
                          ConfidiaBackButton(parentRoute: backRoute),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      title,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            height: 1.15,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (ConfidiaMvpScope.isDemoPath(path)) ...[
                                    const SizedBox(width: 8),
                                    const ConfidiaDemoBadge(),
                                  ],
                                ],
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
                  const SizedBox(width: 8),
                  if (auth.user != null)
                    _ProfileChip(
                      user: auth.user!,
                      imageBase64: avatarBase64,
                      showName: showProfileName,
                      onTap: () => context.go('/profile'),
                    ),
                ],
              );
            },
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

  static const _size = 40.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(serenityBriefingProvider.select((b) => b.score));
    final accent = SerenityPalette.forScore(score, palette: context.palette);

    return ConfidiaTooltip(
      message: 'Briefing du jour · Démo',
      child: SizedBox(
        width: _size,
        height: _size,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              context.go('/dashboard');
              ref.read(dayStartSessionProvider.notifier).openFromChip();
            },
            customBorder: const CircleBorder(),
            child: SerenityScoreRing(
              score: score,
              label: '',
              color: accent,
              size: _size,
              scoreFontSize: 12,
              strokeWidth: 3,
              showLabel: false,
              animateFromZero: false,
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
  final bool showName;
  final VoidCallback onTap;

  const _ProfileChip({
    required this.user,
    this.imageBase64,
    required this.showName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
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
              UserAvatar(user: user, radius: 16, imageBase64: imageBase64),
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
