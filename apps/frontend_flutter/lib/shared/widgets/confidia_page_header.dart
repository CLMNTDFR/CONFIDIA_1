import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens/tokens.dart';
import '../navigation/confidia_parent_route.dart';

/// Back button (chevron) to the parent route.
class ConfidiaBackButton extends StatelessWidget {
  final String parentRoute;

  const ConfidiaBackButton({super.key, required this.parentRoute});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ink = (isDark ? Colors.white : Colors.black).withValues(
      alpha: isDark ? AppOpacity.hoverInkDark : AppOpacity.hoverInkLight,
    );
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(parentRoute),
        mouseCursor: SystemMouseCursors.click,
        hoverColor: ink,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: AppOpacity.faint),
            border: Border.fromBorderSide(AppBorders.standard(isDark)),
          ),
          child: Icon(Icons.chevron_left_rounded, color: ConfidiaColors.textSecondary(isDark), size: 22),
        ),
      ),
    );
  }
}

/// Page header with a back control to the left of the title.
class ConfidiaPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? backRoute;
  final EdgeInsetsGeometry? padding;

  const ConfidiaPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.backRoute,
    this.padding,
  });

  factory ConfidiaPageHeader.forRoute(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? backRoute,
    EdgeInsetsGeometry? padding,
  }) {
    final path = GoRouterState.of(context).matchedLocation;
    return ConfidiaPageHeader(
      title: title,
      subtitle: subtitle,
      backRoute: backRoute ?? confidiaParentRoute(path),
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final parent = backRoute;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parent != null) ...[
            ConfidiaBackButton(parentRoute: parent),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
