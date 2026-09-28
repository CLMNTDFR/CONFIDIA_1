import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/theme_context.dart';

abstract final class ConfidiaAiAssets {
  static const blue = 'assets/ai/blue-ia.png';
  static const pink = 'assets/ai/pink-ia.png';

  static String forPalette(ConfidiaPalette palette) =>
      palette.id == ConfidiaPaletteId.rose ? pink : blue;
}

/// AI assistant logo: fixed PNG per theme, discreet gray halo when [speaking].
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
        final haloSize = widget.size * (1.05 + t * 0.12);
        final haloAlpha = t * (isDark ? 0.08 : 0.06);
        final glowPad = widget.speaking ? widget.size * 0.4 : pad;

        return SizedBox(
          width: widget.size + glowPad * 2,
          height: widget.size + glowPad * 2,
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
                        color: (isDark ? Colors.white : const Color(0xFF94A3B8))
                            .withValues(alpha: haloAlpha),
                        blurRadius: widget.size * 0.36,
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
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
}
