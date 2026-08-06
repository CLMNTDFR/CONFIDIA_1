import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/theme_context.dart';
import 'confidia_logo.dart';

/// Logo avec anneau rotatif  -  réservé à l'écran de chargement post-login.
class ConfidiaAnimatedLogo extends StatefulWidget {
  final double size;
  final bool showText;

  const ConfidiaAnimatedLogo({
    super.key,
    this.size = 48,
    this.showText = true,
  });

  @override
  State<ConfidiaAnimatedLogo> createState() => _ConfidiaAnimatedLogoState();
}

class _ConfidiaAnimatedLogoState extends State<ConfidiaAnimatedLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _ring;

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

  double _ringDiameter() {
    if (!widget.showText) return widget.size * 1.65;

    final blockWidth = ConfidiaBrandMetrics.brandBlockWidth(widget.size, showText: true);
    final blockHeight = ConfidiaBrandMetrics.brandBlockHeight(widget.size, showText: true);
    return math.sqrt(blockWidth * blockWidth + blockHeight * blockHeight) * 1.05;
  }

  Widget _buildRing(double ringSize, double pulse, double ringAngle) {
    final palette = context.palette;
    return Transform.rotate(
      angle: ringAngle,
      child: Container(
        width: ringSize,
        height: ringSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: palette.secondary.withValues(alpha: 0.08 + pulse * 0.18),
            width: 1.2,
          ),
          gradient: SweepGradient(
            startAngle: ringAngle,
            colors: [
              palette.primary.withValues(alpha: pulse * 0.04),
              palette.secondary.withValues(alpha: pulse * 0.16),
              palette.accent.withValues(alpha: pulse * 0.08),
              Colors.transparent,
              Colors.transparent,
            ],
            stops: const [0.0, 0.18, 0.32, 0.55, 1.0],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ringSize = _ringDiameter();

    return AnimatedBuilder(
      animation: _ring,
      builder: (context, _) {
        final pulse = 0.5 + math.sin(_ring.value * math.pi * 2) * 0.22;
        final ringAngle = _ring.value * 2 * math.pi;
        final breathe = 1 + math.sin(_ring.value * math.pi * 2) * 0.008;

        if (!widget.showText) {
          return Transform.scale(
            scale: breathe,
            child: SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  _buildRing(ringSize, pulse, ringAngle),
                  ConfidiaLogoMark(size: widget.size),
                ],
              ),
            ),
          );
        }

        return Transform.scale(
          scale: breathe,
          child: SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _buildRing(ringSize, pulse, ringAngle),
                ConfidiaLogo(size: widget.size, showText: true),
              ],
            ),
          ),
        );
      },
    );
  }
}
