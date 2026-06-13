import 'package:flutter/material.dart';

import '../../core/theme/theme_context.dart';
import 'confidia_ai_robot.dart';

/// Nom de marque « Cofid-IA » en deux couleurs (primary + secondary).
class CofidIaBrand extends StatelessWidget {
  final double? fontSize;
  final FontWeight fontWeight;

  const CofidIaBrand({
    super.key,
    this.fontSize,
    this.fontWeight = FontWeight.w800,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final base = (fontSize ?? Theme.of(context).textTheme.titleSmall?.fontSize ?? 14);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Confid-',
            style: TextStyle(
              fontSize: base,
              fontWeight: fontWeight,
              color: palette.primary,
              letterSpacing: -0.3,
            ),
          ),
          TextSpan(
            text: 'IA',
            style: TextStyle(
              fontSize: base,
              fontWeight: fontWeight,
              color: palette.secondary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// En-tête sobre pour les modules IA : logo + marque + sous-titre optionnel.
class CofidIaPanelHeader extends StatelessWidget {
  final bool speaking;
  final String? subtitle;
  final Widget? trailing;
  final double robotSize;

  const CofidIaPanelHeader({
    super.key,
    this.speaking = false,
    this.subtitle,
    this.trailing,
    this.robotSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConfidiaAiRobot(size: robotSize, speaking: speaking),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CofidIaBrand(),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
