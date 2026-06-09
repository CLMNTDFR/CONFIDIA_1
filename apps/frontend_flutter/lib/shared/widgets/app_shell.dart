import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../features/messaging/messaging_provider.dart';
import '../../shared/data/mock_data.dart';
import 'app_top_bar.dart';
import 'confidia_logo.dart';
import 'mesh_background.dart';
import 'theme_toggle_button.dart';

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
    final topBar = AppTopBar.fromRoute(context, showNotifications: true);

    if (!isWide) {
      return MeshBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(ConfidiaSpacing.topBarHeight),
            child: topBar,
          ),
          body: widget.child,
          bottomNavigationBar: _MobileNav(currentPath: currentPath, unreadCount: unreadCount, mailUnread: mailUnread),
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
                  Expanded(child: widget.child),
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: isDark ? ConfidiaColors.darkSurface.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        border: Border(right: BorderSide(color: isDark ? ConfidiaColors.darkBorderSubtle : ConfidiaColors.lightBorder)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 8, 12),
            child: Row(
              children: [
                if (!collapsed) const Expanded(child: ConfidiaLogo(size: 32)),
                if (collapsed) const ConfidiaLogo(size: 32, showText: false),
                IconButton(icon: Icon(collapsed ? Icons.menu_rounded : Icons.menu_open_rounded, size: 20), onPressed: onToggle),
              ],
            ),
          ),
          if (!collapsed) const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: ThemeToggleButton()),
          const SizedBox(height: ConfidiaSpacing.sm),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.sm),
              children: [
                _NavItem(icon: Icons.space_dashboard_rounded, label: 'Accueil', path: '/dashboard', currentPath: currentPath, collapsed: collapsed),
                _NavItem(icon: Icons.mail_rounded, label: 'Messagerie', path: '/messaging', currentPath: currentPath, collapsed: collapsed, badge: mailUnread > 0 ? mailUnread : null),
                _NavItem(icon: Icons.payments_rounded, label: 'Paiements', path: '/payments', currentPath: currentPath, collapsed: collapsed),
                _NavItem(icon: Icons.folder_copy_rounded, label: 'Documents', path: '/documents', currentPath: currentPath, collapsed: collapsed),
                _NavItem(icon: Icons.calendar_month_rounded, label: 'Calendrier', path: '/calendar', currentPath: currentPath, collapsed: collapsed),
                _NavItem(icon: Icons.notifications_rounded, label: 'Notifications', path: '/notifications', currentPath: currentPath, collapsed: collapsed, badge: unreadCount > 0 ? unreadCount : null),
              ],
            ),
          ),
          const Divider(height: 1),
          _NavItem(icon: Icons.tune_rounded, label: 'Paramètres', path: '/settings', currentPath: currentPath, collapsed: collapsed),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final String currentPath;
  final bool collapsed;
  final int? badge;

  const _NavItem({required this.icon, required this.label, required this.path, required this.currentPath, required this.collapsed, this.badge});

  @override
  Widget build(BuildContext context) {
    final isActive = currentPath == path || (path != '/dashboard' && currentPath.startsWith(path));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: collapsed ? label : '',
        child: Material(
          color: isActive ? ConfidiaColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => context.go(path),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 14, vertical: 11),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: isActive ? ConfidiaColors.primary : ConfidiaColors.textSecondary(isDark)),
                  if (!collapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: isActive ? ConfidiaColors.primary : null, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500))),
                    if (badge != null) Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(gradient: ConfidiaColors.primaryGradient, borderRadius: BorderRadius.circular(10)), child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  final String currentPath;
  final int unreadCount;
  final int mailUnread;

  const _MobileNav({required this.currentPath, required this.unreadCount, required this.mailUnread});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NavigationBar(
      height: 68,
      backgroundColor: isDark ? ConfidiaColors.darkSurface : Colors.white,
      indicatorColor: ConfidiaColors.primary.withValues(alpha: 0.15),
      selectedIndex: _indexForPath(currentPath),
      onDestinationSelected: (i) => context.go(_pathForIndex(i)),
      destinations: [
        const NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Accueil'),
        NavigationDestination(
          icon: Badge(isLabelVisible: mailUnread > 0, label: Text('$mailUnread'), child: const Icon(Icons.mail_outlined)),
          selectedIcon: Badge(isLabelVisible: mailUnread > 0, label: Text('$mailUnread'), child: const Icon(Icons.mail_rounded)),
          label: 'Mails',
        ),
        const NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments_rounded), label: 'Payer'),
        const NavigationDestination(icon: Icon(Icons.folder_copy_outlined), selectedIcon: Icon(Icons.folder_copy_rounded), label: 'Docs'),
        const NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Agenda'),
      ],
    );
  }

  int _indexForPath(String path) {
    if (path.startsWith('/messaging')) return 1;
    if (path.startsWith('/payments')) return 2;
    if (path.startsWith('/documents') || path.startsWith('/upload') || path.startsWith('/scan')) return 3;
    if (path.startsWith('/calendar')) return 4;
    return 0;
  }

  String _pathForIndex(int index) => ['/dashboard', '/messaging', '/payments', '/documents', '/calendar'][index];
}
