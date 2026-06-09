import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Champ de recherche compact et premium.
class PremiumSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const PremiumSearchField({
    super.key,
    this.hintText = 'Rechercher…',
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: Theme.of(context).textTheme.bodySmall,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ConfidiaColors.textSecondary(isDark),
            ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: ConfidiaColors.textSecondary(isDark),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 36),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: isDark
            ? ConfidiaColors.darkSurfaceVariant.withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ConfidiaColors.border(isDark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ConfidiaColors.border(isDark).withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ConfidiaColors.primary.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}
