import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_glow_chip.dart';
import '../../shared/widgets/confidia_modal_sheet.dart';
import '../../shared/widgets/confidia_snackbar.dart';
import '../../shared/widgets/confidia_text_field.dart';
import 'governance_models.dart';
import 'governance_provider.dart';
import 'structure_form_sheet.dart';

const _kinds = ['family', 'personal', 'club', 'org'];

Future<void> showSpaceEditSheet(BuildContext context, WidgetRef ref) {
  final workspace = ref.read(governanceProvider).workspace;
  if (workspace == null) return Future.value();
  return showConfidiaSheet<void>(
    context: context,
    title: 'Modifier l\'espace',
    child: _SpaceEditForm(workspace: workspace),
  );
}

class _SpaceEditForm extends ConsumerStatefulWidget {
  final GovernanceWorkspace workspace;

  const _SpaceEditForm({required this.workspace});

  @override
  ConsumerState<_SpaceEditForm> createState() => _SpaceEditFormState();
}

class _SpaceEditFormState extends ConsumerState<_SpaceEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _kind;
  late String _icon;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.workspace.name);
    _kind = widget.workspace.kind;
    _icon = widget.workspace.icon;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final error = await ref.read(governanceProvider.notifier).updateWorkspace(
          name: _name.text.trim(),
          icon: _icon,
          kind: _kind,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      context.showConfidiaSnack(error, type: ConfidiaSnackType.error);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConfidiaTextFormField(
            controller: _name,
            labelText: 'Nom de l\'espace',
            prefixIcon: StructureIconOptions.iconFor(_icon),
            validator: (value) => value == null || value.trim().isEmpty ? 'Le nom est requis' : null,
          ),
          const SizedBox(height: ConfidiaSpacing.md),
          Text('Type', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in _kinds)
                ConfidiaGlowChip(
                  label: governanceKindLabel(kind),
                  selected: _kind == kind,
                  onTap: () => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: ConfidiaSpacing.md),
          Text('Icône', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: StructureIconOptions.options.length,
            itemBuilder: (context, index) {
              final option = StructureIconOptions.options[index];
              final selected = option.id == _icon;
              return InkWell(
                onTap: () => setState(() => _icon = option.id),
                borderRadius: BorderRadius.circular(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: selected
                        ? palette.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                        : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                    border: Border.all(
                      color: selected ? palette.primary.withValues(alpha: 0.55) : ConfidiaColors.border(isDark),
                    ),
                  ),
                  child: Icon(option.icon, size: 20, color: selected ? palette.primary : null),
                ),
              );
            },
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
