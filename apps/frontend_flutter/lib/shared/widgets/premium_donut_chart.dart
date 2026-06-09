import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/dashboard/dashboard_chart_data.dart';

/// Anneau fin premium — arcs arrondis (`StrokeCap.round`), surbrillance au survol.
class PremiumDonutChart extends StatelessWidget {
  final List<ChartSlice> slices;
  final double size;
  final double strokeWidth;
  final double gapDegrees;
  final double baseOpacity;
  final int? activeIndex;
  final Widget? center;
  final ValueChanged<int>? onSectionEnter;
  final VoidCallback? onSectionExit;

  const PremiumDonutChart({
    super.key,
    required this.slices,
    this.size = 200,
    this.strokeWidth = 7,
    this.gapDegrees = 5,
    this.baseOpacity = 0.34,
    this.activeIndex,
    this.center,
    this.onSectionEnter,
    this.onSectionExit,
  });

  void _probe(BuildContext context, Offset local) {
    final index = _PremiumDonutPainter.probeSection(
      position: local,
      size: Size(size, size),
      slices: slices,
      strokeWidth: strokeWidth,
      gapDegrees: gapDegrees,
    );
    if (index == activeIndex) return;
    if (index != null) {
      onSectionEnter?.call(index);
    } else {
      onSectionExit?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) => _probe(context, event.localPosition),
      onPointerDown: (event) => _probe(context, event.localPosition),
      onPointerUp: (_) => onSectionExit?.call(),
      child: MouseRegion(
        onExit: (_) => onSectionExit?.call(),
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _PremiumDonutPainter(
              slices: slices,
              strokeWidth: strokeWidth,
              gapDegrees: gapDegrees,
              activeIndex: activeIndex,
              baseOpacity: baseOpacity,
            ),
            child: Center(child: center),
          ),
        ),
      ),
    );
  }
}

class _PremiumDonutPainter extends CustomPainter {
  final List<ChartSlice> slices;
  final double strokeWidth;
  final double gapDegrees;
  final int? activeIndex;
  final double baseOpacity;

  const _PremiumDonutPainter({
    required this.slices,
    required this.strokeWidth,
    required this.gapDegrees,
    required this.activeIndex,
    required this.baseOpacity,
  });

  static int? probeSection({
    required Offset position,
    required Size size,
    required List<ChartSlice> slices,
    required double strokeWidth,
    required double gapDegrees,
  }) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final outer = math.min(size.width, size.height) / 2 - 2;
    final inner = outer - strokeWidth - 8;
    if (distance < inner || distance > outer + 10) return null;

    var angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;
    angle = (angle + math.pi / 2) % (2 * math.pi);

    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total == 0) return null;

    final gapRad = gapDegrees * math.pi / 180;
    final available = 2 * math.pi - gapRad * slices.length;
    var cursor = 0.0;

    for (var i = 0; i < slices.length; i++) {
      final sweep = available * (slices[i].value / total);
      if (angle >= cursor && angle <= cursor + sweep) return i;
      cursor += sweep + gapRad;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = math.min(size.width, size.height) / 2 - 2;
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total == 0) return;

    final gapRad = gapDegrees * math.pi / 180;
    final available = 2 * math.pi - gapRad * slices.length;
    var start = -math.pi / 2;

    for (var i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweep = available * (slice.value / total);
      final active = activeIndex == i;
      final hasFocus = activeIndex != null;
      final radius = outer + (active ? 6 : 0);
      final width = active ? strokeWidth + 5 : strokeWidth;

      final rect = Rect.fromCircle(center: center, radius: radius - width / 2);
      final opacity = active
          ? 1.0
          : hasFocus
              ? 0.14
              : baseOpacity;

      if (active) {
        final glow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width + 8
          ..strokeCap = StrokeCap.round
          ..color = slice.color.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawArc(rect, start + gapRad / 2, sweep, false, glow);
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            slice.color.withValues(alpha: opacity),
            slice.color.withValues(alpha: opacity * 0.7),
          ],
        ).createShader(rect);

      canvas.drawArc(rect, start + gapRad / 2, sweep, false, paint);
      start += sweep + gapRad;
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumDonutPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.slices != slices ||
      oldDelegate.baseOpacity != baseOpacity;
}
