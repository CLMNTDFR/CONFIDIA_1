import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/theme_context.dart';
import '../../../shared/models/access_control_models.dart';
import '../../../shared/widgets/confidia_glow_chip.dart';

const _categoryOrder = ['Calendrier', 'Documents', 'Paiements', 'Organisation'];

/// Rights grouped by category with animated collapsible sections.
class MemberPermissionsPicker extends StatefulWidget {
  final List<AccessPermission> permissions;
  final List<String> selectedIds;
  final ValueChanged<String> onToggle;

  const MemberPermissionsPicker({
    super.key,
    required this.permissions,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  State<MemberPermissionsPicker> createState() => _MemberPermissionsPickerState();
}

class _MemberPermissionsPickerState extends State<MemberPermissionsPicker> {
  final _expanded = <String, bool>{};

  Map<String, List<AccessPermission>> get _grouped {
    final map = <String, List<AccessPermission>>{};
    for (final p in widget.permissions) {
      map.putIfAbsent(p.category, () => []).add(p);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.label.compareTo(b.label));
    }
    return map;
  }

  List<String> get _sortedCategories {
    final keys = _grouped.keys.toList();
    keys.sort((a, b) {
      final ai = _categoryOrder.indexOf(a);
      final bi = _categoryOrder.indexOf(b);
      final ap = ai == -1 ? 99 : ai;
      final bp = bi == -1 ? 99 : bi;
      if (ap != bp) return ap.compareTo(bp);
      return a.compareTo(b);
    });
    return keys;
  }

  bool _isExpanded(String category) => _expanded[category] ?? true;

  int _selectedInCategory(String category) {
    final ids = _grouped[category]!.map((p) => p.id);
    return ids.where(widget.selectedIds.contains).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _sortedCategories.map((category) {
        final items = _grouped[category]!;
        final expanded = _isExpanded(category);
        final selectedCount = _selectedInCategory(category);

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ConfidiaColors.border(isDark)),
            ),
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _expanded[category] = !expanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Icon(_iconFor(category), size: 15, color: palette.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '$selectedCount/${items.length}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: ConfidiaColors.textSecondary(isDark),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: ConfidiaColors.textSecondary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: items.map((p) {
                        final selected = widget.selectedIds.contains(p.id);
                        return ConfidiaGlowChip(
                          label: p.label,
                          compact: true,
                          selected: selected,
                          onTap: () => widget.onToggle(p.id),
                        );
                      }).toList(),
                    ),
                  ),
                  crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                  sizeCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconFor(String category) => switch (category) {
        'Calendrier' => Icons.calendar_month_rounded,
        'Documents' => Icons.folder_copy_rounded,
        'Paiements' => Icons.payments_rounded,
        'Organisation' => Icons.groups_rounded,
        _ => Icons.lock_outline_rounded,
      };
}
