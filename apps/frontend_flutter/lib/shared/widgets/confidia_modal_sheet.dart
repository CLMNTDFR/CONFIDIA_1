import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/theme_context.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/tokens/tokens.dart';
import 'confidia_chrome_material.dart';
import 'mobile_shell_insets.dart';

/// Shows a CONFIDIA-styled modal (discreet chrome material).
/// Always centered in the usable area:
/// - mobile: between top bar and bottom bar
/// - desktop: between top bar and bottom of the screen
///
/// Animation: blur/scrim in a fixed fade; sheet slides bottom → top.
/// Root navigator + blocking barrier.
///
/// [maxWidth] / [maxHeightFactor]: for more compact nested modals
/// (e.g. date picker), to keep a stacked overlay effect.
Future<T?> showConfidiaSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  List<Widget>? actions,
  bool isScrollControlled = true,
  double maxWidth = 520,
  double maxHeightFactor = 1,
}) {
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: 'Modale',
    barrierColor: Colors.transparent,
    transitionDuration: AppDurations.medium,
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, _) {
      return _ConfidiaSheetTransition(
        animation: animation,
        title: title,
        actions: actions,
        sheetChild: child,
        maxWidth: maxWidth,
        maxHeightFactor: maxHeightFactor.clamp(0.4, 1.0),
      );
    },
  );
}

/// Fade blur (fixed) + modal sliding up from the bottom + soft shadow.
class _ConfidiaSheetTransition extends StatefulWidget {
  final Animation<double> animation;
  final String title;
  final Widget sheetChild;
  final List<Widget>? actions;
  final double maxWidth;
  final double maxHeightFactor;

  const _ConfidiaSheetTransition({
    required this.animation,
    required this.title,
    required this.sheetChild,
    required this.maxWidth,
    required this.maxHeightFactor,
    this.actions,
  });

  @override
  State<_ConfidiaSheetTransition> createState() => _ConfidiaSheetTransitionState();
}

class _ConfidiaSheetTransitionState extends State<_ConfidiaSheetTransition> {
  static const double _edgeGap = 12;
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
    final size = MediaQuery.sizeOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final isMobile = size.width < 900;

    final topChrome = viewPadding.top + ConfidiaSpacing.topBarHeight;
    final bottomChrome = isMobile
        ? ConfidiaMobileShell.navBarHeight + viewPadding.bottom
        : viewPadding.bottom;

    final topInset = topChrome + _edgeGap;
    final bottomInset = bottomChrome + _edgeGap + viewInsets.bottom;
    final availableH = (size.height - topInset - bottomInset).clamp(120.0, size.height);
    final sheetMaxH = availableH * widget.maxHeightFactor;
    final sheetMaxW = widget.maxWidth;

    // Single ticker: blur sigma/alpha and sheet translation
    // (FadeTransition + BackdropFilter shifts perceived blur, especially on web).
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
            Padding(
              padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: Opacity(
                    opacity: t,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: sheetMaxW,
                          maxHeight: sheetMaxH,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
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
                          child: Material(
                            type: MaterialType.transparency,
                            child: ConfidiaSheet(
                              title: widget.title,
                              actions: widget.actions,
                              child: widget.sheetChild,
                            ),
                          ),
                        ),
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

  static const double _headerBlock = 56;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(22);
    final actionsBlock = (actions != null && actions!.isNotEmpty) ? 72.0 : 0.0;

    return ConfidiaChromeMaterial(
      borderRadius: radius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxBody = constraints.maxHeight.isFinite
              ? (constraints.maxHeight - _headerBlock - actionsBlock).clamp(80.0, constraints.maxHeight)
              : double.infinity;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(ConfidiaSpacing.lg, 4, 8, 0),
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
                      clipBehavior: Clip.antiAlias,
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
              // shrinkWrap: height = content, capped by maxBody (scroll if needed).
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxBody),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(ConfidiaSpacing.lg),
                  children: [child],
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
          );
        },
      ),
    );
  }
}
