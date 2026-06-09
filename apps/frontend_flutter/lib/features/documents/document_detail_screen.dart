import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_data.dart';

class DocumentDetailScreen extends StatelessWidget {
  final int documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    final doc = MockData.documents.firstWhere(
      (d) => d.id == documentId,
      orElse: () => MockData.documents.first,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/documents'),
        ),
        title: Text(doc.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.download_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ConfidiaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Container(
                height: 400,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ConfidiaColors.darkSurfaceVariant,
                  borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 64, color: ConfidiaColors.primary.withValues(alpha: 0.5)),
                    const SizedBox(height: ConfidiaSpacing.md),
                    Text('Aperçu du document', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: ConfidiaSpacing.sm),
                    Text('Intégration Paperless-ngx', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ConfidiaSpacing.lg),
            Text(doc.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: ConfidiaSpacing.md),
            _InfoRow(label: 'Catégorie', value: doc.category ?? 'Non classé'),
            _InfoRow(label: 'Type', value: doc.documentType ?? '• Non renseigné'),
            _InfoRow(label: 'Correspondant', value: doc.correspondent ?? '• Non renseigné'),
            _InfoRow(label: 'Taille', value: doc.fileSizeFormatted),
            _InfoRow(label: 'Créé le', value: DateFormat('d MMMM yyyy', 'fr_FR').format(doc.created)),
            _InfoRow(label: 'Modifié le', value: DateFormat('d MMMM yyyy', 'fr_FR').format(doc.modified)),
            const SizedBox(height: ConfidiaSpacing.md),
            Text('Tags', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: ConfidiaSpacing.sm),
            Wrap(
              spacing: ConfidiaSpacing.sm,
              runSpacing: ConfidiaSpacing.sm,
              children: doc.tags
                  .map((tag) => Chip(
                        label: Text('#$tag'),
                        backgroundColor: ConfidiaColors.secondary.withValues(alpha: 0.1),
                      ))
                  .toList(),
            ),
            const SizedBox(height: ConfidiaSpacing.lg),
            Text('Analyse IA (simulée)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: ConfidiaSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(ConfidiaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: ConfidiaColors.secondary, size: 18),
                        const SizedBox(width: ConfidiaSpacing.sm),
                        Text('Résumé', style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: ConfidiaSpacing.sm),
                    Text(
                      'Document administratif de type ${doc.documentType ?? 'général'}. '
                      'Classification automatique en cours via MockAIProvider.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
