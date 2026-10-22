import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/spacing.dart';
import '../../shared/models/document_model.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_glow_chip.dart';
import '../../shared/widgets/confidia_modal_sheet.dart';
import 'documents_provider.dart';

/// Asks what to do with each live event before the document file is erased.
Future<List<DocumentPurgeDecision>?> showDocumentPurgeSheet({
  required BuildContext context,
  required DocumentModel doc,
  required List<DocumentEventLink> links,
}) {
  return showConfidiaSheet<List<DocumentPurgeDecision>>(
    context: context,
    title: 'Supprimer définitivement',
    child: _PurgeForm(doc: doc, links: links),
  );
}

class _PurgeForm extends StatefulWidget {
  final DocumentModel doc;
  final List<DocumentEventLink> links;

  const _PurgeForm({required this.doc, required this.links});

  @override
  State<_PurgeForm> createState() => _PurgeFormState();
}

class _PurgeFormState extends State<_PurgeForm> {
  late final Map<String, String> _action;
  final _when = DateFormat('d MMM yyyy HH:mm', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _action = {
      for (final link in widget.links)
        if (!link.deleted) link.eventId: 'keep',
    };
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.links.where((link) => !link.deleted).toList();
    final archived = widget.links.where((link) => link.deleted).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '« ${widget.doc.title} » et son fichier seront effacés. Ces événements utilisent encore le document.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Conserver retire seulement le lien. Supprimer retire aussi l\'événement de l\'agenda.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: ConfidiaSpacing.md),
        for (final link in live) ...[
          Text(link.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(_when.format(link.start.toLocal()), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ConfidiaGlowChip(
                label: 'Conserver',
                compact: true,
                selected: _action[link.eventId] == 'keep',
                onTap: () => setState(() => _action[link.eventId] = 'keep'),
              ),
              ConfidiaGlowChip(
                label: 'Supprimer',
                compact: true,
                selected: _action[link.eventId] == 'delete',
                onTap: () => setState(() => _action[link.eventId] = 'delete'),
              ),
            ],
          ),
          const SizedBox(height: ConfidiaSpacing.md),
        ],
        if (archived.isNotEmpty)
          Text(
            archived.length == 1
                ? '1 événement déjà retiré de l\'agenda sera seulement détaché.'
                : '${archived.length} événements déjà retirés de l\'agenda seront seulement détachés.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: ConfidiaSpacing.sm),
        ConfidiaGlowButton(
          label: 'Supprimer définitivement',
          icon: Icons.delete_forever_rounded,
          expand: true,
          onPressed: () {
            Navigator.pop(
              context,
              [
                for (final entry in _action.entries)
                  DocumentPurgeDecision(eventId: entry.key, action: entry.value),
              ],
            );
          },
        ),
      ],
    );
  }
}
