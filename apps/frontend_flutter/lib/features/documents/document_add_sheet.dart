import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/confidia_modal_sheet.dart';
import 'document_source_actions.dart';

/// Choix d'ajout document depuis le dashboard : Scanner ou Importer.
Future<void> showDocumentAddSheet(BuildContext context) {
  return showConfidiaSheet<void>(
    context: context,
    title: 'Ajouter un document',
    child: const _DocumentAddOptions(),
  );
}

class _DocumentAddOptions extends StatelessWidget {
  const _DocumentAddOptions();

  void _go(BuildContext context, String mode) {
    final router = GoRouter.of(context);
    Navigator.pop(context);
    router.go('/documents/add?mode=$mode');
  }

  @override
  Widget build(BuildContext context) {
    return DocumentSourceActions(
      stacked: true,
      onScan: () => _go(context, 'camera'),
      onImport: () => _go(context, 'files'),
    );
  }
}
