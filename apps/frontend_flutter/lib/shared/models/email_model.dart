import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum MailProvider {
  gmail,
  outlook,
  yahoo,
  apple,
  proton,
  imap,
}

extension MailProviderX on MailProvider {
  String get label => switch (this) {
        MailProvider.gmail => 'Gmail',
        MailProvider.outlook => 'Outlook',
        MailProvider.yahoo => 'Yahoo Mail',
        MailProvider.apple => 'Apple Mail',
        MailProvider.proton => 'Proton Mail',
        MailProvider.imap => 'IMAP Pro',
      };

  Color get brandColor => switch (this) {
        MailProvider.gmail => const Color(0xFFEA4335),
        MailProvider.outlook => const Color(0xFF0078D4),
        MailProvider.yahoo => const Color(0xFF6001D2),
        MailProvider.apple => const Color(0xFF555555),
        MailProvider.proton => const Color(0xFF6D4AFF),
        MailProvider.imap => const Color(0xFF4B96B4),
      };

  IconData get icon => switch (this) {
        MailProvider.gmail => Icons.mail_rounded,
        MailProvider.outlook => Icons.mail_outline_rounded,
        MailProvider.yahoo => Icons.alternate_email_rounded,
        MailProvider.apple => Icons.apple_rounded,
        MailProvider.proton => Icons.shield_rounded,
        MailProvider.imap => Icons.business_rounded,
      };
}

class EmailModel extends Equatable {
  final String id;
  final String accountEmail;
  final MailProvider provider;
  final String sender;
  final String subject;
  final String preview;
  final String body;
  final DateTime receivedAt;
  final bool isRead;
  final bool isStarred;
  final bool isProcessed;
  final int? documentId;
  final String? paymentId;
  final String? eventId;

  const EmailModel({
    required this.id,
    required this.accountEmail,
    required this.provider,
    required this.sender,
    required this.subject,
    required this.preview,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
    this.isStarred = false,
    this.isProcessed = false,
    this.documentId,
    this.paymentId,
    this.eventId,
  });

  EmailModel copyWith({bool? isRead, bool? isProcessed, bool? isStarred}) => EmailModel(
        id: id,
        accountEmail: accountEmail,
        provider: provider,
        sender: sender,
        subject: subject,
        preview: preview,
        body: body,
        receivedAt: receivedAt,
        isRead: isRead ?? this.isRead,
        isStarred: isStarred ?? this.isStarred,
        isProcessed: isProcessed ?? this.isProcessed,
        documentId: documentId,
        paymentId: paymentId,
        eventId: eventId,
      );

  @override
  List<Object?> get props => [id, isRead, isProcessed];
}
