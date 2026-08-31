import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/models/document_model.dart';
import '../../shared/widgets/confidia_glow_chip.dart';
import '../../shared/widgets/premium_search_field.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/confidia_page_reveal.dart';
import 'document_source_actions.dart';
import 'documents_provider.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  final String? initialCategory;

  const DocumentsScreen({super.key, this.initialCategory});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String _searchQuery = '';
  late String _selectedCategory;
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategory?.trim();
    _selectedCategory = (initial != null && initial.isNotEmpty) ? initial : 'Tous';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentsProvider.notifier).refresh();
    });
  }

  @override
  void didUpdateWidget(covariant DocumentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialCategory?.trim();
    final prev = oldWidget.initialCategory?.trim();
    if (next != prev) {
      setState(() => _selectedCategory = (next != null && next.isNotEmpty) ? next : 'Tous');
    }
  }

  List<DocumentModel> get _filteredDocs {
    var docs = ref.watch(documentsProvider).items;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      docs = docs.where((d) =>
          d.title.toLowerCase().contains(q) ||
          (d.correspondent?.toLowerCase().contains(q) ?? false) ||
          d.tags.any((t) => t.toLowerCase().contains(q))).toList();
    }
    if (_selectedCategory != 'Tous') {
      docs = docs.where((d) => (d.category ?? 'Autre') == _selectedCategory).toList();
    }
    if (_selectedTags.isNotEmpty) docs = docs.where((d) => _selectedTags.any((t) => d.tags.contains(t))).toList();
    return docs;
  }

  List<String> get _categoryChips {
    final fromDocs = ref.watch(documentsProvider).items.map((d) => d.category).whereType<String>();
    final cats = <String>{'Tous', ...fromDocs}.toList();
    if (_selectedCategory != 'Tous' && !cats.contains(_selectedCategory)) {
      cats.add(_selectedCategory);
    }
    return cats;
  }

  @override
  Widget build(BuildContext context) {
    final docsState = ref.watch(documentsProvider);
    final docs = _filteredDocs;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(ConfidiaSpacing.md, ConfidiaSpacing.sm, ConfidiaSpacing.md, ConfidiaSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumSearchField(
                  hintText: 'Rechercher un document, tag, correspondant…',
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: ConfidiaSpacing.sm),
                DocumentSourceActions(
                  onScan: () => context.go('/documents/add?mode=camera'),
                  onImport: () => context.go('/documents/add?mode=files'),
                ),
                const SizedBox(height: ConfidiaSpacing.md),
                ConfidiaGlowChipScroll(
                  padding: EdgeInsets.zero,
                  children: _categoryChips.map((cat) {
                    final selected = _selectedCategory == cat;
                    return ConfidiaGlowChip(
                      label: cat,
                      selected: selected,
                      compact: true,
                      onTap: () => setState(() => _selectedCategory = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: ConfidiaSpacing.sm),
                Text('${docs.length} résultat${docs.length > 1 ? 's' : ''}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        if (docsState.loading && docsState.items.isEmpty)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
        else if (docsState.error != null && docsState.items.isEmpty)
          SliverFillRemaining(child: Center(child: Text(docsState.error!)))
        else if (docs.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Aucun document. Importez un fichier pour commencer : il restera dans votre espace, avec aperçu et téléchargement.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg),
            sliver: SliverList.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: ConfidiaSpacing.sm),
              itemBuilder: (context, index) {
                final stagger = ConfidiaPageRevealTiming.staggerCount(
                  context,
                  docs.length,
                  itemExtent: 88,
                  overhead: 340,
                );
                return ConfidiaPageReveal(
                  index: index,
                  staggerCount: stagger,
                  child: _DocumentListTile(doc: docs[index], isDark: isDark),
                );
              },
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: ConfidiaInsets.scrollTail(context))),
      ],
    );
  }
}

class _DocumentListTile extends StatelessWidget {
  final DocumentModel doc;
  final bool isDark;

  const _DocumentListTile({required this.doc, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? ConfidiaColors.darkSurfaceElevated : Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/documents/${doc.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ConfidiaColors.border(isDark)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.title, style: Theme.of(context).textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      '${doc.category ?? 'Non classé'} · ${doc.correspondent ?? 'Sans correspondant'} · ${doc.fileSizeFormatted}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(DateFormat('d MMM yyyy', 'fr_FR').format(doc.modified), style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              if (doc.isImportant)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.star_rounded,
                    color: ConfidiaColors.warning,
                    size: 18,
                  ),
                ),
              const Icon(Icons.chevron_right_rounded, color: ConfidiaColors.darkTextTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
