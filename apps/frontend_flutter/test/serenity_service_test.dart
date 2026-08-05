import 'package:confidia/shared/models/calendar_event_model.dart';
import 'package:confidia/shared/models/document_model.dart';
import 'package:confidia/shared/models/email_model.dart';
import 'package:confidia/shared/models/notification_model.dart';
import 'package:confidia/shared/models/payment_model.dart';
import 'package:confidia/shared/services/serenity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 4, 10);

  EmailModel unprocessedMail(String id) => EmailModel(
        id: id,
        accountEmail: 'test@example.com',
        provider: MailProvider.gmail,
        sender: 'Sender',
        subject: 'Sujet $id',
        preview: 'Aperçu',
        body: 'Corps',
        receivedAt: now.subtract(const Duration(days: 1)),
        isProcessed: false,
      );

  PaymentModel pendingPayment({
    required String id,
    required double amount,
    required DateTime dueDate,
  }) =>
      PaymentModel(
        id: id,
        label: 'Facture $id',
        creditor: 'Créancier',
        amount: amount,
        status: PaymentStatus.pending,
        dueDate: dueDate,
        icon: Icons.receipt_long_rounded,
      );

  final mails = [
    unprocessedMail('m1'),
    unprocessedMail('m2'),
    unprocessedMail('m3'),
  ];

  final payments = [
    pendingPayment(id: 'p-soon', amount: 96, dueDate: now.add(const Duration(days: 3))),
    pendingPayment(id: 'p-later', amount: 42, dueDate: now.add(const Duration(days: 20))),
  ];

  final notifications = [
    NotificationModel(
      id: 'n1',
      title: 'Alerte',
      message: 'Message',
      createdAt: now,
    ),
  ];

  group('SerenityService.build', () {
    test('returns 100 when there is no actionable debt', () {
      final briefing = SerenityService.build(
        firstName: 'Amandine',
        emails: const [],
        events: const [],
        payments: const [],
        notifications: const [],
        documents: const [],
        now: now,
      );
      expect(briefing.score, 100);
      expect(briefing.factors, isEmpty);
    });

    test('penalizes unprocessed emails and pending payments', () {
      final briefing = SerenityService.build(
        firstName: 'Amandine',
        emails: mails,
        events: const <CalendarEventModel>[],
        payments: payments,
        notifications: notifications,
        documents: const <DocumentModel>[],
        now: now,
      );
      // 3 mails * 3 = 9, 2 pending * 3 = 6, soon +4, 1 notif * 2 = 2 => 79
      expect(briefing.score, 79);
      expect(briefing.greeting, contains('Amandine'));
    });
  });

  group('SerenityService.projectAfterResolving', () {
    test('default projection is at least the current score', () {
      final current = SerenityService.build(
        firstName: 'Amandine',
        emails: mails,
        events: const [],
        payments: payments,
        notifications: notifications,
        documents: const [],
        now: now,
      ).score;

      final projected = SerenityService.projectAfterResolving(
        firstName: 'Amandine',
        emails: mails,
        events: const [],
        payments: payments,
        notifications: notifications,
        documents: const [],
        now: now,
      );

      expect(projected, greaterThanOrEqualTo(current));
      expect(projected, inInclusiveRange(0, 100));
    });

    test('raises score when only emails are processed', () {
      final projected = SerenityService.projectAfterResolving(
        firstName: 'Amandine',
        emails: mails,
        events: const [],
        payments: payments,
        notifications: notifications,
        documents: const [],
        processEmails: true,
        settlePaymentsDueSoon: false,
        now: now,
      );
      // Without the 9-pt email impact: 79 + 9 = 88
      expect(projected, 88);
    });

    test('raises score when payments due soon are settled', () {
      final projected = SerenityService.projectAfterResolving(
        firstName: 'Amandine',
        emails: mails,
        events: const [],
        payments: payments,
        notifications: notifications,
        documents: const [],
        processEmails: false,
        settlePaymentsDueSoon: true,
        now: now,
      );
      // Clears soon (+4) and reduces pending 2->1 (+3) => 79 + 7 = 86
      expect(projected, 86);
    });

    test('combines email processing and settling all pending payments', () {
      final projected = SerenityService.projectAfterResolving(
        firstName: 'Amandine',
        emails: mails,
        events: const [],
        payments: payments,
        notifications: notifications,
        documents: const [],
        processEmails: true,
        settlePaymentsDueSoon: false,
        settlePendingPayments: true,
        now: now,
      );
      // Clears mails (+9), pending (+6), soon (+4) => 98 (notif remains -2)
      expect(projected, 98);
    });
  });

  group('SerenityService.estimatePenaltyAvoided', () {
    test('uses 5% of amount with a 2 euro floor when not overdue', () {
      final payment = pendingPayment(
        id: 'p1',
        amount: 96,
        dueDate: now.add(const Duration(days: 5)),
      );
      expect(SerenityService.estimatePenaltyAvoided(payment, now: now), 4.8);
    });

    test('adds 1 euro per overdue day', () {
      final payment = pendingPayment(
        id: 'p2',
        amount: 100,
        dueDate: now.subtract(const Duration(days: 3)),
      );
      expect(SerenityService.estimatePenaltyAvoided(payment, now: now), 8.0);
    });

    test('clamps small amounts to the 2 euro floor', () {
      final payment = pendingPayment(
        id: 'p3',
        amount: 10,
        dueDate: now.add(const Duration(days: 2)),
      );
      expect(SerenityService.estimatePenaltyAvoided(payment, now: now), 2.0);
    });

    test('clamps large estimates to 100 euro', () {
      final payment = pendingPayment(
        id: 'p4',
        amount: 5000,
        dueDate: now.subtract(const Duration(days: 40)),
      );
      expect(SerenityService.estimatePenaltyAvoided(payment, now: now), 100.0);
    });
  });
}
