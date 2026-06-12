import 'package:confidia/core/theme/colors.dart';
import 'package:confidia/core/theme/palette.dart';
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

  Color themeColor(ConfidiaPalette palette) => switch (this) {
        AiPriority.low => ConfidiaColors.textSecondary(true),
        AiPriority.medium => palette.accent,
        AiPriority.high => ConfidiaColors.warning,
        AiPriority.urgent => palette.primary,
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
