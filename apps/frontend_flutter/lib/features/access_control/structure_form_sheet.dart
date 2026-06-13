import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/spacing.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_glow_chip.dart';
import '../../shared/widgets/confidia_modal_sheet.dart';
import '../../shared/widgets/confidia_text_field.dart';
import '../../shared/models/access_control_models.dart';
import 'access_control_provider.dart';

Future<void> showStructureFormSheet(BuildContext context) {
  return showConfidiaSheet<void>(
    context: context,
    title: 'Nouvelle structure',
    child: const _StructureFormContent(),
  );
}

class _StructureFormContent extends ConsumerStatefulWidget {
  const _StructureFormContent();

  @override
  ConsumerState<_StructureFormContent> createState() => _StructureFormContentState();
}

class _StructureFormContentState extends ConsumerState<_StructureFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  StructureTemplate _template = StructureTemplate.enterprise;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(accessControlProvider.notifier).addStructure(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          template: _template,
        );
    Navigator.pop(context);
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
            controller: _nameCtrl,
            labelText: 'Nom de la structure',
            prefixIcon: Icons.apartment_rounded,
            validator: (v) => v?.trim().isEmpty == true ? 'Requis' : null,
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          ConfidiaTextFormField(
            controller: _descCtrl,
            labelText: 'Description',
            prefixIcon: Icons.notes_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          Text('Modèle de départ', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ConfidiaGlowChip(
                label: 'Famille',
                icon: Icons.family_restroom_rounded,
                selected: _template == StructureTemplate.family,
                onTap: () => setState(() => _template = StructureTemplate.family),
              ),
              ConfidiaGlowChip(
                label: 'Club',
                icon: Icons.sports_soccer_rounded,
                selected: _template == StructureTemplate.club,
                onTap: () => setState(() => _template = StructureTemplate.club),
              ),
              ConfidiaGlowChip(
                label: 'Entreprise',
                icon: Icons.business_rounded,
                selected: _template == StructureTemplate.enterprise,
                onTap: () => setState(() => _template = StructureTemplate.enterprise),
              ),
              ConfidiaGlowChip(
                label: 'Vide',
                icon: Icons.layers_clear_rounded,
                selected: _template == StructureTemplate.blank,
                onTap: () => setState(() => _template = StructureTemplate.blank),
              ),
            ],
          ),
          const SizedBox(height: ConfidiaSpacing.lg),
          ConfidiaGlowButton(
            label: 'Créer la structure',
            icon: Icons.check_rounded,
            expand: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
