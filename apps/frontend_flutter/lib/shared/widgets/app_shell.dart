import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
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
    final topBar = AppTopBar.fromRoute(context);

    if (!isWide) {
      return MeshBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(ConfidiaSpacing.topBarHeight),
            child: topBar,
          ),
          body: widget.child,
          floatingActionButton: _ScanFab(),
          bottomNavigationBar: _MobileNav(currentPath: currentPath, unreadCount: unreadCount),
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
        floatingActionButton: _ScanFab(),
      ),
    );
  }
}

class _ScanFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.go('/scan'),
      backgroundColor: ConfidiaColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.document_scanner_rounded),
      label: const Text('Scanner'),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final bool collapsed;
  final String currentPath;
  final int unreadCount;
  final VoidCallback onToggle;

  const _Sidebar({
    required this.collapsed,
    required this.currentPath,
    required this.unreadCount,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = collapsed ? ConfidiaSpacing.sidebarCollapsedWidth : ConfidiaSpacing.sidebarWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: isDark
            ? ConfidiaColors.darkSurface.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        border: Border(
          right: BorderSide(
            color: isDark ? ConfidiaColors.darkBorderSubtle : ConfidiaColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 8, 12),
            child: Row(
              children: [
                if (!collapsed) const Expanded(child: ConfidiaLogo(size: 32)),
                if (collapsed) const ConfidiaLogo(size: 32, showText: false),
                IconButton(
                  icon: Icon(collapsed ? Icons.menu_rounded : Icons.menu_open_rounded, size: 20),
                  onPressed: onToggle,
                  tooltip: collapsed ? 'Étendre' : 'Réduire',
                ),
              ],
            ),
          ),
          if (!collapsed) const ThemeToggleButton(),
          const SizedBox(height: ConfidiaSpacing.sm),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.sm, vertical: 4),
              children: [
                _NavItem(icon: Icons.space_dashboard_rounded, label: 'Tableau de bord', path: '/dashboard', currentPath: currentPath, collapsed: collapsed),
                _NavItem(icon: Icons.folder_copy_rounded, label: 'Documents', path: '/documents', currentPath: currentPath, collapsed: collapsed),
                _NavItem(icon: Icons.document_scanner_rounded, label: 'Scanner', path: '/scan', currentPath: currentPath, collapsed: collapsed),
                _NavItem(icon: Icons.cloud_upload_rounded, label: 'Importer', path: '/upload', currentPath: currentPath, collapsed: collapsed),
                _NavItem(icon: Icons.calendar_month_rounded, label: 'Calendrier', path: '/calendar', currentPath: currentPath, collapsed: collapsed),
                _NavItem(icon: Icons.notifications_rounded, label: 'Notifications', path: '/notifications', currentPath: currentPath, collapsed: collapsed, badge: unreadCount > 0 ? unreadCount : null),
                if (auth.user?.isAdmin == true)
                  _NavItem(icon: Icons.admin_panel_settings_rounded, label: 'Administration', path: '/admin', currentPath: currentPath, collapsed: collapsed),
              ],
            ),
          ),
          const Divider(height: 1),
          if (!collapsed && auth.user != null)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: ConfidiaColors.primary.withValues(alpha: 0.15),
                child: Text(auth.user!.initials, style: const TextStyle(color: ConfidiaColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              title: Text(auth.user!.fullName, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(auth.user!.email, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => context.go('/profile'),
            ),
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

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
    required this.collapsed,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentPath == path || (path != '/dashboard' && currentPath.startsWith(path));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: collapsed ? label : '',
        child: Material(
          color: isActive
              ? ConfidiaColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => context.go(path),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 14, vertical: 11),
              decoration: isActive
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ConfidiaColors.primary.withValues(alpha: 0.25)),
                    )
                  : null,
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isActive
                        ? ConfidiaColors.primary
                        : ConfidiaColors.textSecondary(isDark),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: isActive ? ConfidiaColors.primary : null,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: ConfidiaColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
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

  const _MobileNav({required this.currentPath, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NavigationBar(
      height: 68,
      backgroundColor: isDark ? ConfidiaColors.darkSurface : Colors.white,
      indicatorColor: ConfidiaColors.primary.withValues(alpha: 0.15),
      selectedIndex: _indexForPath(currentPath),
      onDestinationSelected: (index) => context.go(_pathForIndex(index)),
      destinations: [
        const NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Accueil'),
        const NavigationDestination(icon: Icon(Icons.folder_copy_outlined), selectedIcon: Icon(Icons.folder_copy_rounded), label: 'Docs'),
        const NavigationDestination(icon: Icon(Icons.document_scanner_outlined), selectedIcon: Icon(Icons.document_scanner_rounded), label: 'Scan'),
        NavigationDestination(
          icon: Badge(isLabelVisible: unreadCount > 0, label: Text('$unreadCount'), child: const Icon(Icons.notifications_outlined)),
          selectedIcon: Badge(isLabelVisible: unreadCount > 0, label: Text('$unreadCount'), child: const Icon(Icons.notifications_rounded)),
          label: 'Alertes',
        ),
        const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profil'),
      ],
    );
  }

  int _indexForPath(String path) {
    if (path.startsWith('/documents') || path.startsWith('/upload')) return 1;
    if (path.startsWith('/scan')) return 2;
    if (path.startsWith('/notifications')) return 3;
    if (path.startsWith('/profile') || path.startsWith('/settings')) return 4;
    if (path.startsWith('/calendar')) return 0;
    return 0;
  }

  String _pathForIndex(int index) {
    return ['/dashboard', '/documents', '/scan', '/notifications', '/profile'][index];
  }
}
