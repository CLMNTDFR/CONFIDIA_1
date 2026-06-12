import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/spacing.dart';
import '../../features/messaging/messaging_provider.dart';
import '../../shared/data/mock_data.dart';
import 'app_top_bar.dart';
import 'confidia_animated_logo.dart';
import 'confidia_navigation.dart';
import 'mesh_background.dart';
import 'mobile_page_header.dart';
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
    ref.watch(messagingProvider);
    final mailUnread = ref.read(messagingProvider.notifier).unreadCount;
    final routeMeta = AppTopBar.routeMeta(currentPath);
    final topBar = AppTopBar.fromRoute(context, showNotifications: true);

    if (!isWide) {
      return MeshBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(ConfidiaSpacing.topBarHeight),
            child: topBar,
          ),
          body: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: MediaQuery.paddingOf(context).copyWith(
                bottom: ConfidiaMobileShell.bottomScrollInset(context),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MobilePageHeader(title: routeMeta.$1, subtitle: routeMeta.$2),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey<String>(currentPath),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: ConfidiaMobileNavBar(
            currentPath: currentPath,
            destinations: ConfidiaNavDestinations.mobileBar(
              mailBadge: mailUnread > 0 ? mailUnread : null,
            ),
          ),
        ),
      );
    }

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            _Sidebar(
              collapsed: _sidebarCollapsed,
              currentPath: currentPath,
              unreadCount: unreadCount,
              mailUnread: mailUnread,
              onToggle: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
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
        color: isDark ? ConfidiaColors.darkSurface.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        border: Border(right: BorderSide(color: isDark ? ConfidiaColors.darkBorderSubtle : ConfidiaColors.lightBorder)),
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
                          child: const ConfidiaAnimatedLogo(layout: ConfidiaAnimatedLogoLayout.sidebarCollapsed),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SidebarToggleButton(collapsed: true, onPressed: onToggle, isDark: isDark),
                    ],
                  )
                : Row(
                    children: [
                      const Expanded(
                        child: ConfidiaAnimatedLogo(layout: ConfidiaAnimatedLogoLayout.sidebarExpanded),
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
                Divider(height: 1, color: ConfidiaColors.border(isDark).withValues(alpha: 0.5)),
                const SizedBox(height: 4),
                ConfidiaSidebarNavItem(
                  destination: ConfidiaNavDestinations.settings(),
                  isActive: confidiaNavIsActive('/settings', currentPath),
                  collapsed: collapsed,
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
            color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            border: Border.all(color: ConfidiaColors.border(widget.isDark).withValues(alpha: 0.6)),
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
