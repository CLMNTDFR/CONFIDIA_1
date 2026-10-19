import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/spacing.dart';
import '../../shared/models/document_model.dart';
import '../../shared/widgets/confidia_confirm_dialog.dart';
import '../../shared/widgets/confidia_page_reveal.dart';
import '../../shared/widgets/confidia_snackbar.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/premium_search_field.dart';
import '../../shared/widgets/workspace_empty_hint.dart';
import 'document_purge_sheet.dart';
import 'documents_provider.dart';
import 'documents_screen.dart';

class DocumentsTrashScreen extends ConsumerStatefulWidget {
  const DocumentsTrashScreen({super.key});

  @override
  ConsumerState<DocumentsTrashScreen> createState() => _DocumentsTrashScreenState();
}

class _DocumentsTrashScreenState extends ConsumerState<DocumentsTrashScreen> {
  String _query = '';
  String? _busyId;
  final _when = DateFormat('d MMM yyyy', 'fr_FR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentsProvider.notifier).refreshTrash();
    });
  }

  List<DocumentModel> _visible(List<DocumentModel> trash) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return trash;
    return trash.where((doc) {
      return doc.title.toLowerCase().contains(q) ||
          (doc.correspondent?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _restore(DocumentModel doc) async {
    if (_busyId != null) return;
    setState(() => _busyId = doc.id);
    final error = await ref.read(documentsProvider.notifier).restoreDocument(doc.id);
    if (!mounted) return;
    setState(() => _busyId = null);
    showConfidiaSnackBar(
      context,
      error ?? 'Document restauré',
      type: error == null ? ConfidiaSnackType.success : ConfidiaSnackType.error,
    );
  }

  Future<void> _purge(DocumentModel doc) async {
    if (_busyId != null) return;
    setState(() => _busyId = doc.id);
    final result = await ref.read(documentsProvider.notifier).eventLinks(doc.id);
    if (!mounted) return;
    setState(() => _busyId = null);
    if (result.error != null || result.links == null) {
      showConfidiaSnackBar(
        context,
        result.error ?? 'Impossible de lire les liens',
        type: ConfidiaSnackType.error,
      );
      return;
    }
    final links = result.links!;
    final live = links.where((link) => !link.deleted).toList();
    List<DocumentPurgeDecision> decisions;
    if (live.isEmpty) {
      final archived = links.length;
      final extra = archived == 0
          ? ''
          : archived == 1
              ? ' 1 événement déjà retiré de l\'agenda sera détaché.'
              : ' $archived événements déjà retirés de l\'agenda seront détachés.';
      final ok = await showConfidiaConfirmDialog(
        context,
        title: 'Supprimer définitivement ?',
        message: '« ${doc.title} » et son fichier seront effacés.$extra Cette action est irréversible.',
        confirmLabel: 'Supprimer définitivement',
        icon: Icons.delete_forever_rounded,
        destructive: true,
      );
      if (ok != true || !mounted) return;
      decisions = const [];
    } else {
      final chosen = await showDocumentPurgeSheet(context: context, doc: doc, links: links);
      if (chosen == null || !mounted) return;
      decisions = chosen;
    }
    setState(() => _busyId = doc.id);
    final error = await ref.read(documentsProvider.notifier).purgeDocument(doc.id, decisions);
    if (!mounted) return;
    setState(() => _busyId = null);
    showConfidiaSnackBar(
      context,
      error ?? 'Document supprimé définitivement',
      type: error == null ? ConfidiaSnackType.success : ConfidiaSnackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final docsState = ref.watch(documentsProvider);
    final docs = _visible(docsState.trash);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              ConfidiaSpacing.md,
              ConfidiaSpacing.sm,
              ConfidiaSpacing.md,
              ConfidiaSpacing.sm,
            ),
            child: PremiumSearchField(
              hintText: 'Rechercher dans la corbeille…',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        ),
        if (docsState.trashLoading && docsState.trash.isEmpty)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
        else if (docsState.error != null && docsState.trash.isEmpty)
          SliverFillRemaining(child: Center(child: Text(docsState.error!)))
        else if (docsState.trash.isEmpty)
          const SliverFillRemaining(
            child: WorkspaceEmptyHint(
              expand: true,
              icon: Icons.delete_outline_rounded,
              title: 'La corbeille est vide',
              subtitle: 'Les documents supprimés apparaissent ici. Vous pouvez les restaurer ou les effacer.',
            ),
          )
        else if (docs.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('Aucun document ne correspond.')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg),
            sliver: SliverList.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: ConfidiaSpacing.sm),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final busy = _busyId == doc.id;
                final removed = doc.deletedAt == null
                    ? 'Dans la corbeille'
                    : 'Retiré le ${_when.format(doc.deletedAt!.toLocal())}';
                return ConfidiaPageReveal(
                  index: index,
                  staggerCount: ConfidiaPageRevealTiming.staggerCount(
                    context,
                    docs.length,
                    itemExtent: 120,
                    overhead: 180,
                  ),
                  child: DocumentListTile(
                    doc: doc,
                    isDark: isDark,
                    whenLabel: removed,
                    actions: busy
                        ? const Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Row(
                            children: [
                              TextButton(
                                onPressed: () => _restore(doc),
                                child: const Text('Restaurer'),
                              ),
                              TextButton(
                                onPressed: () => _purge(doc),
                                child: Text(
                                  'Supprimer',
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: ConfidiaInsets.scrollTail(context))),
      ],
    );
  }
}
