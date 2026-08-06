import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';

/// Champ de formulaire premium - typo compacte, bordures sobres.
class ConfidiaTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const ConfidiaTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  static TextStyle fieldStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.35,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: fieldStyle(context),
      decoration: InputDecoration(
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
        suffixIcon: suffixIcon,
        suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
      ),
    );
  }
}
