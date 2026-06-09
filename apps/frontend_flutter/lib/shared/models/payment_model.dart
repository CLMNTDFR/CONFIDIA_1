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

  Color get color => switch (this) {
        PaymentStatus.pending => const Color(0xFFD20050),
        PaymentStatus.waiting => const Color(0xFFE8A838),
        PaymentStatus.paid => const Color(0xFF22C55E),
        PaymentStatus.expired => const Color(0xFF94A3B8),
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
