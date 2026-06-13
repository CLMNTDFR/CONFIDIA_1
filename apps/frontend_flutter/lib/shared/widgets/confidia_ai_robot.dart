import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/theme_context.dart';

abstract final class ConfidiaAiAssets {
  static const blue = 'assets/ai/blue-ia.png';
  static const pink = 'assets/ai/pink-ia.png';

  static String forPalette(ConfidiaPalette palette) =>
      palette.id == ConfidiaPaletteId.rose ? pink : blue;
}

/// Logo assistant IA : PNG fixe par thème, halo circulaire pulsant quand [speaking].
class ConfidiaAiRobot extends StatefulWidget {
  final double size;
  final bool speaking;

  const ConfidiaAiRobot({
    super.key,
    this.size = 40,
    this.speaking = false,
  });

  @override
  State<ConfidiaAiRobot> createState() => _ConfidiaAiRobotState();
}

class _ConfidiaAiRobotState extends State<ConfidiaAiRobot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _syncPulse();
  }

  @override
  void didUpdateWidget(ConfidiaAiRobot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speaking != widget.speaking) _syncPulse();
  }

  void _syncPulse() {
    if (widget.speaking) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = ConfidiaAiAssets.forPalette(palette);
    final pad = widget.size * 0.12;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = widget.speaking ? _pulse.value : 0.0;
        final haloSize = widget.size * (1.05 + t * 0.18);
        final primaryAlpha = (isDark ? 0.07 : 0.09) + t * (isDark ? 0.06 : 0.08);
        final secondaryAlpha = (isDark ? 0.05 : 0.07) + t * (isDark ? 0.05 : 0.06);

        return SizedBox(
          width: widget.size + pad * 2,
          height: widget.size + pad * 2,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (widget.speaking)
                Container(
                  width: haloSize,
                  height: haloSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.primary.withValues(alpha: primaryAlpha),
                        blurRadius: widget.size * 0.42,
                        spreadRadius: widget.size * 0.02,
                      ),
                      BoxShadow(
                        color: palette.secondary.withValues(alpha: secondaryAlpha),
                        blurRadius: widget.size * 0.28,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              child!,
            ],
          ),
        );
      },
      child: Image.asset(
        asset,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Icon(
          Icons.smart_toy_rounded,
          size: widget.size * 0.72,
          color: palette.primary,
        ),
      ),
    );
  }
}
