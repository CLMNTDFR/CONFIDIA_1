import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/theme_provider.dart';

class ThemeToggleButton extends ConsumerWidget {
  final bool compact;

  const ThemeToggleButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final decoration = BoxDecoration(
      color: isDarkTheme ? ConfidiaColors.darkSurfaceVariant : ConfidiaColors.lightSurfaceVariant,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: isDarkTheme ? ConfidiaColors.darkBorder : ConfidiaColors.lightBorder),
    );

    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(themeModeProvider.notifier).state = !isDark,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: decoration,
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                key: ValueKey(isDark),
                size: 20,
                color: isDark ? context.palette.secondary : ConfidiaColors.warning,
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(themeModeProvider.notifier).state = !isDark,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: decoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey(isDark),
                  size: 18,
                  color: isDark ? context.palette.secondary : ConfidiaColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Text(isDark ? 'Sombre' : 'Clair', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
