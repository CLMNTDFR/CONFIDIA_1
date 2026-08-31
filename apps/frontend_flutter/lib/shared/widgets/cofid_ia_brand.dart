import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import 'confidia_ai_robot.dart';
import 'confidia_demo_badge.dart';

/// Nom de marque « Confid•IA » en monochrome (textPrimary + textSecondary).
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = (fontSize ?? Theme.of(context).textTheme.titleSmall?.fontSize ?? 14);
    final primary = ConfidiaColors.textPrimary(isDark);
    final secondary = ConfidiaColors.textSecondary(isDark);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Confid',
            style: TextStyle(
              fontSize: base,
              fontWeight: fontWeight,
              color: primary,
              letterSpacing: -0.3,
            ),
          ),
          TextSpan(
            text: '•',
            style: TextStyle(
              fontSize: base,
              fontWeight: fontWeight,
              color: secondary,
              letterSpacing: -0.3,
            ),
          ),
          TextSpan(
            text: 'IA',
            style: TextStyle(
              fontSize: base,
              fontWeight: fontWeight,
              color: primary,
              letterSpacing: -0.3,
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
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Flexible(child: CofidIaBrand()),
                  const SizedBox(width: 8),
                  const ConfidiaDemoBadge(compact: true),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
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
