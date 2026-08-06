import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

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
            child: _Orb(color: Colors.white.withValues(alpha: 0.07), size: 320),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: _Orb(color: const Color(0xFF94A3B8).withValues(alpha: 0.08), size: 280),
          ),
          Positioned(
            bottom: -60,
            right: 100,
            child: _Orb(color: Colors.white.withValues(alpha: 0.05), size: 240),
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
