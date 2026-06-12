import 'package:confidia/core/theme/colors.dart';
import 'package:confidia/core/theme/palette.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum PaymentStatus { pending, waiting, paid, expired }

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.pending => 'À traiter',
        PaymentStatus.waiting => 'En attente',
        PaymentStatus.paid => 'Payé',
        PaymentStatus.expired => 'Expiré',
      };

  Color themeColor(ConfidiaPalette palette) => switch (this) {
        PaymentStatus.pending => palette.primary,
        PaymentStatus.waiting => ConfidiaColors.warning,
        PaymentStatus.paid => ConfidiaColors.success,
        PaymentStatus.expired => ConfidiaColors.textSecondary(true),
      };
}

class PaymentModel extends Equatable {
  final String id;
  final String label;
  final String creditor;
  final double amount;
  final PaymentStatus status;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? reference;
  final int? documentId;
  final String? emailId;
  final String? eventId;
  final IconData icon;

  const PaymentModel({
    required this.id,
    required this.label,
    required this.creditor,
    required this.amount,
    required this.status,
    required this.dueDate,
    this.paidAt,
    this.reference,
    this.documentId,
    this.emailId,
    this.eventId,
    this.icon = Icons.receipt_long_rounded,
  });

  String get amountFormatted => '${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2)} €';

  PaymentModel copyWith({PaymentStatus? status, DateTime? paidAt}) => PaymentModel(
        id: id,
        label: label,
        creditor: creditor,
        amount: amount,
        status: status ?? this.status,
        dueDate: dueDate,
        paidAt: paidAt ?? this.paidAt,
        reference: reference,
        documentId: documentId,
        emailId: emailId,
        eventId: eventId,
        icon: icon,
      );

  @override
  List<Object?> get props => [id, status, amount];
}
