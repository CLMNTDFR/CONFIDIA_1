import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

class WorkspaceEmptyHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool expand;

  const WorkspaceEmptyHint({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = ConfidiaColors.textSecondary(isDark);
    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: ConfidiaSpacing.md, horizontal: ConfidiaSpacing.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: muted.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted, height: 1.4),
            ),
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = expand && constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        return SizedBox(
          width: constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity,
          height: boundedHeight ? constraints.maxHeight : null,
          child: boundedHeight ? Center(child: body) : body,
        );
      },
    );
  }
}
