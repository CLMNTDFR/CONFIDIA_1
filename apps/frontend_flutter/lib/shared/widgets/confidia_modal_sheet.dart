import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import 'mobile_shell_insets.dart';

/// Affiche une modale / bottom sheet au style CONFIDIA (glass, glow sobre).
Future<T?> showConfidiaSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  List<Widget>? actions,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => ConfidiaSheet(
      title: title,
      actions: actions,
      child: child,
    ),
  );
}

class ConfidiaSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const ConfidiaSheet({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final shellBottom = ConfidiaMobileShell.isMobileShell(context)
        ? ConfidiaMobileShell.bottomScrollInset(context)
        : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardBottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            margin: EdgeInsets.fromLTRB(10, 0, 10, 10 + shellBottom),
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF1A1A28).withValues(alpha: 0.96),
                        const Color(0xFF101018).withValues(alpha: 0.98),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.97),
                        const Color(0xFFFAFAFE).withValues(alpha: 0.98),
                      ],
              ),
              border: Border.all(color: ConfidiaColors.secondary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: ConfidiaColors.primary.withValues(alpha: 0.12),
                  blurRadius: 32,
                  spreadRadius: -8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ConfidiaColors.border(isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(ConfidiaSpacing.lg, 14, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (b) => ConfidiaColors.brandGradient.createShader(b),
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
                Divider(height: 1, color: ConfidiaColors.border(isDark).withValues(alpha: 0.5)),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      ConfidiaSpacing.lg,
                      ConfidiaSpacing.lg,
                      ConfidiaSpacing.lg,
                      ConfidiaSpacing.lg + shellBottom,
                    ),
                    child: child,
                  ),
                ),
                if (actions != null && actions!.isNotEmpty) ...[
                  Divider(height: 1, color: ConfidiaColors.border(isDark).withValues(alpha: 0.5)),
                  Padding(
                    padding: const EdgeInsets.all(ConfidiaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
