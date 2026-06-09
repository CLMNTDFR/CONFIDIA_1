import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_data.dart';
import 'theme_toggle_button.dart';

class AppTopBar extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  static AppTopBar fromRoute(BuildContext context) {
    final path = GoRouterState.of(context).matchedLocation;
    final meta = _routeMeta(path);
    return AppTopBar(title: meta.$1, subtitle: meta.$2);
  }

  static (String, String?) _routeMeta(String path) {
    if (path.startsWith('/dashboard')) return ('Tableau de bord', 'Vue d\'ensemble');
    if (path.startsWith('/documents/')) return ('Détail document', null);
    if (path.startsWith('/documents')) return ('Documents', 'Gestion documentaire');
    if (path.startsWith('/scan')) return ('Scanner', 'Capture via appareil photo');
    if (path.startsWith('/upload')) return ('Importer', 'Ajouter des fichiers');
    if (path.startsWith('/calendar')) return ('Calendrier', 'Échéances et rendez-vous');
    if (path.startsWith('/notifications')) return ('Notifications', 'Centre d\'alertes');
    if (path.startsWith('/profile')) return ('Profil', 'Votre compte');
    if (path.startsWith('/settings')) return ('Paramètres', 'Préférences');
    if (path.startsWith('/admin')) return ('Administration', 'Gestion plateforme');
    return ('CONFIDIA', null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authStateProvider);
    final unread = MockData.notifications.where((n) => !n.read).length;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Container(
      height: ConfidiaSpacing.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? ConfidiaColors.darkSurface.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? ConfidiaColors.darkBorderSubtle : ConfidiaColors.lightBorderSubtle,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (isWide)
            SizedBox(
              width: 280,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: isDark
                      ? ConfidiaColors.darkSurfaceVariant
                      : ConfidiaColors.lightSurfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (q) {
                  if (q.isNotEmpty) context.go('/documents');
                },
              ),
            ),
          const SizedBox(width: ConfidiaSpacing.sm),
          if (actions != null) ...actions!,
          IconButton(
            tooltip: 'Scanner un document',
            onPressed: () => context.go('/scan'),
            icon: const Icon(Icons.document_scanner_outlined),
          ),
          Stack(
            children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => context.go('/notifications'),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              if (unread > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: ConfidiaColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          ThemeToggleButton(compact: !isWide),
          const SizedBox(width: ConfidiaSpacing.sm),
          if (auth.user != null)
            InkWell(
              onTap: () => context.go('/profile'),
              borderRadius: BorderRadius.circular(24),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: ConfidiaColors.primary.withValues(alpha: 0.15),
                child: Text(
                  auth.user!.initials,
                  style: const TextStyle(
                    color: ConfidiaColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
