import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/spacing.dart';
import '../../shared/widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);

    return ListView(
              padding: const EdgeInsets.all(ConfidiaSpacing.lg),
              children: [
                Text('Apparence', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: ConfidiaSpacing.sm),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    title: const Text('Mode sombre'),
                    subtitle: const Text('Basculer entre thème clair et sombre'),
                    value: isDark,
                    onChanged: (v) => ref.read(themeModeProvider.notifier).state = v,
                  ),
                ),
                const SizedBox(height: ConfidiaSpacing.lg),
                Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: ConfidiaSpacing.sm),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Notifications push'),
                        value: true,
                        onChanged: (_) {},
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Rappels d\'échéances'),
                        value: true,
                        onChanged: (_) {},
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Alertes documents'),
                        value: true,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ConfidiaSpacing.lg),
                Text('Sécurité', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: ConfidiaSpacing.sm),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Changer le mot de passe'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.fingerprint),
                        title: const Text('Authentification biométrique'),
                        trailing: Switch(value: false, onChanged: (_) {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ConfidiaSpacing.lg),
                Text('À propos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: ConfidiaSpacing.sm),
                const GlassCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('CONFIDIA'),
                    subtitle: Text('Version 0.1.0 · MVP'),
                  ),
                ),
                const SizedBox(height: ConfidiaSpacing.xl),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                ),
                const SizedBox(height: ConfidiaSpacing.xxl),
              ],
    );
  }
}
