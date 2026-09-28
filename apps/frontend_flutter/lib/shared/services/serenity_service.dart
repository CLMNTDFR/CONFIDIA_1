import '../../shared/models/calendar_event_model.dart';
import '../../shared/models/document_model.dart';
import '../../shared/models/email_model.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/models/serenity_briefing_model.dart';
import '../utils/serenity_palette.dart';

/// Builds the serenity briefing from local data (mock / providers).
abstract final class SerenityService {
  static SerenityBriefing build({
    required String firstName,
    required List<EmailModel> emails,
    required List<CalendarEventModel> events,
    required List<PaymentModel> payments,
    required List<NotificationModel> notifications,
    required List<DocumentModel> documents,
    DateTime? now,
    bool seedHistory = false,
  }) {
    final reference = now ?? DateTime.now();
    final horizon = reference.add(const Duration(days: 30));

    final unprocessedEmails = emails.where((e) => !e.isProcessed).length;
    final pendingPayments = payments
        .where((p) => p.status == PaymentStatus.pending || p.status == PaymentStatus.waiting)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final unreadNotifications = notifications.where((n) => !n.read).length;
    final importantDocs = documents.where((d) => d.isImportant).length;

    final upcomingEvents = events.where((e) => e.start.isAfter(reference) && e.start.isBefore(horizon)).toList();
    final busyDays = _countBusyDays(upcomingEvents);
    final deadlines7d = upcomingEvents
        .where((e) => e.eventType == EventType.deadline && e.start.isBefore(reference.add(const Duration(days: 7))))
        .length;

    final factors = <SerenityFactor>[];
    var score = 100;

    if (unprocessedEmails > 0) {
      final impact = (unprocessedEmails * 3).clamp(0, 18);
      score -= impact;
      factors.add(
        SerenityFactor(
          domain: SerenityDomain.messaging,
          label: 'Courriers non traités',
          detail: '$unprocessedEmails e-mail(s) en attente de traitement ou de classement',
          impact: impact,
          severity: unprocessedEmails >= 5 ? 'high' : 'medium',
        ),
      );
    }

    if (busyDays > 0) {
      final impact = (busyDays * 4).clamp(0, 16);
      score -= impact;
      factors.add(
        SerenityFactor(
          domain: SerenityDomain.calendar,
          label: 'Jours chargés à venir',
          detail: '$busyDays journée(s) dense(s) sur les 30 prochains jours',
          impact: impact,
          severity: busyDays >= 4 ? 'high' : 'medium',
        ),
      );
    }

    if (pendingPayments.isNotEmpty) {
      final impact = (pendingPayments.length * 3).clamp(0, 14);
      score -= impact;
      factors.add(
        SerenityFactor(
          domain: SerenityDomain.payments,
          label: 'Paiements en attente',
          detail: '${pendingPayments.length} facture(s) à régler',
          impact: impact,
          severity: 'medium',
        ),
      );
    }

    final soonPayment = pendingPayments.cast<PaymentModel?>().firstWhere(
          (p) => p!.dueDate.isBefore(reference.add(const Duration(days: 8))),
          orElse: () => null,
        );
    if (soonPayment != null) {
      final days = soonPayment.dueDate.difference(reference).inDays.clamp(0, 30);
      const impact = 4;
      score -= impact;
      factors.add(
        SerenityFactor(
          domain: SerenityDomain.payments,
          label: 'Échéance proche',
          detail: 'Facture ${soonPayment.creditor} dans $days jour(s)',
          impact: impact,
          severity: 'medium',
        ),
      );
    }

    if (deadlines7d > 0) {
      final impact = (deadlines7d * 3).clamp(0, 10);
      score -= impact;
      factors.add(
        SerenityFactor(
          domain: SerenityDomain.calendar,
          label: 'Échéances imminentes',
          detail: '$deadlines7d échéance(s) dans les 7 prochains jours',
          impact: impact,
          severity: deadlines7d >= 2 ? 'high' : 'medium',
        ),
      );
    }

    if (unreadNotifications > 0) {
      final impact = (unreadNotifications * 2).clamp(0, 6);
      score -= impact;
      factors.add(
        SerenityFactor(
          domain: SerenityDomain.notifications,
          label: 'Alertes non lues',
          detail: '$unreadNotifications notification(s) en attente',
          impact: impact,
          severity: 'low',
        ),
      );
    }

    if (importantDocs >= 4 && unprocessedEmails >= 3) {
      const impact = 3;
      score -= impact;
      factors.add(
        const SerenityFactor(
          domain: SerenityDomain.documents,
          label: 'Documents sensibles en attente',
          detail: 'Plusieurs pièces importantes nécessitent une relecture',
          impact: impact,
          severity: 'low',
        ),
      );
    }

    score = score.clamp(0, 100);
    final level = _resolveLevel(score);
    final calendarLabel = SerenityPalette.calendarLoadLabel(busyDays);
    final priorityToday = unprocessedEmails.clamp(0, 3);
    final displayName = firstName.trim();
    final greeting = displayName.isEmpty ? 'Bonjour.' : 'Bonjour $displayName.';

    final workspaceEmpty = unprocessedEmails == 0 &&
        pendingPayments.isEmpty &&
        unreadNotifications == 0 &&
        upcomingEvents.isEmpty &&
        documents.isEmpty &&
        importantDocs == 0;

    final headline = workspaceEmpty
        ? 'Votre espace est prêt ($score/100)'
        : SerenityPalette.serenityHeadline(level, score, priorityToday);

    final List<String> summaryParts;
    if (workspaceEmpty) {
      summaryParts = [
        if (displayName.isEmpty)
          'Votre espace est encore vide : aucun document, rendez-vous ni échéance.'
        else
          '$displayName, votre espace est encore vide : aucun document, rendez-vous ni échéance.',
        'Importez un fichier ou créez un événement pour que l\'indice suive votre quotidien.',
      ];
    } else {
      summaryParts = [
        if (displayName.isEmpty)
          'Votre indice de sérénité est $score/100 (${level.label.toLowerCase()}).'
        else
          '$displayName, votre indice de sérénité est $score/100 (${level.label.toLowerCase()}).',
        'Votre $calendarLabel sur les 30 prochains jours.',
      ];
      if (soonPayment != null) {
        final days = soonPayment.dueDate.difference(reference).inDays.clamp(0, 30);
        summaryParts.add('Une facture ${soonPayment.creditor} arrive à échéance dans $days jour(s).');
      }
      if (priorityToday > 0) {
        summaryParts.add('$priorityToday courrier(s) mérite(nt) votre attention aujourd\'hui.');
      }
    }

    final metrics = [
      SerenityMetric(
        key: 'unprocessed_emails',
        label: 'Courriers non traités',
        value: unprocessedEmails,
        domain: SerenityDomain.messaging,
      ),
      SerenityMetric(
        key: 'busy_days_30d',
        label: 'Jours chargés (30 j)',
        value: busyDays,
        domain: SerenityDomain.calendar,
      ),
      SerenityMetric(
        key: 'pending_payments',
        label: 'Paiements en attente',
        value: pendingPayments.length,
        domain: SerenityDomain.payments,
      ),
      SerenityMetric(
        key: 'unread_notifications',
        label: 'Alertes non lues',
        value: unreadNotifications,
        domain: SerenityDomain.notifications,
      ),
    ];

    return SerenityBriefing(
      score: score,
      level: level,
      greeting: greeting,
      headline: headline,
      summary: summaryParts.join(' '),
      metrics: metrics,
      factors: factors..sort((a, b) => b.impact.compareTo(a.impact)),
      actions: _buildActions(factors),
      scoreHistory: _buildScoreHistory(score, reference, seedHistory: seedHistory),
      generatedAt: reference,
    );
  }

  /// Projected score if some actionable debts were already handled.
  /// Reuses [build] (single scoring engine). Default: mail plus nearby deadlines (8 d).
  ///
  /// Example: 67 → 82 for the banner "Indice : 67 → 82 si vous traitez les échéances".
  static int projectAfterResolving({
    required String firstName,
    required List<EmailModel> emails,
    required List<CalendarEventModel> events,
    required List<PaymentModel> payments,
    required List<NotificationModel> notifications,
    required List<DocumentModel> documents,
    bool processEmails = true,
    bool settlePaymentsDueSoon = true,
    bool settlePendingPayments = false,
    bool clearUnreadNotifications = false,
    DateTime? now,
    bool seedHistory = false,
  }) {
    final reference = now ?? DateTime.now();
    final soonHorizon = reference.add(const Duration(days: 8));

    final projectedEmails = processEmails
        ? emails.map((e) => e.isProcessed ? e : e.copyWith(isProcessed: true, isRead: true)).toList()
        : emails;

    final projectedPayments = payments.map((p) {
      final actionable = p.status == PaymentStatus.pending || p.status == PaymentStatus.waiting;
      if (!actionable) return p;
      if (settlePendingPayments) {
        return p.copyWith(status: PaymentStatus.paid, paidAt: reference);
      }
      if (settlePaymentsDueSoon && p.dueDate.isBefore(soonHorizon)) {
        return p.copyWith(status: PaymentStatus.paid, paidAt: reference);
      }
      return p;
    }).toList();

    final projectedNotifications = clearUnreadNotifications
        ? notifications
            .map(
              (n) => NotificationModel(
                id: n.id,
                title: n.title,
                message: n.message,
                type: n.type,
                read: true,
                createdAt: n.createdAt,
                actionUrl: n.actionUrl,
              ),
            )
            .toList()
        : notifications;

    return build(
      firstName: firstName,
      emails: projectedEmails,
      events: events,
      payments: projectedPayments,
      notifications: projectedNotifications,
      documents: documents,
      now: reference,
      seedHistory: seedHistory,
    ).score;
  }

  /// Local heuristic for penalties avoided by paying [payment] on time.
  /// Feeds copy such as "Vous évitez X € de pénalités".
  ///
  /// Mock rule: 5% of the amount + €1 per day of delay already elapsed,
  /// floor €2, ceiling €100.
  static double estimatePenaltyAvoided(PaymentModel payment, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final overdueDays = reference.isAfter(payment.dueDate)
        ? reference.difference(payment.dueDate).inDays
        : 0;
    final estimate = payment.amount * 0.05 + overdueDays * 1.0;
    return double.parse(estimate.clamp(2.0, 100.0).toStringAsFixed(2));
  }

  /// History: in demo, a fictional 14-day curve. In a live session, only today's point.
  static List<SerenityScorePoint> _buildScoreHistory(
    int currentScore,
    DateTime now, {
    bool seedHistory = false,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    if (!seedHistory) {
      return [SerenityScorePoint(date: today, score: currentScore)];
    }
    const template = [34, 28, 31, 39, 36, 44, 41, 50, 47, 56, 53, 61, 58];
    final points = <SerenityScorePoint>[];

    for (var i = 0; i < template.length; i++) {
      points.add(SerenityScorePoint(date: today.subtract(Duration(days: template.length - i)), score: template[i]));
    }
    points.add(SerenityScorePoint(date: today, score: currentScore));
    return points;
  }

  static int _countBusyDays(List<CalendarEventModel> events) {
    final byDay = <DateTime, int>{};
    for (final event in events) {
      final day = DateTime(event.start.year, event.start.month, event.start.day);
      final weight = event.eventType == EventType.deadline || event.eventType == EventType.meeting ? 2 : 1;
      byDay[day] = (byDay[day] ?? 0) + weight;
    }
    return byDay.values.where((score) => score >= 4).length;
  }

  static SerenityLevel _resolveLevel(int score) {
    if (score >= 80) return SerenityLevel.excellent;
    if (score > 60) return SerenityLevel.good;
    if (score >= 41) return SerenityLevel.moderate;
    return SerenityLevel.attention;
  }

  static List<SerenityAction> _buildActions(List<SerenityFactor> factors) {
    final domains = factors.map((f) => f.domain).toSet();
    final actions = <SerenityAction>[];

    if (domains.contains(SerenityDomain.messaging)) {
      actions.add(
        const SerenityAction(
          id: 'triage-mails',
          label: 'Traiter les courriers',
          description: 'Cofid-IA classe et propose des actions sur vos e-mails en attente',
          route: '/messaging',
          icon: 'mail',
          aiPowered: true,
          priority: 90,
        ),
      );
    }
    if (domains.contains(SerenityDomain.calendar)) {
      actions.add(
        const SerenityAction(
          id: 'analyze-planning',
          label: 'Analyser le planning',
          description: 'Détecter les conflits et alléger les journées les plus denses',
          route: '/calendar',
          icon: 'calendar_month',
          aiPowered: true,
          priority: 80,
        ),
      );
      actions.add(
        const SerenityAction(
          id: 'conflict-resolution',
          label: 'Résoudre les conflits',
          description: 'Gouvernance : arbitrage des rôles et des disponibilités',
          route: '/access-control',
          icon: 'account_tree',
          aiPowered: true,
          priority: 70,
        ),
      );
    }
    if (domains.contains(SerenityDomain.payments)) {
      actions.add(
        const SerenityAction(
          id: 'settle-payments',
          label: 'Régler les factures',
          description: 'Visualiser et traiter les paiements en attente',
          route: '/payments',
          icon: 'payment',
          priority: 85,
        ),
      );
    }
    if (domains.contains(SerenityDomain.documents) || domains.contains(SerenityDomain.notifications)) {
      actions.add(
        const SerenityAction(
          id: 'review-documents',
          label: 'Consulter les documents',
          description: 'Retrouver les pièces liées à vos alertes',
          route: '/documents',
          icon: 'folder',
          priority: 60,
        ),
      );
    }

    actions.sort((a, b) => b.priority.compareTo(a.priority));
    return actions;
  }
}
