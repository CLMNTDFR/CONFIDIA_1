import '../../shared/models/calendar_event_model.dart';
import '../../shared/models/document_model.dart';
import '../../shared/models/email_model.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/services/mock_ai_service.dart';
import '../../shared/services/serenity_service.dart';
import 'day_briefing_model.dart';

/// Agrège les données locales pour le rituel "Commencer ma journée".
abstract final class DayBriefingService {
  static DayBriefing build({
    required String firstName,
    required List<EmailModel> emails,
    required List<CalendarEventModel> events,
    required List<PaymentModel> payments,
    required List<NotificationModel> notifications,
    required List<DocumentModel> documents,
    MockAiService ai = const MockAiService(),
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Horizon aligné sur la démo : factures à +5/+8/+12 j restent actionnables.
    final urgentHorizon = today.add(const Duration(days: 14));

    final currentScore = SerenityService.build(
      firstName: firstName,
      emails: emails,
      events: events,
      payments: payments,
      notifications: notifications,
      documents: documents,
    ).score;

    final urgentPayments = payments
        .where((p) =>
            (p.status == PaymentStatus.pending || p.status == PaymentStatus.waiting) &&
            !p.dueDate.isAfter(urgentHorizon.add(const Duration(hours: 23))))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final todaysAppointments = events
        .where((e) => _isSameDay(e.start, today) && e.eventType != EventType.deadline)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final deadlinesToday = events
        .where((e) => _isSameDay(e.start, today) && e.eventType == EventType.deadline)
        .length;

    final newDocuments = documents.where((d) {
      final created = DateTime(d.created.year, d.created.month, d.created.day);
      return d.isImportant || today.difference(created).inDays <= 2;
    }).toList()
      ..sort((a, b) => b.modified.compareTo(a.modified));

    final pendingPaymentsCount = payments
        .where((p) => p.status == PaymentStatus.pending || p.status == PaymentStatus.waiting)
        .length;

    // Gains marginaux séquentiels : somme des badges = projection affichée.
    final scored = _buildScoredPriorities(
      firstName: firstName,
      emails: emails,
      events: events,
      payments: payments,
      notifications: notifications,
      documents: documents,
      currentScore: currentScore,
      urgentPayments: urgentPayments,
    );

    final totalGain = scored.projectedScore - currentScore;
    String? valueMessage;
    if (urgentPayments.isNotEmpty) {
      final avoided = urgentPayments
          .map(SerenityService.estimatePenaltyAvoided)
          .fold<double>(0, (s, v) => s + v);
      valueMessage =
          'En réglant vos échéances, vous évitez environ ${avoided.toStringAsFixed(0)} € de pénalités.';
    } else if (totalGain > 0) {
      valueMessage =
          'Traitez les priorités du jour pour gagner jusqu\'à +$totalGain pts.';
    }

    final narrative = ai.composeDayNarrative(
      firstName: firstName,
      currentScore: currentScore,
      projectedScore: scored.projectedScore,
      priorityCount: scored.priorities.length,
      urgentPaymentCount: urgentPayments.length,
      appointmentCount: todaysAppointments.length,
      newDocCount: newDocuments.length,
    );

    // Listes affichées = compteurs du coup d'œil (docs / RDV).
    // paymentsDue reste le total des paiements en attente (aperçu portefeuille).
    final priorityPayKeys = {
      for (final p in scored.priorities)
        if (p.kind == DayPriorityKind.payment) p.id,
    };
    final listedPayments = urgentPayments
        .where((p) => !priorityPayKeys.contains('pay-${p.id}'))
        .take(3)
        .toList();
    final listedAppointments = todaysAppointments;
    final listedDocuments = newDocuments;

    return DayBriefing(
      narrative: narrative,
      priorities: scored.priorities,
      urgentPayments: listedPayments,
      todaysAppointments: listedAppointments,
      newDocuments: listedDocuments,
      glance: DayGlanceMetrics(
        newDocuments: listedDocuments.length,
        appointmentsToday: listedAppointments.length,
        deadlinesToday: deadlinesToday,
        paymentsDue: pendingPaymentsCount,
        serenityScore: currentScore,
      ),
      currentScore: currentScore,
      projectedScore: scored.projectedScore,
      valueMessage: valueMessage,
      generatedAt: now,
    );
  }

  static bool _isSameDay(DateTime a, DateTime day) =>
      a.year == day.year && a.month == day.month && a.day == day.day;

  static int _scoreOf({
    required String firstName,
    required List<EmailModel> emails,
    required List<CalendarEventModel> events,
    required List<PaymentModel> payments,
    required List<NotificationModel> notifications,
    required List<DocumentModel> documents,
  }) {
    return SerenityService.build(
      firstName: firstName,
      emails: emails,
      events: events,
      payments: payments,
      notifications: notifications,
      documents: documents,
    ).score;
  }

  /// Priorités qui font réellement monter le score, avec gains cumulatifs cohérents.
  static ({List<DayPriority> priorities, int projectedScore}) _buildScoredPriorities({
    required String firstName,
    required List<EmailModel> emails,
    required List<CalendarEventModel> events,
    required List<PaymentModel> payments,
    required List<NotificationModel> notifications,
    required List<DocumentModel> documents,
    required int currentScore,
    required List<PaymentModel> urgentPayments,
  }) {
    var emailsState = List<EmailModel>.from(emails);
    var paymentsState = List<PaymentModel>.from(payments);
    var runningScore = currentScore;
    final out = <DayPriority>[];

    void tryAdd(DayPriority draft, {List<EmailModel>? nextEmails, List<PaymentModel>? nextPayments}) {
      final nextScore = _scoreOf(
        firstName: firstName,
        emails: nextEmails ?? emailsState,
        events: events,
        payments: nextPayments ?? paymentsState,
        notifications: notifications,
        documents: documents,
      );
      final gain = nextScore - runningScore;
      if (gain <= 0) return;

      out.add(DayPriority(
        id: draft.id,
        title: draft.title,
        subtitle: draft.subtitle,
        kind: draft.kind,
        route: draft.route,
        tag: draft.tag,
        serenityGain: gain,
      ));
      if (nextEmails != null) emailsState = nextEmails;
      if (nextPayments != null) paymentsState = nextPayments;
      runningScore = nextScore;
    }

    for (final p in urgentPayments) {
      final nextPayments = [
        for (final x in paymentsState)
          if (x.id == p.id) x.copyWith(status: PaymentStatus.paid, paidAt: DateTime.now()) else x,
      ];
      tryAdd(
        DayPriority(
          id: 'pay-${p.id}',
          title: 'Régler ${p.creditor}',
          subtitle: '${p.amountFormatted} · ${p.label}',
          kind: DayPriorityKind.payment,
          route: '/payments/${p.id}',
          tag: 'Paiement',
        ),
        nextPayments: nextPayments,
      );
    }

    final paidPaymentIds = {
      for (final p in paymentsState)
        if (p.status == PaymentStatus.paid) p.id,
    };
    // Courriers déjà réglés via le paiement lié : exclus du briefing.
    final unprocessed = emailsState
        .where((e) =>
            !e.isProcessed &&
            (e.paymentId == null || !paidPaymentIds.contains(e.paymentId)))
        .toList()
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    for (final e in unprocessed) {
      final nextEmails = [
        for (final x in emailsState)
          if (x.id == e.id) x.copyWith(isProcessed: true, isRead: true) else x,
      ];
      tryAdd(
        DayPriority(
          id: 'mail-${e.id}',
          title: e.subject,
          subtitle: '${e.sender} · à valider',
          kind: DayPriorityKind.messaging,
          route: '/messaging/${e.id}',
          tag: 'Courrier',
        ),
        nextEmails: nextEmails,
      );
    }

    return (priorities: out, projectedScore: runningScore);
  }
}
