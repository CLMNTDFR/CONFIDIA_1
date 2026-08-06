import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/tokens/tokens.dart';
import '../../features/day_start/day_start_overlay.dart';
import '../../features/day_start/day_start_provider.dart';
import '../../features/dashboard/serenity_briefing_provider.dart';
import '../../features/messaging/messaging_provider.dart';
import '../../features/onboarding/guided_tour_overlay.dart';
import '../../features/onboarding/guided_tour_provider.dart';
import '../../features/onboarding/onboarding_targets.dart';
import '../../features/serenity_feedback/serenity_moment_overlay.dart';
import '../../features/serenity_feedback/serenity_moments_provider.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/serenity_briefing_model.dart';
import 'app_top_bar.dart';
import 'confidia_logo.dart';
import 'confidia_navigation.dart';
import 'mesh_background.dart';
import 'mobile_shell_insets.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final currentPath = GoRouterState.of(context).matchedLocation;
    final unreadCount = MockData.notifications.where((n) => !n.read).length;
    final mailUnread = ref.watch(messagingUnreadCountProvider);
    final topBar = AppTopBar.fromRoute(context, showNotifications: true);
    final tourActive = ref.watch(guidedTourProvider.select((s) => s.active));
    final dayStartOpen = ref.watch(dayStartSessionProvider.select((s) => s.isOpen));
    final hasMoment = ref.watch(serenityMomentsProvider.select((s) => s.current != null));

    ref.listen(authStateProvider, (prev, next) {
      if (prev?.isAuthenticated == true && !next.isAuthenticated) {
        ref.read(guidedTourProvider.notifier).reset();
      }
    });

    ref.listen(serenityBriefingProvider, (prev, next) {
      ref.read(serenityMomentsProvider.notifier).onScoreChanged(
            prev?.score,
            next.score,
            next.level.label,
          );
    });

    Widget shell;
    if (!isWide) {
      final topInset = MediaQuery.viewPaddingOf(context).top;
      shell = Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(ConfidiaSpacing.topBarHeight + topInset),
          child: SafeArea(
            bottom: false,
            child: topBar,
          ),
        ),
        body: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: MediaQuery.paddingOf(context).copyWith(
              bottom: ConfidiaMobileShell.bottomScrollInset(context),
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey<String>(currentPath),
            child: widget.child,
          ),
        ),
        bottomNavigationBar: ConfidiaMobileNavBar(
          key: OnboardingTargets.mobileNav,
          currentPath: currentPath,
          destinations: ConfidiaNavDestinations.mobileBar(
            mailBadge: mailUnread > 0 ? mailUnread : null,
          ),
        ),
      );
    } else {
      shell = Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            KeyedSubtree(
              key: OnboardingTargets.sidebarNav,
              child: _Sidebar(
                collapsed: _sidebarCollapsed,
                currentPath: currentPath,
                unreadCount: unreadCount,
                mailUnread: mailUnread,
                onToggle: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  topBar,
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey<String>(currentPath),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return MeshBackground(
      child: Stack(
        children: [
          shell,
          if (hasMoment) const SerenityMomentOverlay(),
          if (dayStartOpen) const DayStartOverlay(),
          if (tourActive) const GuidedTourOverlay(),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final bool collapsed;
  final String currentPath;
  final int unreadCount;
  final int mailUnread;
  final VoidCallback onToggle;

  const _Sidebar({
    required this.collapsed,
    required this.currentPath,
    required this.unreadCount,
    required this.mailUnread,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = collapsed ? ConfidiaSpacing.sidebarCollapsedWidth : ConfidiaSpacing.sidebarWidth;
    final mainDestinations = ConfidiaNavDestinations.sidebarMain(
      mailBadge: mailUnread > 0 ? mailUnread : null,
      notifBadge: unreadCount > 0 ? unreadCount : null,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface1(isDark).withValues(
          alpha: isDark ? AppOpacity.contentDark : AppOpacity.contentLight,
        ),
        border: Border(right: AppBorders.subtle(isDark)),
        boxShadow: [
          BoxShadow(
            color: context.palette.secondary.withValues(alpha: isDark ? 0.06 : 0.04),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(collapsed ? 8 : 12, 16, collapsed ? 8 : 8, 12),
            child: collapsed
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 34,
                        child: Center(
                          child: const ConfidiaLogo(size: 22, showText: false),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SidebarToggleButton(collapsed: true, onPressed: onToggle, isDark: isDark),
                    ],
                  )
                : Row(
                    children: [
                      const Expanded(
                        child: ConfidiaLogo(size: 32, showText: true),
                      ),
                      _SidebarToggleButton(collapsed: false, onPressed: onToggle, isDark: isDark),
                    ],
                  ),
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.sm),
              children: mainDestinations
                  .map(
                    (d) => ConfidiaSidebarNavItem(
                      destination: d,
                      isActive: confidiaNavIsActive(d.path, currentPath),
                      collapsed: collapsed,
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            child: Column(
              children: [
                Divider(height: 1, color: AppBorders.subtle(isDark).color),
                const SizedBox(height: 4),
                KeyedSubtree(
                  key: OnboardingTargets.settingsNav,
                  child: ConfidiaSidebarNavItem(
                    destination: ConfidiaNavDestinations.settings(),
                    isActive: confidiaNavIsActive('/settings', currentPath),
                    collapsed: collapsed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarToggleButton extends StatefulWidget {
  final bool collapsed;
  final VoidCallback onPressed;
  final bool isDark;

  const _SidebarToggleButton({
    required this.collapsed,
    required this.onPressed,
    required this.isDark,
  });

  @override
  State<_SidebarToggleButton> createState() => _SidebarToggleButtonState();
}

class _SidebarToggleButtonState extends State<_SidebarToggleButton> with SingleTickerProviderStateMixin {
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
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: AppOpacity.faint),
            border: Border.fromBorderSide(AppBorders.standard(widget.isDark)),
          ),
          child: Icon(
            widget.collapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
            size: 18,
            color: ConfidiaColors.textSecondary(widget.isDark),
          ),
        ),
      ),
    );
  }
}
