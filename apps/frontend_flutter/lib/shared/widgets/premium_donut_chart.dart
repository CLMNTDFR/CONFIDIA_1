import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/dashboard/dashboard_chart_data.dart';

/// Anneau fin premium  -  arcs arrondis (`StrokeCap.round`), surbrillance au survol.
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
  final ValueChanged<int>? onSectionTap;

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
    this.onSectionTap,
  });

  /// Angle médian d'une portion (repère `drawArc`, 0 = droite, sens horaire).
  static double sliceMidpointAngle(int index, List<ChartSlice> slices, double gapDegrees) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total == 0) return -math.pi / 2;

    final gapRad = gapDegrees * math.pi / 180;
    final available = 2 * math.pi - gapRad * slices.length;
    var start = -math.pi / 2;

    for (var i = 0; i < index; i++) {
      start += available * (slices[i].value / total) + gapRad;
    }
    final sweep = available * (slices[index].value / total);
    return start + gapRad / 2 + sweep / 2;
  }

  /// Rotation pour amener la portion active vers la zone visible (3 h, face à la liste).
  static double rotationForActiveSlice(int? index, List<ChartSlice> slices, double gapDegrees) {
    if (index == null) return 0;
    return -sliceMidpointAngle(index, slices, gapDegrees);
  }

  void _probe(BuildContext context, Offset local, double rotationOffset) {
    final index = _PremiumDonutPainter.probeSection(
      position: local,
      size: Size(size, size),
      slices: slices,
      strokeWidth: strokeWidth,
      gapDegrees: gapDegrees,
      rotationOffset: rotationOffset,
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
    final targetRotation = rotationForActiveSlice(activeIndex, slices, gapDegrees);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: targetRotation),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (context, rotationOffset, _) {
        return MouseRegion(
          cursor: onSectionTap != null ? SystemMouseCursors.click : MouseCursor.defer,
          onExit: (_) => onSectionExit?.call(),
          child: Listener(
            onPointerMove: (event) => _probe(context, event.localPosition, rotationOffset),
            onPointerDown: (event) => _probe(context, event.localPosition, rotationOffset),
            onPointerUp: (event) {
              final index = _PremiumDonutPainter.probeSection(
                position: event.localPosition,
                size: Size(size, size),
                slices: slices,
                strokeWidth: strokeWidth,
                gapDegrees: gapDegrees,
                rotationOffset: rotationOffset,
              );
              if (index != null) onSectionTap?.call(index);
              onSectionExit?.call();
            },
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(size, size),
                    painter: _PremiumDonutPainter(
                      slices: slices,
                      strokeWidth: strokeWidth,
                      gapDegrees: gapDegrees,
                      activeIndex: activeIndex,
                      baseOpacity: baseOpacity,
                      rotationOffset: rotationOffset,
                    ),
                  ),
                  if (center != null) center!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PremiumDonutPainter extends CustomPainter {
  final List<ChartSlice> slices;
  final double strokeWidth;
  final double gapDegrees;
  final int? activeIndex;
  final double baseOpacity;
  final double rotationOffset;

  const _PremiumDonutPainter({
    required this.slices,
    required this.strokeWidth,
    required this.gapDegrees,
    required this.activeIndex,
    required this.baseOpacity,
    this.rotationOffset = 0,
  });

  static bool _angleInSweep(double angle, double start, double sweep) {
    final end = start + sweep;
    final normalized = _normalizeAngle(angle);
    final s = _normalizeAngle(start);
    final e = _normalizeAngle(end);
    if (s <= e) return normalized >= s && normalized <= e;
    return normalized >= s || normalized <= e;
  }

  static double _normalizeAngle(double angle) {
    var a = angle % (2 * math.pi);
    if (a < 0) a += 2 * math.pi;
    return a;
  }

  static int? probeSection({
    required Offset position,
    required Size size,
    required List<ChartSlice> slices,
    required double strokeWidth,
    required double gapDegrees,
    double rotationOffset = 0,
  }) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final outer = math.min(size.width, size.height) / 2 - 2;
    final inner = outer - strokeWidth - 8;
    if (distance < inner || distance > outer + 10) return null;

    var angle = math.atan2(dy, dx) - rotationOffset;

    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total == 0) return null;

    final gapRad = gapDegrees * math.pi / 180;
    final available = 2 * math.pi - gapRad * slices.length;
    var start = -math.pi / 2;

    for (var i = 0; i < slices.length; i++) {
      final sweep = available * (slices[i].value / total);
      if (_angleInSweep(angle, start + gapRad / 2, sweep)) return i;
      start += sweep + gapRad;
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

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationOffset);
    canvas.translate(-center.dx, -center.dy);

    for (var i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweep = available * (slice.value / total);
      final active = activeIndex == i;
      final hasFocus = activeIndex != null;
      final radius = outer + (active ? 4 : 0);
      final width = active ? strokeWidth + 4 : strokeWidth;

      final rect = Rect.fromCircle(center: center, radius: radius - width / 2);
      final opacity = active
          ? 0.82
          : hasFocus
              ? 0.14
              : baseOpacity;

      if (active) {
        final glow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width + 6
          ..strokeCap = StrokeCap.round
          ..color = slice.color.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
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

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PremiumDonutPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.slices != slices ||
      oldDelegate.baseOpacity != baseOpacity ||
      oldDelegate.rotationOffset != rotationOffset;
}
