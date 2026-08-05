import 'package:equatable/equatable.dart';

import '../../shared/models/calendar_event_model.dart';
import '../../shared/models/document_model.dart';
import '../../shared/models/payment_model.dart';

enum DayPriorityKind { payment, document, appointment, messaging, other }

class DayPriority extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final DayPriorityKind kind;
  final String route;
  final String? tag;
  /// Points de sérénité estimés si l'action est réalisée.
  final int serenityGain;

  const DayPriority({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.route,
    this.tag,
    this.serenityGain = 0,
  });

  @override
  List<Object?> get props => [id, title, kind, route, serenityGain];
}

/// Compteurs du bandeau « En un coup d'œil ».
class DayGlanceMetrics extends Equatable {
  final int newDocuments;
  final int appointmentsToday;
  final int deadlinesToday;
  final int paymentsDue;
  final int serenityScore;

  const DayGlanceMetrics({
    required this.newDocuments,
    required this.appointmentsToday,
    required this.deadlinesToday,
    required this.paymentsDue,
    required this.serenityScore,
  });

  @override
  List<Object?> get props =>
      [newDocuments, appointmentsToday, deadlinesToday, paymentsDue, serenityScore];
}

class DayBriefing extends Equatable {
  final String narrative;
  final List<DayPriority> priorities;
  final List<PaymentModel> urgentPayments;
  final List<CalendarEventModel> todaysAppointments;
  final List<DocumentModel> newDocuments;
  final DayGlanceMetrics glance;
  final int currentScore;
  final int projectedScore;
  final String? valueMessage;
  final DateTime generatedAt;

  const DayBriefing({
    required this.narrative,
    required this.priorities,
    required this.urgentPayments,
    required this.todaysAppointments,
    required this.newDocuments,
    required this.glance,
    required this.currentScore,
    required this.projectedScore,
    this.valueMessage,
    required this.generatedAt,
  });

  int get totalGain => priorities.fold<int>(0, (sum, p) => sum + p.serenityGain);

  @override
  List<Object?> get props => [narrative, priorities, glance, currentScore, projectedScore, generatedAt];
}
