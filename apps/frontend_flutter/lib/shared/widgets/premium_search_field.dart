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
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: ConfidiaColors.textSecondary(isDark),
            ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: ConfidiaColors.textSecondary(isDark),
        ),
      ),
    );
  }
}
