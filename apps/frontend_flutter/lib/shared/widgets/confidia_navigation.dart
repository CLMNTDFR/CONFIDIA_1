import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens/tokens.dart';
import '../../features/onboarding/onboarding_targets.dart';
import '../navigation/confidia_route_labels.dart';
import 'confidia_chrome_material.dart';
import 'confidia_demo_badge.dart';
import 'confidia_tooltip.dart';

/// Entrée de navigation partagée (sidebar + bottom bar).
class ConfidiaNavDestination {
  final IconData iconOutlined;
  final IconData iconFilled;
  final String label;
  final String path;
  final int? badge;
  final bool isDemo;

  const ConfidiaNavDestination({
    required this.iconOutlined,
    required this.iconFilled,
    required this.label,
    required this.path,
    this.badge,
    this.isDemo = false,
  });
}

bool confidiaNavIsActive(String path, String currentPath) {
  if (path == '/dashboard') return currentPath == '/dashboard';
  return currentPath == path || currentPath.startsWith('$path/');
}

/// Item de sidebar desktop  -  surface2 + textPrimary pour l'actif.
class ConfidiaSidebarNavItem extends StatefulWidget {
  final ConfidiaNavDestination destination;
  final bool isActive;
  final bool collapsed;

  const ConfidiaSidebarNavItem({
    super.key,
    required this.destination,
    required this.isActive,
    required this.collapsed,
  });

  @override
  State<ConfidiaSidebarNavItem> createState() => _ConfidiaSidebarNavItemState();
}

class _ConfidiaSidebarNavItemState extends State<ConfidiaSidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = widget.destination;
    final active = widget.isActive;
    final hovered = _hovered && !active;
    final activeColor = AppColors.textPrimary(isDark);
    final idleColor = AppColors.textSecondary(isDark);

    // Pendant l'animation de largeur, `collapsed` bascule avant la fin :
    // on se base sur l'espace réel pour éviter les overflows.
    final item = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: active
              ? AppColors.surface2(isDark)
              : hovered
                  ? (isDark ? Colors.white : Colors.black).withValues(alpha: AppOpacity.hoverInkLight)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.go(d.path),
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showLabel = constraints.maxWidth >= 96;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: showLabel ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? d.iconFilled : d.iconOutlined,
                        size: 20,
                        color: active ? activeColor : idleColor.withValues(alpha: 0.75),
                      ),
                      if (showLabel) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            d.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: active ? activeColor : idleColor.withValues(alpha: 0.8),
                                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                ),
                          ),
                        ),
                        if (d.isDemo) ...[
                          const ConfidiaDemoBadge(compact: true),
                          const SizedBox(width: 6),
                        ],
                        if (d.badge != null) _NavBadge(count: d.badge!),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    if (!widget.collapsed) return item;
    final tip = d.isDemo ? '${d.label} · Démo' : d.label;
    return ConfidiaTooltip(message: tip, preferBelow: false, child: item);
  }
}

class _NavBadge extends StatelessWidget {
  final int count;

  const _NavBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface2(isDark),
        borderRadius: BorderRadius.circular(8),
        border: Border.fromBorderSide(AppBorders.standard(isDark)),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: AppColors.textPrimary(isDark),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Bottom bar mobile  -  actif sans couleur de marque.
class ConfidiaMobileNavBar extends StatelessWidget {
  final String currentPath;
  final List<ConfidiaNavDestination> destinations;

  const ConfidiaMobileNavBar({
    super.key,
    required this.currentPath,
    required this.destinations,
  });

  int _selectedIndex() {
    for (var i = 0; i < destinations.length; i++) {
      if (confidiaNavIsActive(destinations[i].path, currentPath)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex();

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: ConfidiaChromeMaterial(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: List.generate(destinations.length, (i) {
                final destination = destinations[i];
                Widget item = _MobileNavItem(
                  destination: destination,
                  isActive: i == selected,
                );
                if (destination.isDemo) {
                  item = ConfidiaTooltip(
                    message: '${destination.label} · Démo',
                    child: item,
                  );
                }
                if (destination.path == '/settings') {
                  item = KeyedSubtree(key: OnboardingTargets.settingsNav, child: item);
                }
                return Expanded(child: item);
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final ConfidiaNavDestination destination;
  final bool isActive;

  const _MobileNavItem({required this.destination, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = destination;
    final activeColor = AppColors.textPrimary(isDark);
    final idleColor = AppColors.textSecondary(isDark);

    Widget icon = Icon(
      isActive ? d.iconFilled : d.iconOutlined,
      size: 22,
      color: isActive ? activeColor : idleColor.withValues(alpha: 0.7),
    );

    if (d.badge != null && d.badge! > 0) {
      icon = Badge(
        isLabelVisible: true,
        label: Text(
          '${d.badge}',
          style: TextStyle(fontSize: 9, color: AppColors.textPrimary(isDark)),
        ),
        backgroundColor: AppColors.surface2(isDark),
        child: icon,
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(d.path),
        mouseCursor: SystemMouseCursors.click,
        hoverColor: (isDark ? Colors.white : Colors.black).withValues(
          alpha: isDark ? AppOpacity.hoverInkDark : AppOpacity.hoverInkLight,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.surface2(isDark) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: 4),
                Text(
                  d.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? activeColor : idleColor.withValues(alpha: 0.75),
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

/// Destinations principales de l'application.
abstract final class ConfidiaNavDestinations {
  static ConfidiaNavDestination home() => const ConfidiaNavDestination(
        iconOutlined: Icons.space_dashboard_outlined,
        iconFilled: Icons.space_dashboard_rounded,
        label: ConfidiaRouteLabels.home,
        path: '/dashboard',
      );

  static ConfidiaNavDestination messaging({int? badge}) => ConfidiaNavDestination(
        iconOutlined: Icons.mail_outlined,
        iconFilled: Icons.mail_rounded,
        label: ConfidiaRouteLabels.messaging,
        path: '/messaging',
        badge: badge,
        isDemo: true,
      );

  static ConfidiaNavDestination payments() => const ConfidiaNavDestination(
        iconOutlined: Icons.payments_outlined,
        iconFilled: Icons.payments_rounded,
        label: ConfidiaRouteLabels.payments,
        path: '/payments',
        isDemo: true,
      );

  static ConfidiaNavDestination documents() => const ConfidiaNavDestination(
        iconOutlined: Icons.folder_copy_outlined,
        iconFilled: Icons.folder_copy_rounded,
        label: ConfidiaRouteLabels.documents,
        path: '/documents',
      );

  static ConfidiaNavDestination calendar() => const ConfidiaNavDestination(
        iconOutlined: Icons.calendar_month_outlined,
        iconFilled: Icons.calendar_month_rounded,
        label: ConfidiaRouteLabels.calendar,
        path: '/calendar',
      );

  static ConfidiaNavDestination settings() => const ConfidiaNavDestination(
        iconOutlined: Icons.tune_outlined,
        iconFilled: Icons.tune_rounded,
        label: ConfidiaRouteLabels.settings,
        path: '/settings',
      );

  static ConfidiaNavDestination notifications({int? badge}) => ConfidiaNavDestination(
        iconOutlined: Icons.notifications_outlined,
        iconFilled: Icons.notifications_rounded,
        label: ConfidiaRouteLabels.notifications,
        path: '/notifications',
        badge: badge,
      );

  static List<ConfidiaNavDestination> sidebarMain({int? mailBadge, int? notifBadge}) => [
        home(),
        messaging(badge: mailBadge),
        payments(),
        documents(),
        calendar(),
        notifications(badge: notifBadge),
      ];

  static List<ConfidiaNavDestination> mobileBar({int? mailBadge}) => [
        home(),
        messaging(badge: mailBadge),
        payments(),
        documents(),
        calendar(),
        settings(),
      ];
}
