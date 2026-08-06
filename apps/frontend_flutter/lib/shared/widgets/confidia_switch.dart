import 'package:flutter/material.dart';

import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';

/// Interrupteur premium compact  -  transparence, reflet et léger glow.
class ConfidiaSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ConfidiaSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  State<ConfidiaSwitch> createState() => _ConfidiaSwitchState();
}

class _ConfidiaSwitchState extends State<ConfidiaSwitch> {
  static const _trackW = 36.0;
  static const _trackH = 20.0;
  static const _thumb = 14.0;
  static const _pad = 3.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onChanged != null;
    final on = widget.value;

    return GestureDetector(
      onTap: enabled ? () => widget.onChanged!(!on) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: _trackW,
        height: _trackH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_trackH / 2),
          gradient: on
              ? LinearGradient(
                  colors: [
                    context.palette.primary.withValues(alpha: enabled ? 0.95 : 0.5),
                    context.palette.secondary.withValues(alpha: enabled ? 0.85 : 0.45),
                  ],
                )
              : null,
          color: on
              ? null
              : (isDark ? Colors.white : Colors.black).withValues(alpha: enabled ? 0.08 : 0.05),
          border: Border.all(
            color: on
                ? context.palette.secondary.withValues(
                    alpha: enabled ? AppOpacity.borderFocus : AppOpacity.borderStrong,
                  )
                : AppBorders.standard(isDark).color,
          ),
          boxShadow: on && enabled
              ? [
                  BoxShadow(
                    color: context.palette.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: context.palette.secondary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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
              color: Colors.white.withValues(alpha: enabled ? 0.98 : 0.7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
                if (on)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.55),
                    blurRadius: 2,
                    spreadRadius: -1,
                    offset: const Offset(-1, -1),
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
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: Padding(
        padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    const SizedBox(height: 2),
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
    );
  }
}
