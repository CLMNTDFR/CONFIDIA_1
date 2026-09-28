import 'package:flutter/material.dart';

import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/confidia_dropdown_field.dart';
import '../../../shared/widgets/confidia_text_field.dart';
import '../document_types.dart';

/// Type list + « Autre » option with free text. Optional field.
class DocumentTypeField extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const DocumentTypeField({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<DocumentTypeField> createState() => _DocumentTypeFieldState();
}

class _DocumentTypeFieldState extends State<DocumentTypeField> {
  late String _choice;
  late final TextEditingController _customCtrl;

  static const _menuKeys = [
    DocumentTypes.unspecifiedKey,
    ...DocumentTypes.presets,
    DocumentTypes.otherKey,
  ];

  @override
  void initState() {
    super.initState();
    _choice = DocumentTypes.choiceFor(widget.initialValue);
    _customCtrl = TextEditingController(
      text: _choice == DocumentTypes.otherKey ? (widget.initialValue ?? '') : '',
    );
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(DocumentTypes.resolve(choice: _choice, custom: _customCtrl.text));
  }

  String _labelFor(String key) => switch (key) {
        DocumentTypes.unspecifiedKey => 'Non renseigné',
        DocumentTypes.otherKey => 'Autre (saisie libre)',
        _ => key,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConfidiaDropdownField<String>(
          value: _choice,
          items: _menuKeys,
          itemLabel: _labelFor,
          labelText: 'Type de document',
          prefixIcon: Icons.description_outlined,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _choice = value);
            _emit();
          },
        ),
        if (_choice == DocumentTypes.otherKey) ...[
          const SizedBox(height: ConfidiaSpacing.sm),
          ConfidiaTextFormField(
            controller: _customCtrl,
            labelText: 'Précisez le type',
            hintText: 'Ex. Permis de conduire',
            prefixIcon: Icons.edit_outlined,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => _emit(),
          ),
        ],
      ],
    );
  }
}
