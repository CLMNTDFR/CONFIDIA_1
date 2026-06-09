import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AiPriority { low, medium, high, urgent }

extension AiPriorityX on AiPriority {
  String get label => switch (this) {
        AiPriority.low => 'Faible',
        AiPriority.medium => 'Moyenne',
        AiPriority.high => 'Élevée',
        AiPriority.urgent => 'Urgente',
      };

  Color get color => switch (this) {
        AiPriority.low => const Color(0xFF94A3B8),
        AiPriority.medium => const Color(0xFF4B96B4),
        AiPriority.high => const Color(0xFFE8A838),
        AiPriority.urgent => const Color(0xFFD20050),
      };
}

class AiInsightModel extends Equatable {
  final String summary;
  final double? detectedAmount;
  final DateTime? detectedDeadline;
  final List<String> recommendedActions;
  final AiPriority priority;
  final List<String> tags;

  const AiInsightModel({
    required this.summary,
    this.detectedAmount,
    this.detectedDeadline,
    this.recommendedActions = const [],
    this.priority = AiPriority.medium,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [summary, detectedAmount, priority];
}
