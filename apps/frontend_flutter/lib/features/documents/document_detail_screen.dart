import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/spacing.dart';
import '../../shared/models/ai_insight_model.dart';
import '../../shared/models/document_model.dart';
import '../../shared/services/mock_ai_service.dart';
import '../../shared/widgets/cofid_ia_brand.dart';
import '../../shared/widgets/ai_streaming_text.dart';
import '../../shared/widgets/confidia_confirm_dialog.dart';
import '../../shared/widgets/confidia_menu.dart';
import '../../shared/widgets/confidia_snackbar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/confidia_page_reveal.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/status_badge.dart';
import 'document_edit_sheet.dart';
import 'documents_provider.dart';
import 'widgets/document_file_preview.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  bool _analysisComplete = false;
  bool _loadingPreview = true;
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
  }

  Future<void> _loadPreview() async {
    final notifier = ref.read(documentsProvider.notifier);
    if (ref.read(documentsProvider).byId(widget.documentId) == null) {
      await notifier.refresh();
    }
    final bytes = await notifier.loadBytes(widget.documentId);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loadingPreview = false;
    });
  }

  Future<void> _download() async {
    final message = await ref.read(documentsProvider.notifier).download(widget.documentId);
    if (!mounted) return;
    if (message != null) {
      showConfidiaSnackBar(context, message, type: ConfidiaSnackType.warning);
    } else {
      showConfidiaSnackBar(context, 'Téléchargement lancé', type: ConfidiaSnackType.success);
    }
  }

  Future<void> _edit(DocumentModel doc) async {
    await showDocumentEditSheet(context, doc);
  }

  Future<void> _confirmDelete(DocumentModel doc) async {
    final ok = await showConfidiaConfirmDialog(
      context,
      title: 'Supprimer le document ?',
      message: '« ${doc.title} » sera définitivement retiré de votre espace.',
      confirmLabel: 'Supprimer',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (ok != true || !mounted) return;
    final error = await ref.read(documentsProvider.notifier).deleteDocument(doc.id);
    if (!mounted) return;
    if (error != null) {
      showConfidiaSnackBar(context, error, type: ConfidiaSnackType.error);
      return;
    }
    showConfidiaSnackBar(context, 'Document supprimé', type: ConfidiaSnackType.success);
    if (!mounted) return;
    context.go('/documents');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(documentsProvider, (previous, next) {
      if (previous?.byId(widget.documentId) == null) return;
      if (next.byId(widget.documentId) != null) return;
      if (!context.mounted) return;
      context.go('/documents');
    });
    final docsState = ref.watch(documentsProvider);
    final doc = docsState.byId(widget.documentId);
    if (doc == null) {
      return Center(
        child: docsState.loading
            ? const CircularProgressIndicator()
            : const Text('Document introuvable'),
      );
    }
    final demo = ref.watch(authStateProvider).isDemoSession;
    final insight = const MockAiService().analyzeDocument(doc);
    final analysisText = demo ? _analysisText(insight, doc) : _liveAnalysisText(doc);

    return SingleChildScrollView(
      padding: ConfidiaInsets.page(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConfidiaPageReveal(
            index: 0,
            staggerCount: 4,
            child: _DocumentHeader(
              doc: doc,
              onDownload: _download,
              onEdit: () => _edit(doc),
              onDelete: () => _confirmDelete(doc),
            ),
          ),
          const SizedBox(height: ConfidiaSpacing.lg),
          ConfidiaPageReveal(
            index: 1,
            staggerCount: 4,
            child: _AiAnalysisSection(
              insight: demo
                  ? insight
                  : AiInsightModel(
                      summary: analysisText,
                      recommendedActions: const ['Télécharger', 'Classer plus tard'],
                      priority: AiPriority.low,
                      tags: doc.tags,
                    ),
              analysisText: analysisText,
              analysisComplete: _analysisComplete,
              onAnalysisComplete: () => setState(() => _analysisComplete = true),
            ),
          ),
          const SizedBox(height: ConfidiaSpacing.lg),
          ConfidiaPageReveal(
            index: 2,
            staggerCount: 4,
            child: DocumentFilePreview(
              doc: doc,
              bytes: _bytes,
              loading: _loadingPreview,
              onDownload: _download,
            ),
          ),
          const SizedBox(height: ConfidiaSpacing.lg),
          ConfidiaPageReveal(index: 3, staggerCount: 4, child: _DocumentMetadata(doc: doc)),
        ],
      ),
    );
  }

  String _liveAnalysisText(DocumentModel doc) {
    final buffer = StringBuffer(
      'Document enregistré dans votre espace. '
      'L\'extraction automatique des montants et échéances arrivera dans une prochaine version. '
      'En attendant, le fichier reste disponible en aperçu et en téléchargement.',
    );
    if (doc.category != null) {
      buffer.write('\n\nClassé dans « ${doc.category} ».');
    }
    return buffer.toString();
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
  final VoidCallback onDownload;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DocumentHeader({
    required this.doc,
    required this.onDownload,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Retour',
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
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Télécharger',
              icon: const Icon(Icons.download_outlined),
              onPressed: onDownload,
            ),
            ConfidiaMenuButton<String>(
              tooltip: 'Plus d\'actions',
              items: const [
                ConfidiaMenuEntry(
                  value: 'edit',
                  label: 'Modifier',
                  icon: Icons.edit_outlined,
                ),
                ConfidiaMenuEntry(
                  value: 'download',
                  label: 'Télécharger',
                  icon: Icons.download_outlined,
                ),
                ConfidiaMenuEntry(
                  value: 'delete',
                  label: 'Supprimer',
                  icon: Icons.delete_outline_rounded,
                  destructive: true,
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                  case 'download':
                    onDownload();
                  case 'delete':
                    onDelete();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _AiAnalysisSection extends StatefulWidget {
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
  State<_AiAnalysisSection> createState() => _AiAnalysisSectionState();
}

class _AiAnalysisSectionState extends State<_AiAnalysisSection> {
  bool _speaking = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      highlighted: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CofidIaPanelHeader(
            speaking: _speaking,
            trailing: AnimatedOpacity(
              opacity: widget.analysisComplete ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: widget.analysisComplete
                  ? StatusBadge(label: widget.insight.priority.label, color: widget.insight.priority.themeColor(context.palette))
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 16),
          AiStreamingText(
            text: widget.analysisText,
            showThinkingRobot: false,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.65,
                  color: isDark ? Colors.white.withValues(alpha: 0.92) : ConfidiaColors.lightTextPrimary,
                ),
            onStreamStart: () => setState(() => _speaking = true),
            onComplete: () {
              setState(() => _speaking = false);
              widget.onAnalysisComplete();
            },
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOutCubic,
            child: widget.analysisComplete && widget.insight.tags.isNotEmpty
                ? Padding(
                    key: const ValueKey('tags'),
                    padding: const EdgeInsets.only(top: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.insight.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ConfidiaColors.textSecondary(
                                  Theme.of(context).brightness == Brightness.dark,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ConfidiaColors.border(Theme.of(context).brightness == Brightness.dark)),
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

class _DocumentMetadata extends StatelessWidget {
  final DocumentModel doc;

  const _DocumentMetadata({required this.doc});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      _MetaItem(icon: Icons.category_outlined, label: 'Catégorie', value: doc.category ?? 'Non classé'),
      _MetaItem(icon: Icons.description_outlined, label: 'Type', value: doc.documentType ?? 'Non renseigné'),
      _MetaItem(icon: Icons.person_outline_rounded, label: 'Correspondant', value: doc.correspondent ?? 'N/A'),
      _MetaItem(icon: Icons.sd_storage_outlined, label: 'Taille', value: doc.fileSizeFormatted.isEmpty ? 'N/A' : doc.fileSizeFormatted),
      _MetaItem(icon: Icons.calendar_today_outlined, label: 'Créé', value: DateFormat('d MMM yyyy', 'fr_FR').format(doc.created)),
      _MetaItem(icon: Icons.update_rounded, label: 'Modifié', value: DateFormat('d MMM yyyy', 'fr_FR').format(doc.modified)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informations', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
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
            spacing: 8,
            runSpacing: 8,
            children: doc.tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ConfidiaColors.border(isDark)),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 15, color: ConfidiaColors.textSecondary(isDark)),
          const SizedBox(width: 8),
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
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
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
