import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/widgets/confidia_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/stagger_fade.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final docCount = MockData.documents.length;
    final eventCount = MockData.calendarEvents.length;
    final unread = MockData.notifications.where((n) => !n.read).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ConfidiaSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              StaggerFade(
                index: 0,
                child: GlassCard(
                  highlighted: true,
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: ConfidiaColors.primary.withValues(alpha: 0.15),
                            child: Text(user.initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ConfidiaColors.primary)),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: ConfidiaColors.success, shape: BoxShape.circle),
                            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
                      Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        children: user.roles.map((r) => Chip(label: Text(r), visualDensity: VisualDensity.compact)).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ConfidiaSpacing.md),
              StaggerFade(
                index: 1,
                child: Row(
                  children: [
                    Expanded(child: _MetricTile(label: 'Documents', value: '$docCount', icon: Icons.folder_copy_rounded, color: ConfidiaColors.primary)),
                    const SizedBox(width: ConfidiaSpacing.sm),
                    Expanded(child: _MetricTile(label: 'Échéances', value: '$eventCount', icon: Icons.event_rounded, color: ConfidiaColors.accent)),
                    const SizedBox(width: ConfidiaSpacing.sm),
                    Expanded(child: _MetricTile(label: 'Alertes', value: '$unread', icon: Icons.notifications_rounded, color: ConfidiaColors.secondary)),
                  ],
                ),
              ),
              const SizedBox(height: ConfidiaSpacing.md),
              StaggerFade(
                index: 2,
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ProfileTile(icon: Icons.person_rounded, title: 'Informations', subtitle: '${user.firstName} ${user.lastName}'),
                      const Divider(height: 1),
                      _ProfileTile(icon: Icons.email_rounded, title: 'Email', subtitle: user.email),
                      const Divider(height: 1),
                      _ProfileTile(icon: Icons.phone_rounded, title: 'Téléphone', subtitle: user.phone ?? 'Non renseigné'),
                      const Divider(height: 1),
                      _ProfileTile(icon: Icons.business_rounded, title: 'Organisation', subtitle: user.organization ?? 'Non renseigné'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ConfidiaSpacing.md),
              StaggerFade(
                index: 3,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Espace CONFIDIA', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 12),
                      _ActionRow(icon: Icons.folder_copy_rounded, label: 'Mes documents', onTap: () => context.go('/documents')),
                      _ActionRow(icon: Icons.document_scanner_rounded, label: 'Scanner un document', onTap: () => context.go('/scan')),
                      _ActionRow(icon: Icons.calendar_month_rounded, label: 'Mon calendrier', onTap: () => context.go('/calendar')),
                      _ActionRow(icon: Icons.shield_rounded, label: 'Identité numérique', subtitle: 'Bientôt disponible', onTap: () {}),
                      _ActionRow(icon: Icons.lock_rounded, label: 'Sécurité et accès', onTap: () => context.go('/settings')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ConfidiaSpacing.lg),
              StaggerFade(
                index: 4,
                child: Row(
                  children: [
                    Expanded(child: ConfidiaButton(label: 'Paramètres', icon: Icons.tune_rounded, outlined: true, compact: true, onPressed: () => context.go('/settings'))),
                    const SizedBox(width: ConfidiaSpacing.sm),
                    Expanded(child: ConfidiaButton(label: 'Déconnexion', icon: Icons.logout_rounded, compact: true, onPressed: () async {
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    })),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? ConfidiaColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ConfidiaColors.border(isDark)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: ConfidiaColors.primary, size: 20),
      title: Text(title, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text(subtitle),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _ActionRow({required this.icon, required this.label, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: ConfidiaColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: ConfidiaColors.primary),
      ),
      title: Text(label),
      subtitle: subtitle != null ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall) : null,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
