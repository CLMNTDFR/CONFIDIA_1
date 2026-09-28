import 'package:flutter/material.dart';

/// Durations and curves for premium charts (excluding the donut).
abstract final class PremiumChartMotion {
  static const entryDuration = Duration(milliseconds: 2500);
  static const focusDuration = Duration(milliseconds: 1100);
  static const curve = Curves.easeOutCubic;
}

class PremiumChartMotionValues {
  final double entry;
  final double focus;

  const PremiumChartMotionValues({required this.entry, required this.focus});

  double scaleY(double value) => value * entry;

  double dimOpacity({required bool isActive, double active = 1, double idle = 1, double dimmed = 0.42}) {
    if (focus <= 0) return isActive ? active : idle;
    return isActive ? active : idle + (dimmed - idle) * focus;
  }

  double labelAlpha({required bool isActive, double base = 0.8, double dimmed = 0.45}) {
    if (focus <= 0) return base;
    return isActive ? 1 : base + (dimmed - base) * focus;
  }
}

/// Drives the entry animation (data rise) and the hover focus fade.
class PremiumChartMotionScope extends StatefulWidget {
  final bool hasFocus;
  final Widget Function(BuildContext context, PremiumChartMotionValues motion) builder;

  const PremiumChartMotionScope({
    super.key,
    required this.hasFocus,
    required this.builder,
  });

  @override
  State<PremiumChartMotionScope> createState() => _PremiumChartMotionScopeState();
}

class _PremiumChartMotionScopeState extends State<PremiumChartMotionScope> with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _focus;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(vsync: this, duration: PremiumChartMotion.entryDuration)..forward();
    _focus = AnimationController(vsync: this, duration: PremiumChartMotion.focusDuration);
    if (widget.hasFocus) _focus.forward();
  }

  @override
  void didUpdateWidget(covariant PremiumChartMotionScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasFocus == oldWidget.hasFocus) return;
    if (widget.hasFocus) {
      _focus.forward();
    } else {
      _focus.reverse();
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    _focus.dispose();
    super.dispose();
  }

  PremiumChartMotionValues _values() => PremiumChartMotionValues(
        entry: PremiumChartMotion.curve.transform(_entry.value),
        focus: PremiumChartMotion.curve.transform(_focus.value),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entry, _focus]),
      builder: (context, _) => widget.builder(context, _values()),
    );
  }
}
