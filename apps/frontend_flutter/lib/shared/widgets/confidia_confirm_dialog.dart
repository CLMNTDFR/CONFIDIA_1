import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';
import 'confidia_chrome_material.dart';
import 'confidia_glow_button.dart';

/// CONFIDIA-styled confirmation dialog (chrome material, centered buttons).
/// Same choreography as [showConfidiaSheet]: progressive blur/scrim + slide.
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
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: 'Dialogue',
    barrierColor: Colors.transparent,
    transitionDuration: AppDurations.medium,
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return _ConfidiaConfirmTransition(
        animation: animation,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        destructive: destructive,
      );
    },
  );
  return result == true;
}

class _ConfidiaConfirmTransition extends StatefulWidget {
  final Animation<double> animation;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final bool destructive;

  const _ConfidiaConfirmTransition({
    required this.animation,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.destructive,
  });

  @override
  State<_ConfidiaConfirmTransition> createState() => _ConfidiaConfirmTransitionState();
}

class _ConfidiaConfirmTransitionState extends State<_ConfidiaConfirmTransition> {
  static const double _barrierBlur = 14;

  late final CurvedAnimation _motion = CurvedAnimation(
    parent: widget.animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, _) {
        final t = _motion.value.clamp(0.0, 1.0);
        final sigma = _barrierBlur * t;
        final veil = AppOpacity.veilDark * t;
        final dy = (1.0 - t) * 56;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: veil),
                ),
              ),
            ),
            Center(
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Opacity(
                  opacity: t,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.xlAll,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22 * t),
                            blurRadius: 36,
                            spreadRadius: 2,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12 * t),
                            blurRadius: 64,
                            spreadRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _ConfidiaConfirmDialog(
                        title: widget.title,
                        message: widget.message,
                        confirmLabel: widget.confirmLabel,
                        cancelLabel: widget.cancelLabel,
                        icon: widget.icon,
                        destructive: widget.destructive,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
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

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ConfidiaChromeMaterial(
          borderRadius: AppRadius.xlAll,
          padding: const EdgeInsets.fromLTRB(
            ConfidiaSpacing.lg,
            ConfidiaSpacing.lg,
            ConfidiaSpacing.lg,
            ConfidiaSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? AppOpacity.muted : AppOpacity.tintSoft),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                  const SizedBox(width: 8),
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
    );
  }
}
