import 'package:flutter/material.dart';

/// Calibrates overlapping entrance animations (staggered starts, not sequential).
class ConfidiaPageRevealTiming {
  final Duration targetTotal;
  final Duration itemDuration;
  final double slideOffset;

  const ConfidiaPageRevealTiming({
    required this.targetTotal,
    required this.itemDuration,
    this.slideOffset = 72,
  });

  /// Fast cascade — entire first viewport settles in ~800 ms with heavy overlap.
  static const standard = ConfidiaPageRevealTiming(
    targetTotal: Duration(milliseconds: 800),
    itemDuration: Duration(milliseconds: 400),
    slideOffset: 72,
  );

  /// Slow cascade for hero pages (e.g. notifications).
  static const slow = ConfidiaPageRevealTiming(
    targetTotal: Duration(milliseconds: 2800),
    itemDuration: Duration(milliseconds: 900),
    slideOffset: 56,
  );

  Duration staggerDelay(int index, int staggerCount) {
    if (staggerCount <= 1) return Duration.zero;
    final cappedIndex = index.clamp(0, staggerCount - 1);
    final windowMs = targetTotal.inMilliseconds - itemDuration.inMilliseconds;
    final step = windowMs / (staggerCount - 1);
    return Duration(milliseconds: (cappedIndex * step).round());
  }

  /// Estimates how many list items fit in the first screen for stagger timing.
  static int staggerCount(
    BuildContext context,
    int itemCount, {
    double itemExtent = 84,
    double overhead = 300,
    int maxItems = 10,
  }) {
    if (itemCount <= 1) return itemCount;
    final viewport = MediaQuery.sizeOf(context).height - overhead;
    final visible = (viewport / itemExtent).ceil().clamp(1, maxItems);
    return itemCount.clamp(1, visible);
  }
}

/// Slides content in from the right with a fade, staggered for page entrances.
class ConfidiaPageReveal extends StatefulWidget {
  final int index;
  final int staggerCount;
  final Widget child;
  final ConfidiaPageRevealTiming timing;

  const ConfidiaPageReveal({
    super.key,
    required this.index,
    required this.staggerCount,
    required this.child,
    this.timing = ConfidiaPageRevealTiming.standard,
  });

  @override
  State<ConfidiaPageReveal> createState() => _ConfidiaPageRevealState();
}

class _ConfidiaPageRevealState extends State<ConfidiaPageReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.timing.itemDuration,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    final delay = widget.timing.staggerDelay(widget.index, widget.staggerCount);
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset((1 - t) * widget.timing.slideOffset, 0),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
