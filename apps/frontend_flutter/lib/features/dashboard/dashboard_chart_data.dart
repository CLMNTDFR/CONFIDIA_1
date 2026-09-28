import '../../shared/models/document_model.dart';
import '../../shared/models/email_model.dart';
import '../../shared/models/payment_model.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/palette.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChartSlice {
  final String label;
  final double value;
  final Color color;

  const ChartSlice({required this.label, required this.value, required this.color});
}

class MonthlyPoint {
  final String label;
  final double value;

  const MonthlyPoint({required this.label, required this.value});
}

class HubActivityMonth {
  final String label;
  final int documents;
  final int emails;
  final int payments;

  const HubActivityMonth({
    required this.label,
    required this.documents,
    required this.emails,
    required this.payments,
  });
}

/// Aggregated data for dashboard charts.
abstract final class DashboardChartData {
  /// Monthly spending over 6 months (invoices + hub payments).
  static List<MonthlyPoint> expenseTrend({
    List<PaymentModel> payments = const [],
    bool seedDemo = false,
  }) {
    final now = DateTime.now();
    final base = seedDemo
        ? <double>[312, 428, 385, 496, 452, 0]
        : List<double>.filled(6, 0);

    for (final payment in payments) {
      final monthIndex = _monthsAgo(now, payment.dueDate);
      if (monthIndex >= 0 && monthIndex < 6) {
        base[monthIndex] += payment.amount;
      }
    }

    return List.generate(6, (i) {
      final date = DateTime(now.year, now.month - (5 - i), 1);
      return MonthlyPoint(
        label: DateFormat('MMM', 'fr_FR').format(date),
        value: base[i],
      );
    });
  }

  /// Document breakdown by category.
  static List<ChartSlice> documentsByCategory(List<DocumentModel> docs, ConfidiaPalette palette) {
    final counts = <String, int>{};
    for (final doc in docs) {
      final key = doc.category ?? 'Autre';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final chartColors = palette.chartColors;
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return List.generate(entries.length, (i) {
      final entry = entries[i];
      return ChartSlice(
        label: entry.key,
        value: entry.value.toDouble(),
        color: chartColors[i % chartColors.length],
      );
    });
  }

  /// Monthly hub activity (documents, mail, payments).
  static List<HubActivityMonth> hubActivity({
    List<DocumentModel> documents = const [],
    List<EmailModel> emails = const [],
    List<PaymentModel> payments = const [],
    bool seedDemo = false,
  }) {
    final now = DateTime.now();

    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - (5 - i), 1);
      final nextMonth = DateTime(month.year, month.month + 1, 1);

      int docCount = documents.where((d) => !d.created.isBefore(month) && d.created.isBefore(nextMonth)).length;
      int mailCount = emails.where((e) => !e.receivedAt.isBefore(month) && e.receivedAt.isBefore(nextMonth)).length;
      int payCount = payments.where((p) {
        final ref = p.paidAt ?? p.dueDate;
        return !ref.isBefore(month) && ref.isBefore(nextMonth);
      }).length;

      if (seedDemo && i < 5) {
        docCount += [1, 0, 2, 1, 1][i];
        mailCount += [2, 1, 3, 2, 2][i];
        payCount += [1, 2, 1, 2, 1][i];
      }

      return HubActivityMonth(
        label: DateFormat('MMM', 'fr_FR').format(month),
        documents: docCount,
        emails: mailCount,
        payments: payCount,
      );
    });
  }

  /// Amounts by payment status.
  static List<ChartSlice> paymentsByStatus(List<PaymentModel> payments, ConfidiaPalette palette) {
    final totals = <PaymentStatus, double>{};
    for (final payment in payments) {
      totals[payment.status] = (totals[payment.status] ?? 0) + payment.amount;
    }

    Color colorFor(PaymentStatus status) => switch (status) {
          PaymentStatus.pending => palette.primary,
          PaymentStatus.waiting => palette.secondary,
          PaymentStatus.paid => ConfidiaColors.success,
          PaymentStatus.expired => ConfidiaColors.error,
        };

    String labelFor(PaymentStatus status) => switch (status) {
          PaymentStatus.pending => 'À payer',
          PaymentStatus.waiting => 'En attente',
          PaymentStatus.paid => 'Réglés',
          PaymentStatus.expired => 'Expirés',
        };

    return PaymentStatus.values
        .where((s) => (totals[s] ?? 0) > 0)
        .map((s) => ChartSlice(label: labelFor(s), value: totals[s]!, color: colorFor(s)))
        .toList();
  }

  static int _monthsAgo(DateTime now, DateTime date) => (now.year - date.year) * 12 + now.month - date.month;
}
