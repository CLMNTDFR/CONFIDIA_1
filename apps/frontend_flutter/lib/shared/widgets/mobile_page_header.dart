import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../navigation/confidia_parent_route.dart';
import 'confidia_page_header.dart';

/// Titre de page affiché sous la top bar sur mobile.
class MobilePageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String path;

  const MobilePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backRoute = confidiaParentRoute(path);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(ConfidiaSpacing.lg, 10, ConfidiaSpacing.lg, 12),
      decoration: BoxDecoration(
        color: isDark ? ConfidiaColors.darkSurface.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.65),
        border: Border(
          bottom: BorderSide(color: isDark ? ConfidiaColors.darkBorderSubtle : ConfidiaColors.lightBorderSubtle),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (backRoute != null) ...[
            ConfidiaBackButton(parentRoute: backRoute),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
