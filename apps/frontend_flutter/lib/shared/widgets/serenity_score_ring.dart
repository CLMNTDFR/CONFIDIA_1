import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Anneau de score sérénité animé (dashboard, chip, moments).
class SerenityScoreRing extends StatelessWidget {
  final int score;
  final String label;
  final Color color;
  final Animation<double>? pulse;
  final double size;
  final double scoreFontSize;
  final double labelFontSize;
  final double strokeWidth;
  /// Si false, l'anneau suit [score] immédiatement (compteur externe).
  final bool animateFromZero;
  final bool showLabel;

  const SerenityScoreRing({
    super.key,
    required this.score,
    required this.label,
    required this.color,
    this.pulse,
    this.size = 54,
    this.scoreFontSize = 18,
    this.labelFontSize = 9,
    this.strokeWidth = 3.5,
    this.animateFromZero = true,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final scoreText = Center(
      child: Text(
        '$score',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
              fontSize: scoreFontSize,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
      ),
    );

    Widget ring;
    if (reduceMotion || !animateFromZero) {
      ring = CustomPaint(
        size: Size(size, size),
        painter: _SerenityScoreRingPainter(
          progress: score / 100,
          color: color,
          strokeWidth: strokeWidth,
        ),
        child: scoreText,
      );
    } else {
      ring = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) {
          return CustomPaint(
            size: Size(size, size),
            painter: _SerenityScoreRingPainter(
              progress: progress,
              color: color,
              strokeWidth: strokeWidth,
            ),
            child: child,
          );
        },
        child: scoreText,
      );
    }

    final pulsed = pulse == null || reduceMotion
        ? SizedBox(width: size, height: size, child: ring)
        : AnimatedBuilder(
            animation: pulse!,
            builder: (context, child) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1 + pulse!.value * 0.08),
                      blurRadius: 8 + pulse!.value * 4,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: ring,
          );

    if (!showLabel) return pulsed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pulsed,
        const SizedBox(height: 4),
        SizedBox(
          width: size + 18,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.1,
                ),
          ),
        ),
      ],
    );
  }
}

class _SerenityScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _SerenityScoreRingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    const start = -math.pi / 2;

    final track = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, math.pi * 2, false, track);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      math.pi * 2 * progress,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _SerenityScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
