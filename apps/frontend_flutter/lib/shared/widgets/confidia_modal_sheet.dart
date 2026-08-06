import 'package:flutter/material.dart';

import '../../core/theme/theme_context.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/tokens/tokens.dart';
import 'mobile_shell_insets.dart';

enum ConfidiaSheetLayout { bottom, centered }

/// Affiche une modale au style CONFIDIA (glass, glow sobre).
/// Mobile : ancrée en bas. Desktop : centrée verticalement.
Future<T?> showConfidiaSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  List<Widget>? actions,
  bool isScrollControlled = true,
}) {
  final isMobile = ConfidiaMobileShell.isMobileShell(context);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      final sheet = ConfidiaSheet(
        title: title,
        actions: actions,
        layout: isMobile ? ConfidiaSheetLayout.bottom : ConfidiaSheetLayout.centered,
        child: child,
      );

      if (isMobile) return sheet;

      final viewInsets = MediaQuery.viewInsetsOf(ctx);
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 32 + viewInsets.top * 0.15, 24, 32 + viewInsets.bottom),
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.86,
            ),
            child: sheet,
          ),
        ),
      );
    },
  );
}

class ConfidiaSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final ConfidiaSheetLayout layout;

  const ConfidiaSheet({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.layout = ConfidiaSheetLayout.bottom,
  });

  bool get _centered => layout == ConfidiaSheetLayout.centered;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final shellBottom = ConfidiaMobileShell.isMobileShell(context)
        ? ConfidiaMobileShell.bottomScrollInset(context)
        : 0.0;
    final radius = BorderRadius.circular(22);

    return Padding(
      padding: EdgeInsets.only(bottom: _centered ? 0 : keyboardBottom),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: AppBlur.sheetFilter,
          child: Container(
            margin: _centered ? EdgeInsets.zero : EdgeInsets.fromLTRB(10, 0, 10, 10 + shellBottom),
            decoration: BoxDecoration(
              borderRadius: radius,
              color: AppColors.surface1(isDark),
              border: Border.fromBorderSide(AppBorders.standard(isDark)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_centered) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppBorders.standard(isDark).color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ] else
                  const SizedBox(height: 14),
                Padding(
                  padding: EdgeInsets.fromLTRB(ConfidiaSpacing.lg, _centered ? 4 : 14, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (b) => context.palette.brandGradient.createShader(b),
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                      Material(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.close_rounded, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Divider(height: 1, color: AppBorders.subtle(isDark).color),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      ConfidiaSpacing.lg,
                      ConfidiaSpacing.lg,
                      ConfidiaSpacing.lg,
                      ConfidiaSpacing.lg + (_centered ? 0 : shellBottom),
                    ),
                    child: child,
                  ),
                ),
                if (actions != null && actions!.isNotEmpty) ...[
                  Divider(height: 1, color: AppBorders.subtle(isDark).color),
                  Padding(
                    padding: const EdgeInsets.all(ConfidiaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: actions!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
