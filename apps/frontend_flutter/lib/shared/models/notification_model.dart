import 'package:equatable/equatable.dart';

enum NotificationType { info, warning, success, error, document, calendar, system }

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool read;
  final DateTime createdAt;
  final String? actionUrl;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.read = false,
    required this.createdAt,
    this.actionUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['notification_type'],
        orElse: () => NotificationType.info,
      ),
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      actionUrl: json['action_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, read];
}
