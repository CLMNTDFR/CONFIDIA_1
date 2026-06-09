import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/ai_insight_model.dart';
import '../../shared/models/document_model.dart';
import '../../shared/services/mock_ai_service.dart';
import '../../shared/widgets/ai_streaming_text.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/status_badge.dart';

class DocumentDetailScreen extends StatefulWidget {
  final int documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _analysisComplete = false;

  @override
  Widget build(BuildContext context) {
    final doc = MockData.documents.firstWhere(
      (d) => d.id == widget.documentId,
      orElse: () => MockData.documents.first,
    );
    final insight = const MockAiService().analyzeDocument(doc);
    final analysisText = _analysisText(insight, doc);

    return SingleChildScrollView(
      padding: ConfidiaInsets.page(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DocumentHeader(doc: doc),
          const SizedBox(height: ConfidiaSpacing.lg),
          _AiAnalysisSection(
            insight: insight,
            analysisText: analysisText,
            analysisComplete: _analysisComplete,
            onAnalysisComplete: () => setState(() => _analysisComplete = true),
          ),
          const SizedBox(height: ConfidiaSpacing.lg),
          _DocumentPreview(),
          const SizedBox(height: ConfidiaSpacing.lg),
          _DocumentMetadata(doc: doc),
        ],
      ),
    );
  }

  String _analysisText(AiInsightModel insight, DocumentModel doc) {
    final buffer = StringBuffer(insight.summary);
    if (insight.detectedAmount != null) {
      buffer.write(' Montant détecté : ${insight.detectedAmount!.toStringAsFixed(2)} €.');
    }
    if (insight.detectedDeadline != null) {
      buffer.write(' Échéance : ${DateFormat('d MMMM yyyy', 'fr_FR').format(insight.detectedDeadline!)}.');
    }
    if (insight.recommendedActions.isNotEmpty) {
      buffer.write('\n\nActions suggérées : ${insight.recommendedActions.join(' · ')}.');
    }
    if (doc.category != null) {
      buffer.write('\n\nClassé dans « ${doc.category} » avec ${doc.tags.length} étiquette${doc.tags.length > 1 ? 's' : ''}.');
    }
    return buffer.toString();
  }
}

class _DocumentHeader extends StatelessWidget {
  final DocumentModel doc;

  const _DocumentHeader({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => context.go('/documents'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doc.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (doc.correspondent != null) ...[
                const SizedBox(height: 4),
                Text(doc.correspondent!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.download_outlined), onPressed: () {}),
        IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.share_outlined), onPressed: () {}),
        IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }
}

class _AiAnalysisSection extends StatelessWidget {
  final AiInsightModel insight;
  final String analysisText;
  final bool analysisComplete;
  final VoidCallback onAnalysisComplete;

  const _AiAnalysisSection({
    required this.insight,
    required this.analysisText,
    required this.analysisComplete,
    required this.onAnalysisComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      highlighted: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => ConfidiaColors.brandGradient.createShader(bounds),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text('Analyse IA', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              AnimatedOpacity(
                opacity: analysisComplete ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                child: analysisComplete ? StatusBadge(label: insight.priority.label, color: insight.priority.color) : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AiStreamingText(
            text: analysisText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.65,
                  color: isDark ? Colors.white.withValues(alpha: 0.92) : ConfidiaColors.lightTextPrimary,
                ),
            onComplete: onAnalysisComplete,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOutCubic,
            child: analysisComplete && insight.tags.isNotEmpty
                ? Padding(
                    key: const ValueKey('tags'),
                    padding: const EdgeInsets.only(top: 14),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: insight.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ConfidiaColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: ConfidiaColors.secondary.withValues(alpha: 0.2)),
                              ),
                              child: Text('#$tag', style: Theme.of(context).textTheme.labelSmall),
                            ),
                          )
                          .toList(),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aperçu', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          height: 340,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? ConfidiaColors.darkSurfaceVariant : ConfidiaColors.lightSurfaceElevated,
            borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
            border: Border.all(color: ConfidiaColors.border(isDark)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.picture_as_pdf_rounded, size: 52, color: ConfidiaColors.primary.withValues(alpha: 0.45)),
              const SizedBox(height: 12),
              Text('Aperçu du document', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text('Intégration Paperless-ngx', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentMetadata extends StatelessWidget {
  final DocumentModel doc;

  const _DocumentMetadata({required this.doc});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      _MetaItem(icon: Icons.category_outlined, label: 'Catégorie', value: doc.category ?? 'Non classé'),
      _MetaItem(icon: Icons.description_outlined, label: 'Type', value: doc.documentType ?? 'Non renseigné'),
      _MetaItem(icon: Icons.person_outline_rounded, label: 'Correspondant', value: doc.correspondent ?? '—'),
      _MetaItem(icon: Icons.sd_storage_outlined, label: 'Taille', value: doc.fileSizeFormatted.isEmpty ? '—' : doc.fileSizeFormatted),
      _MetaItem(icon: Icons.calendar_today_outlined, label: 'Créé', value: DateFormat('d MMM yyyy', 'fr_FR').format(doc.created)),
      _MetaItem(icon: Icons.update_rounded, label: 'Modifié', value: DateFormat('d MMM yyyy', 'fr_FR').format(doc.modified)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informations', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 2 : 1;
              final tileWidth = columns == 2 ? (constraints.maxWidth - 8) / 2 : constraints.maxWidth;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: tileWidth,
                        child: _MetaTile(item: item, isDark: isDark),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
        if (doc.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: doc.tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ConfidiaColors.border(isDark)),
                    ),
                    child: Text(tag, style: Theme.of(context).textTheme.labelSmall),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _MetaItem {
  final IconData icon;
  final String label;
  final String value;

  const _MetaItem({required this.icon, required this.label, required this.value});
}

class _MetaTile extends StatelessWidget {
  final _MetaItem item;
  final bool isDark;

  const _MetaTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ConfidiaColors.border(isDark).withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 15, color: ConfidiaColors.textSecondary(isDark)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.4,
                        color: ConfidiaColors.textSecondary(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
