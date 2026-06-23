import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';

/// Champ de formulaire premium  -  typo compacte, bordures sobres.
class ConfidiaTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const ConfidiaTextFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.enabled = true,
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
      enabled: enabled,
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
        fillColor: isDark
            ? ConfidiaColors.darkSurfaceElevated.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.92),
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: maxLines > 1 ? 12 : 11,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: ConfidiaColors.textSecondary(isDark))
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 38),
        suffixIcon: suffixIcon,
        suffixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: ConfidiaColors.border(isDark).withValues(alpha: 0.85)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: ConfidiaColors.border(isDark).withValues(alpha: 0.75)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: context.palette.primary.withValues(alpha: 0.55), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: ConfidiaColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: ConfidiaColors.error, width: 1.5),
        ),
      ),
    );
  }
}
