import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';

class MeshBackground extends StatelessWidget {
  final Widget child;

  const MeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? ConfidiaColors.darkBackground : ConfidiaColors.lightBackground,
            ),
          ),
        ),
        if (isDark) ...[
          Positioned(
            top: -120,
            right: -80,
            child: _Orb(color: context.palette.primary.withValues(alpha: 0.18), size: 320),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: _Orb(color: context.palette.secondary.withValues(alpha: 0.12), size: 280),
          ),
          Positioned(
            bottom: -60,
            right: 100,
            child: _Orb(color: context.palette.accent.withValues(alpha: 0.1), size: 240),
          ),
        ],
        child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;

  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
