import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
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

const eventTypeConfigs = <EventTypeConfig>[
  EventTypeConfig(
    type: EventType.deadline,
    label: 'Échéance',
    description: 'Factures, taxes, contrats',
    color: ConfidiaColors.primary,
    icon: Icons.flag_rounded,
  ),
  EventTypeConfig(
    type: EventType.appointment,
    label: 'Rendez-vous',
    description: 'Médical, administratif',
    color: ConfidiaColors.accent,
    icon: Icons.event_available_rounded,
  ),
  EventTypeConfig(
    type: EventType.meeting,
    label: 'Réunion',
    description: 'Professionnel ou personnel',
    color: ConfidiaColors.secondary,
    icon: Icons.groups_rounded,
  ),
  EventTypeConfig(
    type: EventType.reminder,
    label: 'Rappel',
    description: 'Renouvellements, démarches',
    color: Color(0xFFE8A838),
    icon: Icons.notifications_active_rounded,
  ),
];

EventTypeConfig configFor(EventType type) =>
    eventTypeConfigs.firstWhere((c) => c.type == type, orElse: () => eventTypeConfigs.last);

Color colorForEventType(EventType type) => configFor(type).color;

Color eventColor(CalendarEventModel event) => colorForEventType(event.eventType);
