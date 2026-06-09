import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';

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

/// Item de sidebar desktop — glow sobre, animation au tap.
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

class _ConfidiaSidebarNavItemState extends State<ConfidiaSidebarNavItem> with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1, end: 0.96).animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = widget.destination;
    final active = widget.isActive;
    final hovered = _hovered && !active;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: widget.collapsed ? d.label : '',
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown: (_) => _press.forward(),
            onTapUp: (_) => _press.reverse(),
            onTapCancel: () => _press.reverse(),
            onTap: () => context.go(d.path),
            child: ScaleTransition(
              scale: _scale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: active
                      ? LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            ConfidiaColors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                            ConfidiaColors.secondary.withValues(alpha: isDark ? 0.14 : 0.06),
                          ],
                        )
                      : null,
                  color: active
                      ? null
                      : hovered
                          ? ConfidiaColors.primary.withValues(alpha: isDark ? 0.08 : 0.05)
                          : Colors.transparent,
                  border: Border.all(
                    color: active
                        ? ConfidiaColors.secondary.withValues(alpha: 0.25)
                        : hovered
                            ? ConfidiaColors.secondary.withValues(alpha: 0.22)
                            : Colors.transparent,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: ConfidiaColors.primary.withValues(alpha: 0.12),
                            blurRadius: 12,
                            spreadRadius: -4,
                          ),
                        ]
                      : hovered
                          ? [
                              BoxShadow(
                                color: ConfidiaColors.secondary.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: -4,
                              ),
                            ]
                          : null,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 0 : 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: widget.collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          gradient: active
                              ? LinearGradient(
                                  colors: [
                                    ConfidiaColors.primary.withValues(alpha: 0.85),
                                    ConfidiaColors.secondary.withValues(alpha: 0.7),
                                  ],
                                )
                              : hovered
                                  ? LinearGradient(
                                      colors: [
                                        ConfidiaColors.primary.withValues(alpha: 0.2),
                                        ConfidiaColors.secondary.withValues(alpha: 0.12),
                                      ],
                                    )
                                  : null,
                          color: active || hovered
                              ? null
                              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: ConfidiaColors.secondary.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    spreadRadius: -2,
                                  ),
                                ]
                              : hovered
                                  ? [
                                      BoxShadow(
                                        color: ConfidiaColors.primary.withValues(alpha: 0.15),
                                        blurRadius: 6,
                                        spreadRadius: -2,
                                      ),
                                    ]
                                  : null,
                        ),
                        child: Icon(
                          active || hovered ? d.iconFilled : d.iconOutlined,
                          size: 17,
                          color: active
                              ? Colors.white
                              : hovered
                                  ? ConfidiaColors.primary
                                  : ConfidiaColors.textSecondary(isDark),
                        ),
                      ),
                    if (!widget.collapsed) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          d.label,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: active ? ConfidiaColors.primary : ConfidiaColors.textSecondary(isDark),
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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
        ),
      ),
    );
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
        gradient: ConfidiaColors.primaryGradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: ConfidiaColors.primary.withValues(alpha: 0.35),
            blurRadius: 6,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

/// Bottom bar mobile premium — glass, glow, 6 destinations dont Paramètres.
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

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? ConfidiaColors.darkSurface : Colors.white).withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(color: ConfidiaColors.border(isDark).withValues(alpha: 0.6)),
            ),
            boxShadow: [
              BoxShadow(
                color: ConfidiaColors.secondary.withValues(alpha: isDark ? 0.08 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: List.generate(destinations.length, (i) {
                  return Expanded(
                    child: _MobileNavItem(
                      destination: destinations[i],
                      isActive: i == selected,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatefulWidget {
  final ConfidiaNavDestination destination;
  final bool isActive;

  const _MobileNavItem({required this.destination, required this.isActive});

  @override
  State<_MobileNavItem> createState() => _MobileNavItemState();
}

class _MobileNavItemState extends State<_MobileNavItem> with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1, end: 0.9).animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = widget.destination;
    final active = widget.isActive;

    Widget icon = Icon(
      active ? d.iconFilled : d.iconOutlined,
      size: 21,
      color: active ? ConfidiaColors.primary : ConfidiaColors.textSecondary(isDark),
    );

    if (d.badge != null && d.badge! > 0) {
      icon = Badge(
        isLabelVisible: true,
        label: Text('${d.badge}', style: const TextStyle(fontSize: 9)),
        backgroundColor: ConfidiaColors.primary,
        child: icon,
      );
    }

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: () => context.go(d.path),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ConfidiaColors.primary.withValues(alpha: isDark ? 0.18 : 0.1),
                      Colors.transparent,
                    ],
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (active)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ConfidiaColors.primary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                    ),
                  icon,
                ],
              ),
              const SizedBox(height: 2),
              Text(
                d.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.1,
                  color: active ? ConfidiaColors.primary : ConfidiaColors.textSecondary(isDark),
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
        label: 'Accueil',
        path: '/dashboard',
      );

  static ConfidiaNavDestination messaging({int? badge}) => ConfidiaNavDestination(
        iconOutlined: Icons.mail_outlined,
        iconFilled: Icons.mail_rounded,
        label: 'Mails',
        path: '/messaging',
        badge: badge,
      );

  static ConfidiaNavDestination payments() => const ConfidiaNavDestination(
        iconOutlined: Icons.payments_outlined,
        iconFilled: Icons.payments_rounded,
        label: 'Payer',
        path: '/payments',
      );

  static ConfidiaNavDestination documents() => const ConfidiaNavDestination(
        iconOutlined: Icons.folder_copy_outlined,
        iconFilled: Icons.folder_copy_rounded,
        label: 'Docs',
        path: '/documents',
      );

  static ConfidiaNavDestination calendar() => const ConfidiaNavDestination(
        iconOutlined: Icons.calendar_month_outlined,
        iconFilled: Icons.calendar_month_rounded,
        label: 'Agenda',
        path: '/calendar',
      );

  static ConfidiaNavDestination settings() => const ConfidiaNavDestination(
        iconOutlined: Icons.tune_outlined,
        iconFilled: Icons.tune_rounded,
        label: 'Réglages',
        path: '/settings',
      );

  static ConfidiaNavDestination notifications({int? badge}) => ConfidiaNavDestination(
        iconOutlined: Icons.notifications_outlined,
        iconFilled: Icons.notifications_rounded,
        label: 'Alertes',
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
