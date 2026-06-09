import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_ecosystem.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/provider_chip.dart';
import '../../shared/widgets/status_badge.dart';

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
                Text('Comptes connectés', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: ConfidiaSpacing.sm),
                ...MockEcosystem.connectedAccounts.map((acc) => Padding(
                      padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                MailProviderChip(provider: acc.provider),
                                const Spacer(),
                                const StatusBadge(label: 'Connecté', color: ConfidiaColors.success),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(acc.email, style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            _SettingMetric(label: 'Dernière sync', value: DateFormat('d MMM · HH:mm', 'fr_FR').format(acc.lastSync)),
                            _SettingMetric(label: 'Volume synchronisé', value: acc.dataVolume),
                            _SettingMetric(label: 'Documents importés', value: '${acc.documentsImported}'),
                            _SettingMetric(label: 'Emails synchronisés', value: '${acc.emailsSynced}'),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: ConfidiaSpacing.lg),
                Text('Stockage documentaire', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: ConfidiaSpacing.sm),
                ...MockEcosystem.storageServices.map((svc) => Padding(
                      padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(svc.icon, color: svc.color),
                                const SizedBox(width: 10),
                                Expanded(child: Text(svc.name, style: Theme.of(context).textTheme.titleSmall)),
                                StatusBadge(label: svc.connected ? 'Connecté' : 'Déconnecté', color: svc.connected ? ConfidiaColors.success : ConfidiaColors.error),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(svc.description, style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: svc.usageRatio, minHeight: 6, backgroundColor: ConfidiaColors.border(Theme.of(context).brightness == Brightness.dark), color: svc.color),
                            ),
                            const SizedBox(height: 6),
                            Text('${svc.storageUsed} utilisés sur ${svc.storageTotal}', style: Theme.of(context).textTheme.labelSmall),
                            Text('Sync · ${DateFormat('d MMM HH:mm', 'fr_FR').format(svc.lastSync)}', style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ),
                    )),
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

class _SettingMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SettingMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
