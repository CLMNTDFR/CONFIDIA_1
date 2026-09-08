import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/widgets/confidia_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../documents/document_add_sheet.dart';
import '../onboarding/guided_tour_provider.dart';

final firstLoginBannerDismissedProvider = StateProvider<bool>((ref) => false);

class FirstLoginWelcomeCard extends ConsumerWidget {
  const FirstLoginWelcomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      highlighted: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Votre espace est prêt',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Masquer',
                onPressed: () => ref.read(firstLoginBannerDismissedProvider.notifier).state = true,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Aucun document ni rendez-vous pour l\'instant. Importez une pièce, ou lancez la visite guidée comme en mode découverte.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ConfidiaColors.textSecondary(isDark),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: ConfidiaSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ConfidiaButton(
                label: 'Importer un document',
                compact: true,
                icon: Icons.upload_file_rounded,
                onPressed: () => showDocumentAddSheet(context),
              ),
              ConfidiaButton(
                label: 'Lancer la visite guidée',
                compact: true,
                outlined: true,
                onPressed: () => ref.read(guidedTourProvider.notifier).startNow(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
