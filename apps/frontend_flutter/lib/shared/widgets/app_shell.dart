import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/tokens/tokens.dart';
import '../../features/day_start/day_start_overlay.dart';
import '../../features/day_start/day_start_provider.dart';
import '../../features/dashboard/serenity_briefing_provider.dart';
import '../../features/messaging/messaging_provider.dart';
import '../../features/notifications/notifications_provider.dart';
import '../../features/onboarding/guided_tour_overlay.dart';
import '../../features/onboarding/guided_tour_provider.dart';
import '../../features/onboarding/onboarding_targets.dart';
import '../../features/serenity_feedback/serenity_moment_overlay.dart';
import '../../features/serenity_feedback/serenity_moments_provider.dart';
import '../../shared/models/serenity_briefing_model.dart';
import 'app_top_bar.dart';
import 'confidia_logo.dart';
import 'confidia_navigation.dart';
import 'confidia_tappable.dart';
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
    final unreadCount = ref.watch(notificationsUnreadCountProvider);
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

    ref.listen(guidedTourProvider, (prev, next) {
      if (prev?.active == true && !next.active) {
        ref.read(authStateProvider.notifier).clearFirstLoginPending();
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
              // Réserve l'emprise barre + air : les pages qui s'appuient sur
              // MediaQuery.padding (SafeArea, etc.) restent au-dessus de la nav.
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
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surface1(isDark).withValues(
          alpha: isDark ? AppOpacity.contentDark : AppOpacity.contentLight,
        ),
        border: Border(right: AppBorders.subtle(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Largeur animée vs booléen : afficher le chrome étendu seulement quand il y a la place.
          final showExpandedChrome = constraints.maxWidth >= 160;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(showExpandedChrome ? 12 : 8, 16, showExpandedChrome ? 8 : 8, 12),
                child: showExpandedChrome
                    ? Row(
                        children: [
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: ConfidiaLogo(size: 26, showText: true),
                                ),
                              ),
                            ),
                          ),
                          _SidebarToggleButton(collapsed: false, onPressed: onToggle, isDark: isDark),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 36,
                            child: Center(
                              child: ConfidiaLogo(size: 28, showText: false),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SidebarToggleButton(collapsed: true, onPressed: onToggle, isDark: isDark),
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
                          collapsed: !showExpandedChrome,
                        ),
                      )
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Column(
                  children: [
                    Divider(height: 1, color: AppBorders.subtle(isDark).color),
                    const SizedBox(height: 4),
                    KeyedSubtree(
                      key: OnboardingTargets.settingsNav,
                      child: ConfidiaSidebarNavItem(
                        destination: ConfidiaNavDestinations.settings(),
                        isActive: confidiaNavIsActive('/settings', currentPath),
                        collapsed: !showExpandedChrome,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SidebarToggleButton extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onPressed;
  final bool isDark;

  const _SidebarToggleButton({
    required this.collapsed,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    return ConfidiaTappable(
      onTap: onPressed,
      pressScale: 0.9,
      borderRadius: radius,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: AppOpacity.faint),
          border: Border.fromBorderSide(AppBorders.standard(isDark)),
        ),
        child: Icon(
          collapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
          size: 18,
          color: ConfidiaColors.textSecondary(isDark),
        ),
      ),
    );
  }
}
