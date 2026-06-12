import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/spacing.dart';

/// Logo CONFIDIA · prêt à recevoir une image via [imageAssetPath].
class ConfidiaLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String? imageAssetPath;

  const ConfidiaLogo({
    super.key,
    this.size = 36,
    this.showText = true,
    this.imageAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoMark(size: size, imageAssetPath: imageAssetPath),
        if (showText) ...[
          const SizedBox(width: ConfidiaSpacing.sm + 2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => context.palette.brandGradient.createShader(bounds),
                child: Text(
                  'CONFIDIA',
                  style: TextStyle(
                    fontSize: size * 0.45,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
              Text(
                'Hub numérique',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w500,
                  color: ConfidiaColors.textSecondary(isDark),
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  final double size;
  final String? imageAssetPath;

  const _LogoMark({required this.size, this.imageAssetPath});

  @override
  Widget build(BuildContext context) {
    if (imageAssetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(imageAssetPath!, width: size, height: size, fit: BoxFit.cover),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: context.palette.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: context.palette.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Icon(Icons.shield_rounded, color: Colors.white, size: size * 0.52),
    );
  }
}
