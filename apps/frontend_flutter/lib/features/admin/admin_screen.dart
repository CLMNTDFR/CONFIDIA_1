import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/spacing.dart';
import '../../shared/widgets/confidia_page_reveal.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/stat_card.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    if (auth.user?.isAdmin != true) {
      return const Scaffold(
        body: Center(child: Text('Accès réservé aux administrateurs')),
      );
    }

    return SingleChildScrollView(
        padding: ConfidiaInsets.page(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConfidiaPageReveal(
              index: 0,
              staggerCount: 3,
              child: StatsRow(stats: [
                CompactStat(label: 'Utilisateurs', value: '3', icon: Icons.people_outline, color: context.palette.primary),
                CompactStat(label: 'Documents', value: '6', icon: Icons.description_outlined, color: context.palette.accent),
                CompactStat(label: 'Services', value: '3', icon: Icons.cloud_outlined, color: context.palette.secondary),
                CompactStat(label: 'Uptime', value: '99.9%', icon: Icons.trending_up, color: ConfidiaColors.success),
              ]),
            ),
            const SizedBox(height: ConfidiaSpacing.lg),
            ConfidiaPageReveal(
              index: 1,
              staggerCount: 3,
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(ConfidiaSpacing.lg),
                      child: Text('Services', style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    _ServiceRow(name: 'Keycloak', status: 'En ligne', url: 'localhost:8080', icon: Icons.vpn_key),
                    const Divider(height: 1),
                    _ServiceRow(name: 'Paperless-ngx', status: 'En ligne', url: 'localhost:8001', icon: Icons.description),
                    const Divider(height: 1),
                    _ServiceRow(name: 'Nextcloud', status: 'En ligne', url: 'localhost:8081', icon: Icons.cloud),
                    const Divider(height: 1),
                    _ServiceRow(name: 'FastAPI Backend', status: 'En ligne', url: 'localhost:8000', icon: Icons.api),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(height: ConfidiaSpacing.lg),
            ConfidiaPageReveal(
              index: 2,
              staggerCount: 4,
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(ConfidiaSpacing.lg),
                      child: Text('Utilisateurs', style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    _UserRow(name: 'Admin CONFIDIA', email: 'admin@confidia.local', role: 'ADMIN'),
                    const Divider(height: 1),
                    _UserRow(name: 'Jean Dupont', email: 'user@confidia.local', role: 'USER'),
                    const Divider(height: 1),
                    _UserRow(name: 'Marie Martin', email: 'manager@confidia.local', role: 'MANAGER'),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(height: ConfidiaSpacing.lg),
            ConfidiaPageReveal(
              index: 3,
              staggerCount: 4,
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg),
              child: Card(
                child: ListTile(
                  leading: Icon(Icons.account_tree_rounded, color: context.palette.primary),
                  title: const Text('Gouvernance & accès'),
                  subtitle: const Text('Organigramme, rôles, droits et IA planning'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/access-control'),
                ),
              ),
            ),
            ),
            const SizedBox(height: ConfidiaSpacing.xxl),
          ],
        ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final String name;
  final String status;
  final String url;
  final IconData icon;

  const _ServiceRow({
    required this.name,
    required this.status,
    required this.url,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: context.palette.primary),
      title: Text(name),
      subtitle: Text(url),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ConfidiaColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          status,
          style: const TextStyle(color: ConfidiaColors.success, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final String name;
  final String email;
  final String role;

  const _UserRow({required this.name, required this.email, required this.role});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: context.palette.primary.withValues(alpha: 0.15),
        child: Text(name[0], style: TextStyle(color: context.palette.primary)),
      ),
      title: Text(name),
      subtitle: Text(email),
      trailing: Chip(label: Text(role)),
    );
  }
}
