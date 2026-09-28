import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';
import 'confidia_menu.dart';
import 'confidia_tappable.dart';
import 'confidia_text_field.dart';

/// CONFIDIA-styled dropdown menu, aligned with [ConfidiaTextFormField].
class ConfidiaDropdownField<T> extends StatefulWidget {
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final IconData? prefixIcon;
  final String? labelText;
  final String? hintText;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;

  const ConfidiaDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabel,
    this.prefixIcon,
    this.labelText,
    this.hintText,
    this.onChanged,
    this.validator,
  });

  static InputDecoration decoration(
    BuildContext context, {
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      isDense: true,
      filled: true,
      fillColor: AppColors.surface1(isDark).withValues(
        alpha: isDark ? AppOpacity.inputFillDark : AppOpacity.inputFillLight,
      ),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ConfidiaColors.textSecondary(isDark),
          ),
      floatingLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: ConfidiaColors.textSecondary(isDark),
            letterSpacing: 0.2,
          ),
      hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 13,
            color: ConfidiaColors.textSecondary(isDark),
          ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: ConfidiaColors.textSecondary(isDark))
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      border: AppBorders.input(isDark: isDark),
      enabledBorder: AppBorders.input(isDark: isDark),
      focusedBorder: AppBorders.input(
        isDark: isDark,
        accent: context.palette.primary.withValues(alpha: AppOpacity.borderFocus),
        width: AppBorders.focus,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.controlAll,
        borderSide: AppBorders.error(),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.controlAll,
        borderSide: AppBorders.error(width: AppBorders.focus),
      ),
    );
  }

  @override
  State<ConfidiaDropdownField<T>> createState() => _ConfidiaDropdownFieldState<T>();
}

class _ConfidiaDropdownFieldState<T> extends State<ConfidiaDropdownField<T>> {
  bool _open = false;

  bool get _enabled => widget.onChanged != null;

  Future<void> _pick(FormFieldState<T> field) async {
    if (!_enabled || widget.items.isEmpty || _open) return;
    setState(() => _open = true);
    final selected = await showConfidiaMenu<T>(
      context: context,
      matchAnchorWidth: true,
      items: [
        for (final item in widget.items)
          ConfidiaMenuEntry<T>(
            value: item,
            label: widget.itemLabel(item),
            selected: item == widget.value,
          ),
      ],
    );
    if (!mounted) return;
    setState(() => _open = false);
    if (selected == null) return;
    widget.onChanged?.call(selected);
    field.didChange(selected);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = ConfidiaColors.textSecondary(isDark);

    return FormField<T>(
      initialValue: widget.value,
      validator: (_) => widget.validator?.call(widget.value),
      enabled: _enabled,
      builder: (field) {
        final hasValue = widget.value != null;
        return ConfidiaTappable(
          onTap: _enabled ? () => _pick(field) : null,
          pressScale: 0.99,
          borderRadius: AppRadius.controlAll,
          child: InputDecorator(
            isFocused: _open,
            isEmpty: !hasValue,
            decoration: ConfidiaDropdownField.decoration(
              context,
              labelText: widget.labelText,
              hintText: widget.hintText,
              prefixIcon: widget.prefixIcon,
            ).copyWith(
              enabled: _enabled,
              errorText: field.errorText,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: AppDurations.quick,
                  curve: Curves.easeOutCubic,
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: muted, size: 22),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            child: Text(
              hasValue ? widget.itemLabel(widget.value as T) : '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ConfidiaTextFormField.fieldStyle(context).copyWith(
                color: _enabled
                    ? ConfidiaColors.textPrimary(isDark)
                    : muted.withValues(alpha: 0.55),
              ),
            ),
          ),
        );
      },
    );
  }
}
