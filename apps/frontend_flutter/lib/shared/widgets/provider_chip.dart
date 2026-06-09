import 'package:flutter/material.dart';

import '../models/calendar_event_model.dart';
import '../models/email_model.dart';

class MailProviderChip extends StatelessWidget {
  final MailProvider provider;
  final bool compact;

  const MailProviderChip({super.key, required this.provider, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: provider.brandColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: provider.brandColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(provider.icon, size: compact ? 10 : 12, color: provider.brandColor),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(provider.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: provider.brandColor)),
          ],
        ],
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: source.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        source.label,
        style: TextStyle(fontSize: compact ? 9 : 10, fontWeight: FontWeight.w700, color: source.color),
      ),
    );
  }
}
