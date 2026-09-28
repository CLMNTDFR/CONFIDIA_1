import 'package:flutter/material.dart';

import '../../core/theme/theme_context.dart';
import '../brands/brand_assets.dart';
import '../models/calendar_event_model.dart';
import '../models/email_model.dart';
import 'brand_icon.dart';

class MailProviderChip extends StatelessWidget {
  final MailProvider provider;
  final bool compact;

  const MailProviderChip({super.key, required this.provider, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 8, vertical: compact ? 4 : 4),
      decoration: BoxDecoration(
        color: provider.brandColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: provider.brandColor.withValues(alpha: 0.3)),
      ),
      child: BrandLabel(
        assetPath: provider.logoAsset,
        fallbackIcon: provider.icon,
        fallbackColor: provider.brandColor,
        label: provider.label,
        iconSize: compact ? 12 : 14,
        showLabel: !compact,
        labelStyle: TextStyle(fontSize: compact ? 9 : 10, fontWeight: FontWeight.w600, color: provider.brandColor),
      ),
    );
  }
}

class CalendarSourceChip extends StatelessWidget {
  final CalendarSource source;
  final bool compact;

  const CalendarSourceChip({super.key, required this.source, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (source == CalendarSource.confidia) return const SizedBox.shrink();

    final color = source.themeColor(context.palette);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 8, vertical: compact ? 4 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: BrandLabel(
        assetPath: source.logoAsset,
        fallbackIcon: Icons.calendar_month_rounded,
        fallbackColor: color,
        label: source.label,
        iconSize: compact ? 11 : 13,
        showLabel: true,
        labelStyle: TextStyle(fontSize: compact ? 9 : 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Logo for storage services (Paperless, Nextcloud).
class StorageBrandChip extends StatelessWidget {
  final String assetPath;
  final String label;
  final Color color;
  final IconData fallbackIcon;

  const StorageBrandChip({
    super.key,
    required this.assetPath,
    required this.label,
    required this.color,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandIcon(assetPath: assetPath, fallbackIcon: fallbackIcon, fallbackColor: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
