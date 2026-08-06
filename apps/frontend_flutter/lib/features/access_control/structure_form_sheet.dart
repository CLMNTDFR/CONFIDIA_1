import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_glow_chip.dart';
import '../../shared/widgets/confidia_modal_sheet.dart';
import '../../shared/widgets/confidia_text_field.dart';
import '../../shared/models/access_control_models.dart';
import 'access_control_provider.dart';

/// Icônes proposées pour les structures personnalisées.
abstract final class StructureIconOptions {
  static const icons = <IconData>[
    Icons.apartment_rounded,
    Icons.business_rounded,
    Icons.family_restroom_rounded,
    Icons.groups_rounded,
    Icons.diversity_3_rounded,
    Icons.sports_soccer_rounded,
    Icons.school_rounded,
    Icons.volunteer_activism_rounded,
    Icons.church_rounded,
    Icons.local_hospital_rounded,
    Icons.account_balance_rounded,
    Icons.handshake_rounded,
    Icons.home_work_rounded,
    Icons.hiking_rounded,
    Icons.theater_comedy_rounded,
    Icons.pets_rounded,
    Icons.emoji_people_rounded,
    Icons.workspace_premium_rounded,
    Icons.hub_rounded,
    Icons.interests_rounded,
    Icons.castle_rounded,
    Icons.forest_rounded,
    Icons.music_note_rounded,
    Icons.science_rounded,
  ];
}

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
  final _customModelCtrl = TextEditingController();
  StructureTemplate _template = StructureTemplate.enterprise;
  IconData _customIcon = Icons.hub_rounded;

  bool get _isCustom => _template == StructureTemplate.custom;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _customModelCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_isCustom && _customModelCtrl.text.trim().isEmpty) {
      return;
    }

    final structureName = _isCustom ? _customModelCtrl.text.trim() : _nameCtrl.text.trim();

    ref.read(accessControlProvider.notifier).addStructure(
          name: structureName,
          description: _descCtrl.text.trim(),
          template: _template,
          icon: _isCustom ? _customIcon : null,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isCustom) ...[
            ConfidiaTextFormField(
              controller: _nameCtrl,
              labelText: 'Nom de la structure',
              prefixIcon: Icons.apartment_rounded,
              validator: (v) => v?.trim().isEmpty == true ? 'Requis' : null,
            ),
            const SizedBox(height: ConfidiaSpacing.sm),
          ],
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
                label: 'Custom',
                icon: Icons.tune_rounded,
                selected: _isCustom,
                onTap: () => setState(() => _template = StructureTemplate.custom),
              ),
            ],
          ),
          if (_isCustom) ...[
            const SizedBox(height: ConfidiaSpacing.md),
            ConfidiaTextFormField(
              controller: _customModelCtrl,
              labelText: 'Nom du modèle',
              prefixIcon: _customIcon,
              hintText: 'Ex. Association, École, Copropriété…',
              validator: (v) => v?.trim().isEmpty == true ? 'Requis pour un modèle custom' : null,
            ),
            const SizedBox(height: ConfidiaSpacing.sm),
            Text('Icône du modèle', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: StructureIconOptions.icons.length,
              itemBuilder: (context, index) {
                final icon = StructureIconOptions.icons[index];
                final selected = _customIcon == icon;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _customIcon = icon),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: selected
                            ? palette.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                            : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                        border: Border.all(
                          color: selected
                              ? palette.primary.withValues(alpha: 0.55)
                              : ConfidiaColors.border(isDark),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: selected ? palette.primary : ConfidiaColors.textSecondary(isDark),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: ConfidiaSpacing.lg),
          Center(
            child: ConfidiaGlowButton(
              label: 'Créer la structure',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
