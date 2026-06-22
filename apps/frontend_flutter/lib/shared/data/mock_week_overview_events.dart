import '../models/calendar_event_model.dart';
import '../models/week_overview_model.dart';

/// Événements de la semaine courante — alignés sur le widget tableau de bord.
abstract final class MockWeekOverviewEvents {
  static DateTime _weekDay(int weekday, {int hour = 9, int minute = 0}) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day + weekday, hour, minute);
  }

  static WeekCalendarScope scopeFor(CalendarEventModel event) {
    return event.weekScope ?? _inferScope(event);
  }

  static WeekCalendarScope _inferScope(CalendarEventModel event) {
    if (event.eventType == EventType.meeting) return WeekCalendarScope.professional;
    if (event.eventType == EventType.deadline) return WeekCalendarScope.family;
    return WeekCalendarScope.personal;
  }

  static final events = [
  // Lundi — chargée
  _e(0, EventType.meeting, WeekCalendarScope.professional, 'Stand-up équipe', 9),
  _e(0, EventType.meeting, WeekCalendarScope.professional, 'Revue client', 10),
  _e(0, EventType.deadline, WeekCalendarScope.family, 'Paiement loyer', 11),
  _e(0, EventType.appointment, WeekCalendarScope.personal, 'Médecin', 14),
  _e(0, EventType.meeting, WeekCalendarScope.professional, 'Point projet', 15),
  _e(0, EventType.reminder, WeekCalendarScope.personal, 'Renouvellement CNI', 16),
  _e(0, EventType.deadline, WeekCalendarScope.family, 'Facture EDF', 17),
  _e(0, EventType.meeting, WeekCalendarScope.professional, 'Comité direction', 18),
  // Mardi — moyenne
  _e(1, EventType.meeting, WeekCalendarScope.professional, 'Réunion fournisseur', 10),
  _e(1, EventType.deadline, WeekCalendarScope.family, 'Cotisation MAIF', 11),
  _e(1, EventType.appointment, WeekCalendarScope.personal, 'Dentiste', 15),
  _e(1, EventType.reminder, WeekCalendarScope.personal, 'Relance assurance', 17),
  // Mercredi — chargée
  _e(2, EventType.meeting, WeekCalendarScope.professional, 'Sprint planning', 9),
  _e(2, EventType.meeting, WeekCalendarScope.professional, 'Atelier UX', 10),
  _e(2, EventType.deadline, WeekCalendarScope.family, 'Déclaration CAF', 11),
  _e(2, EventType.appointment, WeekCalendarScope.personal, 'Notaire', 13),
  _e(2, EventType.meeting, WeekCalendarScope.professional, 'Revue CONFIDIA', 14),
  _e(2, EventType.deadline, WeekCalendarScope.family, 'Taxe foncière', 15),
  _e(2, EventType.reminder, WeekCalendarScope.personal, 'Passeport', 16),
  _e(2, EventType.meeting, WeekCalendarScope.professional, 'Call investisseur', 17),
  _e(2, EventType.appointment, WeekCalendarScope.personal, 'Coiffeur', 18),
  // Jeudi — calme
  _e(3, EventType.appointment, WeekCalendarScope.personal, 'Courses', 11),
  _e(3, EventType.reminder, WeekCalendarScope.family, 'Anniversaire', 18),
  // Vendredi — moyenne
  _e(4, EventType.meeting, WeekCalendarScope.professional, 'Bilan hebdo', 9),
  _e(4, EventType.deadline, WeekCalendarScope.family, 'Paiement internet', 10),
  _e(4, EventType.meeting, WeekCalendarScope.professional, 'Point RH', 11),
  _e(4, EventType.appointment, WeekCalendarScope.personal, 'Sport', 17),
  _e(4, EventType.reminder, WeekCalendarScope.personal, 'Contrat Orange', 18),
  _e(4, EventType.meeting, WeekCalendarScope.family, 'Réunion parents', 19),
  // Samedi — calme
  _e(5, EventType.appointment, WeekCalendarScope.family, 'Marché', 10),
  ];

  static CalendarEventModel _e(
    int dayOffset,
    EventType type,
    WeekCalendarScope scope,
    String title,
    int hour,
  ) {
    final start = _weekDay(dayOffset, hour: hour);
    return CalendarEventModel(
      id: 'week-$dayOffset-$hour-$title',
      title: title,
      start: start,
      end: start.add(const Duration(hours: 1)),
      eventType: type,
      weekScope: scope,
    );
  }
}
