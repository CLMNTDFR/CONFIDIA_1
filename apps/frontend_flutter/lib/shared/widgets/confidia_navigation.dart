import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../features/onboarding/onboarding_targets.dart';
import '../navigation/confidia_route_labels.dart';
import 'confidia_tooltip.dart';

/// Entrée de navigation partagée (sidebar + bottom bar).
class ConfidiaNavDestination {
  final IconData iconOutlined;
  final IconData iconFilled;
  final String label;
  final String path;
  final int? badge;

  const ConfidiaNavDestination({
    required this.iconOutlined,
    required this.iconFilled,
    required this.label,
    required this.path,
    this.badge,
  });
}

bool confidiaNavIsActive(String path, String currentPath) {
  if (path == '/dashboard') return currentPath == '/dashboard';
  return currentPath == path || currentPath.startsWith('$path/');
}

/// Item de sidebar desktop  -  sobre, typographie comme signal d'état.
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

    final item = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: hovered ? (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => context.go(d.path),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 0 : 12, vertical: 10),
              child: Row(
                mainAxisAlignment: widget.collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Icon(
                    active ? d.iconFilled : d.iconOutlined,
                    size: 20,
                    color: active
                        ? context.palette.primary
                        : ConfidiaColors.textSecondary(isDark).withValues(alpha: 0.75),
                  ),
                  if (!widget.collapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        d.label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: active
                                  ? context.palette.primary
                                  : ConfidiaColors.textSecondary(isDark).withValues(alpha: 0.8),
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            ),
                      ),
                    ),
                    if (d.badge != null) _NavBadge(count: d.badge!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.collapsed) return item;
    return ConfidiaTooltip(message: d.label, preferBelow: false, child: item);
  }
}

class _NavBadge extends StatelessWidget {
  final int count;

  const _NavBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.palette.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }
}

/// Bottom bar mobile  -  sobre, lisible.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selectedIndex();

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF12121A).withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.18),
              border: Border(
                top: BorderSide(color: ConfidiaColors.border(isDark).withValues(alpha: 0.28)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: Row(
                  children: List.generate(destinations.length, (i) {
                    final destination = destinations[i];
                    Widget item = _MobileNavItem(
                      destination: destination,
                      isActive: i == selected,
                    );
                    if (destination.path == '/settings') {
                      item = KeyedSubtree(key: OnboardingTargets.settingsNav, child: item);
                    }
                    return Expanded(child: item);
                  }),
                ),
              ),
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

    Widget icon = Icon(
      isActive ? d.iconFilled : d.iconOutlined,
      size: 22,
      color: isActive
          ? context.palette.primary
          : ConfidiaColors.textSecondary(isDark).withValues(alpha: 0.7),
    );

    if (d.badge != null && d.badge! > 0) {
      icon = Badge(
        isLabelVisible: true,
        label: Text('${d.badge}', style: const TextStyle(fontSize: 9)),
        backgroundColor: context.palette.primary,
        child: icon,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(d.path),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 3),
              Text(
                d.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive
                      ? context.palette.primary
                      : ConfidiaColors.textSecondary(isDark).withValues(alpha: 0.75),
                ),
              ),
            ],
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
      );

  static ConfidiaNavDestination payments() => const ConfidiaNavDestination(
        iconOutlined: Icons.payments_outlined,
        iconFilled: Icons.payments_rounded,
        label: ConfidiaRouteLabels.payments,
        path: '/payments',
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
