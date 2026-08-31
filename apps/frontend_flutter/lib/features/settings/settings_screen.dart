import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_ecosystem.dart';
import '../../shared/models/connected_account_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/brands/brand_assets.dart';
import '../../shared/widgets/brand_icon.dart';
import '../../shared/widgets/confidia_demo_badge.dart';
import '../../shared/widgets/confidia_palette_picker.dart';
import '../../shared/widgets/confidia_switch.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/logout_button.dart';
import '../../shared/widgets/provider_chip.dart';
import '../../shared/widgets/status_badge.dart';
import '../onboarding/onboarding_targets.dart';
import '../profile/profile_password_sheet.dart';

void _noop(bool _) {}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final paletteId = ref.watch(colorPaletteProvider);

    return ListView(
      padding: ConfidiaInsets.page(context),
      children: [
        _SectionTitle(label: 'Organisation & accès', demo: true),
        const SizedBox(height: 8),
        KeyedSubtree(
          key: OnboardingTargets.gouvernanceTile,
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: _CompactActionTile(
              icon: Icons.account_tree_rounded,
              title: 'Gouvernance & accès',
              subtitle: 'Organigramme, rôles, droits et assistant IA',
              demo: true,
              onTap: () => context.go('/access-control'),
            ),
          ),
        ),
        const SizedBox(height: ConfidiaSpacing.md),
        _SectionTitle(label: 'Apparence'),
        const SizedBox(height: 8),
        KeyedSubtree(
          key: OnboardingTargets.appearanceSection,
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ConfidiaSwitchTile(
                  title: 'Mode sombre',
                  subtitle: 'Thème clair ou sombre',
                  value: isDark,
                  onChanged: (v) => ref.read(themeModeProvider.notifier).state = v,
                ),
                Divider(height: 1, color: ConfidiaColors.border(Theme.of(context).brightness == Brightness.dark)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thème couleur',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text('Palette de marque bleu ou rose', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 8),
                      ConfidiaPalettePicker(
                        value: paletteId,
                        onChanged: (id) => ref.read(colorPaletteProvider.notifier).state = id,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ConfidiaSpacing.md),
        _SectionTitle(label: 'Notifications'),
        const SizedBox(height: 8),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ConfidiaSwitchTile(title: 'Notifications push', value: true, onChanged: _noop),
              Divider(height: 1, color: ConfidiaColors.border(Theme.of(context).brightness == Brightness.dark)),
              ConfidiaSwitchTile(title: 'Rappels d\'échéances', value: true, onChanged: _noop),
              Divider(height: 1, color: ConfidiaColors.border(Theme.of(context).brightness == Brightness.dark)),
              ConfidiaSwitchTile(title: 'Alertes documents', value: true, onChanged: _noop),
            ],
          ),
        ),
        const SizedBox(height: ConfidiaSpacing.md),
        _SectionTitle(label: 'Comptes connectés', demo: true),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 640 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: ConfidiaSpacing.sm,
                mainAxisSpacing: ConfidiaSpacing.sm,
                mainAxisExtent: 148,
              ),
              itemCount: MockEcosystem.connectedAccounts.length,
              itemBuilder: (context, i) => _ConnectedAccountCard(account: MockEcosystem.connectedAccounts[i]),
            );
          },
        ),
        const SizedBox(height: ConfidiaSpacing.md),
        _SectionTitle(label: 'Stockage documentaire'),
        const SizedBox(height: 8),
        ...MockEcosystem.storageServices.map((svc) {
              final svcColor = svc.id == 'paperless' ? context.palette.primary : svc.color;
              return Padding(
              padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        BrandIcon(
                          assetPath: BrandAssets.ifBundled(
                            svc.id == 'paperless' ? BrandAssets.paperless : BrandAssets.nextcloud,
                          ),
                          adaptForTheme: true,
                          fallbackIcon: svc.icon,
                          fallbackColor: svcColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(svc.name, style: Theme.of(context).textTheme.labelLarge)),
                        StatusBadge(
                          label: svc.connected ? 'Connecté' : 'Déconnecté',
                          color: svc.connected ? ConfidiaColors.success : ConfidiaColors.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(svc.description, style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: svc.usageRatio,
                        minHeight: 4,
                        backgroundColor: ConfidiaColors.border(Theme.of(context).brightness == Brightness.dark),
                        color: svcColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${svc.storageUsed} / ${svc.storageTotal} · Sync ${DateFormat('d MMM HH:mm', 'fr_FR').format(svc.lastSync)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            );
            }),
        const SizedBox(height: ConfidiaSpacing.md),
        _SectionTitle(label: 'Sécurité'),
        const SizedBox(height: 8),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _CompactActionTile(
                icon: Icons.lock_outline_rounded,
                title: 'Changer le mot de passe',
                onTap: () => showProfilePasswordSheet(context),
              ),
              const Divider(height: 1),
              ConfidiaSwitchTile(
                title: 'Authentification biométrique',
                value: false,
                onChanged: _noop,
              ),
            ],
          ),
        ),
        const SizedBox(height: ConfidiaSpacing.md),
        _SectionTitle(label: 'À propos'),
        const SizedBox(height: 8),
        GlassCard(
          padding: EdgeInsets.zero,
          child: _CompactActionTile(
            icon: Icons.info_outline_rounded,
            title: 'CONFIDIA',
            subtitle: 'Version 0.1.0 · MVP',
            onTap: () {},
            showChevron: false,
          ),
        ),
        const SizedBox(height: ConfidiaSpacing.lg),
        const LogoutButton(),
        const SizedBox(height: ConfidiaSpacing.xl),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final bool demo;

  const _SectionTitle({required this.label, this.demo = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark),
                letterSpacing: 0.4,
              ),
        ),
        if (demo) ...[
          const SizedBox(width: 8),
          const ConfidiaDemoBadge(compact: true),
        ],
      ],
    );
  }
}

class _CompactActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showChevron;
  final bool demo;

  const _CompactActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.showChevron = true,
    this.demo = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Icon(icon, size: 18, color: context.palette.primary),
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle!, style: Theme.of(context).textTheme.labelSmall) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (demo) const ConfidiaDemoBadge(compact: true),
          if (demo && showChevron) const SizedBox(width: 8),
          if (showChevron) const Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _ConnectedAccountCard extends StatelessWidget {
  final ConnectedAccountModel account;

  const _ConnectedAccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              MailProviderChip(provider: account.provider, compact: true),
              const Spacer(),
              const ConfidiaDemoBadge(compact: true),
              const SizedBox(width: 6),
              const StatusBadge(label: 'Connecté', color: ConfidiaColors.success),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            account.email,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _AccountStatChip(
                icon: Icons.sync_rounded,
                label: DateFormat('d MMM · HH:mm', 'fr_FR').format(account.lastSync),
                isDark: isDark,
              ),
              _AccountStatChip(icon: Icons.storage_rounded, label: account.dataVolume, isDark: isDark),
              _AccountStatChip(icon: Icons.folder_rounded, label: '${account.documentsImported} docs', isDark: isDark),
              _AccountStatChip(icon: Icons.mail_rounded, label: '${account.emailsSynced} mails', isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _AccountStatChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: ConfidiaColors.textSecondary(isDark)),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
