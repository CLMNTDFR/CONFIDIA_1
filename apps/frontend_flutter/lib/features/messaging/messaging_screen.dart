import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_ecosystem.dart';
import '../../shared/models/email_model.dart';
import '../../shared/widgets/confidia_glow_chip.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/brands/brand_assets.dart';
import '../../shared/widgets/brand_icon.dart';
import '../../shared/widgets/provider_chip.dart';
import 'messaging_provider.dart';

class MessagingScreen extends ConsumerWidget {
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mailFilterProvider);
    final emails = ref.watch(messagingProvider.notifier).inbox;
    final filtered = filter == null ? emails : emails.where((e) => e.provider == filter).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (MediaQuery.of(context).size.width >= 900)
          SizedBox(width: 220, child: _AccountsSidebar(selected: filter, onSelect: (p) => ref.read(mailFilterProvider.notifier).state = p)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConfidiaGlowChipScroll(
                children: [
                  ConfidiaGlowChip(
                    label: 'Tous',
                    icon: Icons.inbox_rounded,
                    selected: filter == null,
                    onTap: () => ref.read(mailFilterProvider.notifier).state = null,
                  ),
                  ...MailProvider.values.map(
                    (p) => ConfidiaGlowChip(
                      label: p.label,
                      selected: filter == p,
                      accentColor: p.brandColor,
                      leading: BrandIcon(
                        assetPath: p.logoAsset,
                        fallbackIcon: p.icon,
                        fallbackColor: p.brandColor,
                        size: 14,
                      ),
                      onTap: () => ref.read(mailFilterProvider.notifier).state = p,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Aucun message'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(ConfidiaSpacing.lg),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, i) => _EmailTile(email: filtered[i]),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountsSidebar extends StatelessWidget {
  final MailProvider? selected;
  final ValueChanged<MailProvider?> onSelect;

  const _AccountsSidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: ConfidiaSpacing.lg, top: ConfidiaSpacing.lg),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Comptes', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _AccountTile(label: 'Boîte unifiée', email: '${MockEcosystem.emails.length} messages', provider: null, selected: selected == null, onTap: () => onSelect(null)),
            const Divider(height: 16),
            ...MockEcosystem.connectedAccounts.map((acc) => _AccountTile(
                  label: acc.provider.label,
                  email: acc.email,
                  provider: acc.provider,
                  selected: selected == acc.provider,
                  onTap: () => onSelect(acc.provider),
                )),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final String label;
  final String email;
  final MailProvider? provider;
  final bool selected;
  final VoidCallback onTap;

  const _AccountTile({required this.label, required this.email, required this.provider, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ConfidiaColors.primary.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              if (provider != null) MailProviderChip(provider: provider!, compact: true) else const Icon(Icons.inbox_rounded, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(email, style: Theme.of(context).textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
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

class _EmailTile extends ConsumerWidget {
  final EmailModel email;

  const _EmailTile({required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: email.isRead ? Colors.transparent : ConfidiaColors.primary.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          ref.read(messagingProvider.notifier).markRead(email.id);
          context.go('/messaging/${email.id}');
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ConfidiaColors.border(isDark)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: email.provider.brandColor.withValues(alpha: 0.12),
                child: BrandIcon(
                  assetPath: email.provider.logoAsset,
                  fallbackIcon: email.provider.icon,
                  fallbackColor: email.provider.brandColor,
                  size: 22,
                  borderRadius: 10,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            email.sender,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: email.isRead ? FontWeight.w500 : FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        MailProviderChip(provider: email.provider, compact: true),
                        const SizedBox(width: 6),
                        Text(DateFormat('d MMM', 'fr_FR').format(email.receivedAt), style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                    Text(email.subject, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: email.isRead ? null : FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(email.preview, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (email.isStarred) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.star_rounded, size: 16, color: ConfidiaColors.warning)),
              if (email.isProcessed) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.check_circle_rounded, size: 16, color: ConfidiaColors.success)),
            ],
          ),
        ),
      ),
    );
  }
}
