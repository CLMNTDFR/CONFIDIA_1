import 'package:flutter/material.dart';

import '../../core/theme/tokens/tokens.dart';
import 'confidia_tappable.dart';

/// Interrupteur compact  -  piste discrète, pouce calme.
class ConfidiaSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ConfidiaSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  static const _trackW = 36.0;
  static const _trackH = 20.0;
  static const _thumb = 14.0;
  static const _pad = 3.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onChanged != null;
    final on = value;
    final ink = isDark ? Colors.white : Colors.black;

    return ConfidiaTappable(
      onTap: enabled ? () => onChanged!(!on) : null,
      pressScale: 0.94,
      borderRadius: AppRadius.pillAll,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: _trackW,
        height: _trackH,
        decoration: BoxDecoration(
          borderRadius: AppRadius.pillAll,
          color: on
              ? ink.withValues(alpha: enabled ? (isDark ? 0.34 : 0.22) : 0.14)
              : ink.withValues(alpha: enabled ? 0.08 : 0.05),
          border: Border.all(
            color: on
                ? ink.withValues(alpha: isDark ? 0.45 : 0.28)
                : AppBorders.standard(isDark).color,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: _thumb,
            height: _thumb,
            margin: const EdgeInsets.symmetric(horizontal: _pad),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black).withValues(alpha: enabled ? 0.55 : 0.35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ligne de réglage avec [ConfidiaSwitch] à droite.
class ConfidiaSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry? contentPadding;

  const ConfidiaSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = (isDark ? Colors.white : Colors.black).withValues(
      alpha: isDark ? AppOpacity.hoverInkDark : AppOpacity.hoverInkLight,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.mdAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        mouseCursor: onChanged != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        borderRadius: AppRadius.mdAll,
        hoverColor: ink,
        splashColor: ink.withValues(alpha: AppOpacity.quiet),
        child: Padding(
          padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConfidiaSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
