import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import 'confidia_logo.dart';

/// Taille et disposition du logo CONFIDIA animé (anneau tournant).
enum ConfidiaAnimatedLogoLayout {
  /// Sidebar ouverte : logo + CONFIDIA + « Hub numérique »
  sidebarExpanded,

  /// Sidebar rétractée : marque seule, très compact
  sidebarCollapsed,

  /// Barre supérieure mobile : logo + textes
  topBar,
}

/// Logo CONFIDIA animé avec anneau tournant — sidebar ou top bar.
class ConfidiaAnimatedLogo extends StatefulWidget {
  final ConfidiaAnimatedLogoLayout layout;

  const ConfidiaAnimatedLogo({
    super.key,
    this.layout = ConfidiaAnimatedLogoLayout.sidebarExpanded,
  });

  @override
  State<ConfidiaAnimatedLogo> createState() => _ConfidiaAnimatedLogoState();
}

class _ConfidiaAnimatedLogoState extends State<ConfidiaAnimatedLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _ring;

  bool get _iconOnly => widget.layout == ConfidiaAnimatedLogoLayout.sidebarCollapsed;

  double get _logoSize => switch (widget.layout) {
        ConfidiaAnimatedLogoLayout.sidebarCollapsed => 15,
        ConfidiaAnimatedLogoLayout.topBar => 22,
        ConfidiaAnimatedLogoLayout.sidebarExpanded => 24,
      };

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 8000))..repeat();
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringSize = _logoSize * (_iconOnly ? 1.55 : 2.0);

    return AnimatedBuilder(
      animation: _ring,
      builder: (context, _) {
        final pulse = 0.5 + math.sin(_ring.value * math.pi * 2) * 0.25;
        final ringAngle = _ring.value * 2 * math.pi;
        final breathe = 1 + math.sin(_ring.value * math.pi * 2) * 0.012;

        final mark = Transform.scale(
          scale: breathe,
          child: SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Transform.rotate(
                  angle: ringAngle,
                  child: Container(
                    width: ringSize,
                    height: ringSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          ConfidiaColors.primary.withValues(alpha: pulse * 0.1),
                          ConfidiaColors.secondary.withValues(alpha: pulse * 0.45),
                          ConfidiaColors.accent.withValues(alpha: pulse * 0.25),
                          ConfidiaColors.primary.withValues(alpha: pulse * 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
                ConfidiaLogo(size: _logoSize, showText: false),
              ],
            ),
          ),
        );

        if (_iconOnly) return mark;

        final titleSize = widget.layout == ConfidiaAnimatedLogoLayout.topBar ? 15.0 : 14.0;
        final taglineSize = widget.layout == ConfidiaAnimatedLogoLayout.topBar ? 10.0 : 9.5;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => ConfidiaColors.brandGradient.createShader(b),
                    child: Text(
                      'CONFIDIA',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: Colors.white,
                        height: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hub numérique',
                    style: TextStyle(
                      fontSize: taglineSize,
                      fontWeight: FontWeight.w500,
                      color: ConfidiaColors.textSecondary(isDark),
                      letterSpacing: 0.3,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
