import 'package:confidia/features/day_start/day_briefing_model.dart';
import 'package:confidia/features/day_start/day_briefing_service.dart';
import 'package:confidia/shared/data/mock_ecosystem.dart';
import 'package:confidia/shared/models/payment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DayBriefingService builds a coherent briefing from mock data', () {
    final briefing = DayBriefingService.build(
      firstName: 'Amandine',
      emails: MockEcosystem.emails,
      events: MockEcosystem.allCalendarEvents,
      payments: MockEcosystem.payments,
      notifications: MockEcosystem.notifications,
      documents: MockEcosystem.documents,
    );

    expect(briefing.narrative, isNotEmpty);
    expect(briefing.priorities, isNotEmpty);
    expect(briefing.priorities.length, greaterThanOrEqualTo(3));
    expect(briefing.currentScore, inInclusiveRange(0, 100));
    expect(briefing.glance.serenityScore, briefing.currentScore);
  });

  test('priority gains sum exactly to the displayed projection', () {
    final briefing = DayBriefingService.build(
      firstName: 'Jean',
      emails: MockEcosystem.emails,
      events: MockEcosystem.allCalendarEvents,
      payments: MockEcosystem.payments,
      notifications: MockEcosystem.notifications,
      documents: MockEcosystem.documents,
    );

    final gainsSum = briefing.priorities.fold<int>(0, (s, p) => s + p.serenityGain);
    expect(briefing.totalGain, gainsSum);
    expect(briefing.projectedScore, briefing.currentScore + gainsSum);
    expect(briefing.priorities.every((p) => p.serenityGain > 0), isTrue);
  });

  test('glance document count matches listed documents', () {
    final briefing = DayBriefingService.build(
      firstName: 'Jean',
      emails: MockEcosystem.emails,
      events: MockEcosystem.allCalendarEvents,
      payments: MockEcosystem.payments,
      notifications: MockEcosystem.notifications,
      documents: MockEcosystem.documents,
    );

    expect(briefing.glance.newDocuments, briefing.newDocuments.length);
    expect(briefing.glance.appointmentsToday, briefing.todaysAppointments.length);
  });

  test('urgent payment section excludes payments already in priorities', () {
    final briefing = DayBriefingService.build(
      firstName: 'Jean',
      emails: MockEcosystem.emails,
      events: MockEcosystem.allCalendarEvents,
      payments: MockEcosystem.payments,
      notifications: MockEcosystem.notifications,
      documents: MockEcosystem.documents,
    );

    final priorityPayIds = {
      for (final p in briefing.priorities)
        if (p.kind == DayPriorityKind.payment) p.id,
    };
    expect(
      briefing.urgentPayments.every((p) => !priorityPayIds.contains('pay-${p.id}')),
      isTrue,
    );
  });

  test('paid invoice leaves payment and linked mail priorities', () {
    final payments = [
      for (final p in MockEcosystem.payments)
        if (p.id == 'pay-edf')
          p.copyWith(status: PaymentStatus.paid, paidAt: DateTime.now())
        else
          p,
    ];

    final briefing = DayBriefingService.build(
      firstName: 'Jean',
      emails: MockEcosystem.emails,
      events: MockEcosystem.allCalendarEvents,
      payments: payments,
      notifications: MockEcosystem.notifications,
      documents: MockEcosystem.documents,
    );

    expect(
      briefing.priorities.any((p) => p.id.contains('edf') || p.title.toLowerCase().contains('edf') || p.title.toLowerCase().contains('électricité')),
      isFalse,
    );
    expect(briefing.urgentPayments.any((p) => p.id == 'pay-edf'), isFalse);
  });

  test('valueMessage never claims browsing documents raises serenity', () {
    final briefing = DayBriefingService.build(
      firstName: 'Jean',
      emails: MockEcosystem.emails,
      events: MockEcosystem.allCalendarEvents,
      payments: MockEcosystem.payments,
      notifications: MockEcosystem.notifications,
      documents: MockEcosystem.documents,
    );

    final msg = briefing.valueMessage ?? '';
    expect(msg.toLowerCase().contains('parcourir'), isFalse);
    if (briefing.totalGain > 0 && msg.isNotEmpty) {
      expect(
        msg.contains('échéance') || msg.contains('priorités') || msg.contains('pts'),
        isTrue,
      );
    }
  });
}
