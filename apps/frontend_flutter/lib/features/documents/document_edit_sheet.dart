import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/spacing.dart';
import '../../shared/models/document_model.dart';
import '../../shared/widgets/confidia_dropdown_field.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_modal_sheet.dart';
import '../../shared/widgets/confidia_snackbar.dart';
import '../../shared/widgets/confidia_text_field.dart';
import 'document_categories.dart';
import 'documents_provider.dart';
import 'widgets/document_type_field.dart';

Future<void> showDocumentEditSheet(BuildContext context, DocumentModel doc) {
  return showConfidiaSheet<void>(
    context: context,
    title: 'Modifier le document',
    child: _DocumentEditForm(doc: doc),
  );
}

class _DocumentEditForm extends ConsumerStatefulWidget {
  final DocumentModel doc;

  const _DocumentEditForm({required this.doc});

  @override
  ConsumerState<_DocumentEditForm> createState() => _DocumentEditFormState();
}

class _DocumentEditFormState extends ConsumerState<_DocumentEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _correspondentCtrl;
  late String _category;
  late String? _documentType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.doc.title);
    _correspondentCtrl = TextEditingController(text: widget.doc.correspondent ?? '');
    _documentType = widget.doc.documentType;
    final current = widget.doc.category;
    _category = (current != null && DocumentCategories.values.contains(current))
        ? current
        : DocumentCategories.values.first;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _correspondentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final error = await ref.read(documentsProvider.notifier).updateDocument(
          id: widget.doc.id,
          title: _titleCtrl.text,
          category: _category,
          correspondent: _correspondentCtrl.text,
          documentType: _documentType ?? '',
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showConfidiaSnackBar(context, error, type: ConfidiaSnackType.error);
      return;
    }
    Navigator.pop(context);
    showConfidiaSnackBar(context, 'Document mis à jour', type: ConfidiaSnackType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConfidiaTextFormField(
            controller: _titleCtrl,
            labelText: 'Titre',
            prefixIcon: Icons.title_rounded,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Le titre est requis' : null,
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          ConfidiaDropdownField<String>(
            value: _category,
            items: DocumentCategories.values,
            itemLabel: (item) => item,
            labelText: 'Catégorie',
            prefixIcon: Icons.category_outlined,
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          DocumentTypeField(
            initialValue: widget.doc.documentType,
            onChanged: (value) => _documentType = value,
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          ConfidiaTextFormField(
            controller: _correspondentCtrl,
            labelText: 'Correspondant (optionnel)',
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: ConfidiaSpacing.lg),
          Center(
            child: ConfidiaGlowButton(
              label: _saving ? 'Enregistrement…' : 'Enregistrer',
              icon: Icons.check_rounded,
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}
