import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/document_model.dart';
import '../../shared/widgets/confidia_button.dart';
import '../../shared/widgets/stagger_fade.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Tous';
  final Set<String> _selectedTags = {};

  List<DocumentModel> get _filteredDocs {
    var docs = MockData.documents;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      docs = docs.where((d) =>
          d.title.toLowerCase().contains(q) ||
          (d.correspondent?.toLowerCase().contains(q) ?? false) ||
          d.tags.any((t) => t.toLowerCase().contains(q))).toList();
    }
    if (_selectedCategory != 'Tous') docs = docs.where((d) => d.category == _selectedCategory).toList();
    if (_selectedTags.isNotEmpty) docs = docs.where((d) => _selectedTags.any((t) => d.tags.contains(t))).toList();
    return docs;
  }

  @override
  Widget build(BuildContext context) {
    final docs = _filteredDocs;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(ConfidiaSpacing.lg, 0, ConfidiaSpacing.lg, ConfidiaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Rechercher...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ConfidiaSpacing.sm),
                Row(
                  children: [
                    Expanded(child: ConfidiaButton(label: 'Scanner', icon: Icons.document_scanner_rounded, compact: true, onPressed: () => context.go('/scan'))),
                    const SizedBox(width: ConfidiaSpacing.sm),
                    Expanded(child: ConfidiaButton(label: 'Importer', icon: Icons.upload_rounded, outlined: true, compact: true, onPressed: () => context.go('/upload'))),
                  ],
                ),
                const SizedBox(height: ConfidiaSpacing.md),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: MockData.categories.map((cat) {
                      final selected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: ConfidiaSpacing.sm),
                        child: FilterChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                          selectedColor: ConfidiaColors.primary.withValues(alpha: 0.15),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: ConfidiaSpacing.sm),
                Text('${docs.length} résultat${docs.length > 1 ? 's' : ''}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        if (docs.isEmpty)
          const SliverFillRemaining(child: Center(child: Text('Aucun document trouvé')))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg),
            sliver: SliverList.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: ConfidiaSpacing.sm),
              itemBuilder: (context, index) => StaggerFade(
                index: index,
                child: _DocumentListTile(doc: docs[index], isDark: isDark),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.go('/documents/${doc.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ConfidiaColors.border(isDark)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ConfidiaColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: ConfidiaColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
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
              if (doc.isImportant) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.star_rounded, color: ConfidiaColors.warning, size: 18)),
              const Icon(Icons.chevron_right_rounded, color: ConfidiaColors.darkTextTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
