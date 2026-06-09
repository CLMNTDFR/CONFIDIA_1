import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../shared/models/user_model.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_data.dart';
import 'confidia_button.dart';
import 'theme_toggle_button.dart';

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
    final path = GoRouterState.of(context).matchedLocation;
    final meta = _routeMeta(path);
    return AppTopBar(title: meta.$1, subtitle: meta.$2, showNotifications: showNotifications);
  }

  static (String, String?) _routeMeta(String path) {
    if (path.startsWith('/dashboard')) return ('Accueil', 'Widgets personnalisables');
    if (path.startsWith('/documents/')) return ('Document', 'Détail et analyse');
    if (path.startsWith('/documents')) return ('Documents', 'Bibliothèque');
    if (path.startsWith('/scan')) return ('Scanner', 'Capture photo');
    if (path.startsWith('/upload')) return ('Importer', 'Ajout de fichiers');
    if (path.startsWith('/payments/')) return ('Paiement', 'Détail et règlement');
    if (path.startsWith('/payments')) return ('Paiements', 'Factures et échéances');
    if (path.startsWith('/messaging/')) return ('Message', 'Analyse IA');
    if (path.startsWith('/messaging')) return ('Messagerie', 'Boîte unifiée');
    if (path.startsWith('/calendar')) return ('Calendrier', 'Échéances fusionnées');
    if (path.startsWith('/notifications')) return ('Notifications', 'Centre d\'alertes');
    if (path.startsWith('/profile')) return ('Profil', 'Compte et identité');
    if (path.startsWith('/settings')) return ('Paramètres', 'Préférences');
    if (path.startsWith('/admin')) return ('Administration', 'Plateforme');
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
        color: isDark ? ConfidiaColors.darkSurface.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: isDark ? ConfidiaColors.darkBorderSubtle : ConfidiaColors.lightBorderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) Text(subtitle!, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (isWide)
            SizedBox(
              width: 260,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? ConfidiaColors.darkSurfaceVariant : ConfidiaColors.lightSurfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onSubmitted: (q) { if (q.isNotEmpty) context.go('/documents'); },
              ),
            ),
          const SizedBox(width: ConfidiaSpacing.sm),
          if (showNotifications)
            ConfidiaIconButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Notifications',
              showBadge: unread > 0,
              onPressed: () => context.go('/notifications'),
            ),
          const SizedBox(width: 6),
          const ThemeToggleButton(compact: true),
          const SizedBox(width: 6),
          if (auth.user != null)
            _ProfileChip(user: auth.user!, onTap: () => context.go('/profile')),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _ProfileChip({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: ConfidiaColors.primary.withValues(alpha: 0.15),
                child: Text(user.initials, style: const TextStyle(color: ConfidiaColors.primary, fontWeight: FontWeight.w700, fontSize: 11)),
              ),
              if (MediaQuery.of(context).size.width >= 1100) ...[
                const SizedBox(width: 8),
                Text(user.firstName, style: Theme.of(context).textTheme.labelLarge),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
