import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import 'confidia_glow_button.dart';

/// Dialogue de confirmation au style CONFIDIA (glass, animation, boutons centrés).
Future<bool> showConfidiaConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmer',
  String cancelLabel = 'Annuler',
  IconData icon = Icons.help_outline_rounded,
  bool destructive = false,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: Center(
            child: _ConfidiaConfirmDialog(
              title: title,
              message: message,
              confirmLabel: confirmLabel,
              cancelLabel: cancelLabel,
              icon: icon,
              destructive: destructive,
            ),
          ),
        ),
      );
    },
  );
  return result == true;
}

class _ConfidiaConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final bool destructive;

  const _ConfidiaConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.destructive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;
    final accent = destructive ? ConfidiaColors.error : palette.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
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
                border: Border.all(color: palette.secondary.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.14),
                    blurRadius: 32,
                    spreadRadius: -8,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(ConfidiaSpacing.lg, ConfidiaSpacing.lg, ConfidiaSpacing.lg, ConfidiaSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.16 : 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accent.withValues(alpha: 0.25)),
                      ),
                      child: Icon(icon, color: accent, size: 22),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ConfidiaGlowButton(
                          label: cancelLabel,
                          icon: Icons.close_rounded,
                          primary: false,
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        const SizedBox(width: 10),
                        ConfidiaGlowButton(
                          label: confirmLabel,
                          icon: destructive ? Icons.logout_rounded : Icons.check_rounded,
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
