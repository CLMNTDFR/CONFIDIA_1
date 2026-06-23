import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';

/// Fond d'accueil post-login  -  orbes flottantes floues, translucides et sobres.
class WelcomeAmbientBackground extends StatefulWidget {
  final Widget child;

  const WelcomeAmbientBackground({super.key, required this.child});

  @override
  State<WelcomeAmbientBackground> createState() => _WelcomeAmbientBackgroundState();
}

class _WelcomeAmbientBackgroundState extends State<WelcomeAmbientBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? ConfidiaColors.darkBackground : ConfidiaColors.lightBackground,
          ),
        ),
        AnimatedBuilder(
          animation: _drift,
          builder: (context, _) {
            final t = _drift.value * math.pi * 2;
            return Stack(
              fit: StackFit.expand,
              children: [
                _AmbientOrb(
                  isDark: isDark,
                  color: palette.primary,
                  center: Offset(
                    0.22 + math.sin(t) * 0.06,
                    0.18 + math.cos(t * 0.7) * 0.05,
                  ),
                  radius: 0.38,
                ),
                _AmbientOrb(
                  isDark: isDark,
                  color: palette.secondary,
                  center: Offset(
                    0.78 + math.cos(t * 0.85) * 0.05,
                    0.32 + math.sin(t * 0.6) * 0.04,
                  ),
                  radius: 0.32,
                ),
                _AmbientOrb(
                  isDark: isDark,
                  color: palette.accent,
                  center: Offset(
                    0.5 + math.sin(t * 0.5 + 1) * 0.08,
                    0.72 + math.cos(t * 0.45) * 0.05,
                  ),
                  radius: 0.28,
                ),
              ],
            );
          },
        ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
            child: const SizedBox.expand(),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final bool isDark;
  final Color color;
  final Offset center;
  final double radius;

  const _AmbientOrb({
    required this.isDark,
    required this.color,
    required this.center,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final diameter = size.shortestSide * radius * 2;
    final left = size.width * center.dx - diameter / 2;
    final top = size.height * center.dy - diameter / 2;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: isDark ? 0.16 : 0.11),
              color.withValues(alpha: isDark ? 0.05 : 0.03),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}
