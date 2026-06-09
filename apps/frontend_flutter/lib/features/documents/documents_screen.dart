import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/document_model.dart';
import '../../shared/widgets/glass_card.dart';

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
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(ConfidiaSpacing.lg, 0, ConfidiaSpacing.lg, ConfidiaSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un document, tag, correspondant...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: ConfidiaSpacing.sm),
              ElevatedButton.icon(
                onPressed: () => context.go('/upload'),
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: Text(isWide ? 'Importer' : ''),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg),
            children: MockData.categories.map((cat) {
              final selected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: ConfidiaSpacing.sm),
                child: FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: ConfidiaColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: ConfidiaColors.primary,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: ConfidiaSpacing.sm),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg),
            children: MockData.allTags.map((tag) {
              final selected = _selectedTags.contains(tag);
              return Padding(
                padding: const EdgeInsets.only(right: ConfidiaSpacing.sm),
                child: ActionChip(
                  label: Text('#$tag'),
                  backgroundColor: selected ? ConfidiaColors.secondary.withValues(alpha: 0.15) : null,
                  onPressed: () => setState(() => selected ? _selectedTags.remove(tag) : _selectedTags.add(tag)),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(ConfidiaSpacing.lg, ConfidiaSpacing.sm, ConfidiaSpacing.lg, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${docs.length} résultat${docs.length > 1 ? 's' : ''}', style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
        Expanded(
          child: docs.isEmpty
              ? const Center(child: Text('Aucun document trouvé'))
              : isWide ? _buildGrid(docs) : _buildList(docs),
        ),
      ],
    );
  }

  Widget _buildGrid(List<DocumentModel> docs) {
    return GridView.builder(
      padding: const EdgeInsets.all(ConfidiaSpacing.lg),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 0.95,
        crossAxisSpacing: ConfidiaSpacing.md,
        mainAxisSpacing: ConfidiaSpacing.md,
      ),
      itemCount: docs.length,
      itemBuilder: (_, i) => _DocumentCard(doc: docs[i]),
    );
  }

  Widget _buildList(List<DocumentModel> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(ConfidiaSpacing.lg),
      itemCount: docs.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
        child: _DocumentCard(doc: docs[i]),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentModel doc;
  const _DocumentCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.go('/documents/${doc.id}'),
      padding: const EdgeInsets.all(ConfidiaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ConfidiaColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: ConfidiaColors.primary, size: 20),
              ),
              const Spacer(),
              if (doc.isImportant) const Icon(Icons.star_rounded, color: ConfidiaColors.warning, size: 18),
            ],
          ),
          const SizedBox(height: ConfidiaSpacing.md),
          Text(doc.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          if (doc.category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ConfidiaColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(doc.category!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ConfidiaColors.accent)),
            ),
          const SizedBox(height: ConfidiaSpacing.sm),
          Row(
            children: [
              Text(DateFormat('d MMM yyyy', 'fr_FR').format(doc.modified), style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              Text(doc.fileSizeFormatted, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
