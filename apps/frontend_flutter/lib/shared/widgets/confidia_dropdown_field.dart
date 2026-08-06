import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';
import 'confidia_text_field.dart';

/// Menu déroulant au style CONFIDIA, aligné sur [ConfidiaTextFormField].
class ConfidiaDropdownField<T> extends StatelessWidget {
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
            color: context.palette.primary,
            letterSpacing: 0.2,
          ),
      hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 13,
            color: ConfidiaColors.textSecondary(isDark),
          ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: ConfidiaColors.textSecondary(isDark))
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 38),
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
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      borderRadius: BorderRadius.circular(12),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.palette.primary, size: 22),
      dropdownColor: Theme.of(context).brightness == Brightness.dark
          ? ConfidiaColors.darkSurfaceElevated
          : Colors.white,
      style: ConfidiaTextFormField.fieldStyle(context),
      decoration: decoration(context, labelText: labelText, hintText: hintText, prefixIcon: prefixIcon),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
