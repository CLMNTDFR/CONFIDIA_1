import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../shared/models/calendar_event_model.dart';

class EventTypeConfig {
  final EventType type;
  final String label;
  final String description;
  final Color color;
  final IconData icon;

  const EventTypeConfig({
    required this.type,
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
  });
}

List<EventTypeConfig> eventTypeConfigs(ConfidiaPalette palette) => [
      EventTypeConfig(
        type: EventType.deadline,
        label: 'Échéance',
        description: 'Factures, taxes, contrats',
        color: palette.primary,
        icon: Icons.flag_rounded,
      ),
      EventTypeConfig(
        type: EventType.appointment,
        label: 'Rendez-vous',
        description: 'Médical, administratif',
        color: palette.accent,
        icon: Icons.event_available_rounded,
      ),
      EventTypeConfig(
        type: EventType.meeting,
        label: 'Réunion',
        description: 'Professionnel ou personnel',
        color: palette.secondary,
        icon: Icons.groups_rounded,
      ),
      EventTypeConfig(
        type: EventType.reminder,
        label: 'Rappel',
        description: 'Renouvellements, démarches',
        color: const Color(0xFFE8A838),
        icon: Icons.notifications_active_rounded,
      ),
    ];

EventTypeConfig configFor(EventType type, ConfidiaPalette palette) =>
    eventTypeConfigs(palette).firstWhere((c) => c.type == type, orElse: () => eventTypeConfigs(palette).last);

Color colorForEventType(EventType type, ConfidiaPalette palette) => configFor(type, palette).color;

Color eventColor(CalendarEventModel event, ConfidiaPalette palette) => colorForEventType(event.eventType, palette);
