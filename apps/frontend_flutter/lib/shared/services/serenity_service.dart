import '../../shared/models/calendar_event_model.dart';
import '../../shared/models/document_model.dart';
import '../../shared/models/email_model.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/models/serenity_briefing_model.dart';
import '../utils/serenity_palette.dart';

/// Calcule le briefing de sérénité depuis les données locales (mock / providers).
abstract final class SerenityService {
  static SerenityBriefing build({
    required String firstName,
    required List<EmailModel> emails,
    required List<CalendarEventModel> events,
    required List<PaymentModel> payments,
    required List<NotificationModel> notifications,
    required List<DocumentModel> documents,
  }) {
    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 30));

    final unprocessedEmails = emails.where((e) => !e.isProcessed).length;
    final pendingPayments = payments
        .where((p) => p.status == PaymentStatus.pending || p.status == PaymentStatus.waiting)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final unreadNotifications = notifications.where((n) => !n.read).length;
    final importantDocs = documents.where((d) => d.isImportant).length;

    final upcomingEvents = events.where((e) => e.start.isAfter(now) && e.start.isBefore(horizon)).toList();
    final busyDays = _countBusyDays(upcomingEvents);
    final deadlines7d = upcomingEvents
        .where((e) => e.eventType == EventType.deadline && e.start.isBefore(now.add(const Duration(days: 7))))
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
          (p) => p!.dueDate.isBefore(now.add(const Duration(days: 8))),
          orElse: () => null,
        );
    if (soonPayment != null) {
      final days = soonPayment.dueDate.difference(now).inDays.clamp(0, 30);
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

    final headline = SerenityPalette.serenityHeadline(level, score, priorityToday);

    final summaryParts = <String>[
      '$firstName, votre indice de sérénité est $score/100 (${level.label.toLowerCase()}).',
      'Votre $calendarLabel sur les 30 prochains jours.',
    ];
    if (soonPayment != null) {
      final days = soonPayment.dueDate.difference(now).inDays.clamp(0, 30);
      summaryParts.add('Une facture ${soonPayment.creditor} arrive à échéance dans $days jour(s).');
    }
    if (priorityToday > 0) {
      summaryParts.add('$priorityToday courrier(s) mérite(nt) votre attention aujourd\'hui.');
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
      greeting: 'Bonjour $firstName.',
      headline: headline,
      summary: summaryParts.join(' '),
      metrics: metrics,
      factors: factors..sort((a, b) => b.impact.compareTo(a.impact)),
      actions: _buildActions(factors),
      scoreHistory: _buildScoreHistory(score, now),
      generatedAt: now,
    );
  }

  /// Historique mock : forte amplitude, récupération progressive vers le score actuel.
  static List<SerenityScorePoint> _buildScoreHistory(int currentScore, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
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
    if (score >= 65) return SerenityLevel.good;
    if (score >= 50) return SerenityLevel.moderate;
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
