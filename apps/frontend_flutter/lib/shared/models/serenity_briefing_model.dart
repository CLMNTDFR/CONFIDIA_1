import 'package:equatable/equatable.dart';

enum SerenityDomain {
  messaging,
  calendar,
  payments,
  documents,
  notifications,
}

extension SerenityDomainX on SerenityDomain {
  String get apiValue => switch (this) {
        SerenityDomain.messaging => 'messaging',
        SerenityDomain.calendar => 'calendar',
        SerenityDomain.payments => 'payments',
        SerenityDomain.documents => 'documents',
        SerenityDomain.notifications => 'notifications',
      };

  static SerenityDomain fromApi(String value) => SerenityDomain.values.firstWhere(
        (d) => d.apiValue == value,
        orElse: () => SerenityDomain.notifications,
      );
}

enum SerenityLevel {
  excellent,
  good,
  moderate,
  attention,
}

extension SerenityLevelX on SerenityLevel {
  String get apiValue => name;

  String get label => switch (this) {
        SerenityLevel.excellent => 'Excellente',
        SerenityLevel.good => 'Bonne',
        SerenityLevel.moderate => 'Modérée',
        SerenityLevel.attention => 'À surveiller',
      };

  static SerenityLevel fromApi(String value) => SerenityLevel.values.firstWhere(
        (l) => l.apiValue == value,
        orElse: () => SerenityLevel.moderate,
      );
}

class SerenityMetric extends Equatable {
  final String key;
  final String label;
  final int value;
  final String? unit;
  final SerenityDomain domain;

  const SerenityMetric({
    required this.key,
    required this.label,
    required this.value,
    this.unit,
    required this.domain,
  });

  factory SerenityMetric.fromJson(Map<String, dynamic> json) => SerenityMetric(
        key: json['key'] as String,
        label: json['label'] as String,
        value: json['value'] as int,
        unit: json['unit'] as String?,
        domain: SerenityDomainX.fromApi(json['domain'] as String),
      );

  @override
  List<Object?> get props => [key, value, domain];
}

class SerenityFactor extends Equatable {
  final SerenityDomain domain;
  final String label;
  final String detail;
  final int impact;
  final String severity;

  const SerenityFactor({
    required this.domain,
    required this.label,
    required this.detail,
    required this.impact,
    required this.severity,
  });

  factory SerenityFactor.fromJson(Map<String, dynamic> json) => SerenityFactor(
        domain: SerenityDomainX.fromApi(json['domain'] as String),
        label: json['label'] as String,
        detail: json['detail'] as String,
        impact: json['impact'] as int,
        severity: json['severity'] as String,
      );

  @override
  List<Object?> get props => [domain, label, impact];
}

class SerenityScorePoint extends Equatable {
  final DateTime date;
  final int score;

  const SerenityScorePoint({required this.date, required this.score});

  factory SerenityScorePoint.fromJson(Map<String, dynamic> json) => SerenityScorePoint(
        date: DateTime.parse(json['date'] as String),
        score: json['score'] as int,
      );

  @override
  List<Object?> get props => [date, score];
}

class SerenityAction extends Equatable {
  final String id;
  final String label;
  final String description;
  final String route;
  final String icon;
  final bool aiPowered;
  final int priority;

  const SerenityAction({
    required this.id,
    required this.label,
    required this.description,
    required this.route,
    required this.icon,
    this.aiPowered = false,
    this.priority = 0,
  });

  factory SerenityAction.fromJson(Map<String, dynamic> json) => SerenityAction(
        id: json['id'] as String,
        label: json['label'] as String,
        description: json['description'] as String,
        route: json['route'] as String,
        icon: json['icon'] as String,
        aiPowered: json['ai_powered'] as bool? ?? false,
        priority: json['priority'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [id, route, priority];
}

class SerenityBriefing extends Equatable {
  final int score;
  final SerenityLevel level;
  final String greeting;
  final String headline;
  final String summary;
  final List<SerenityMetric> metrics;
  final List<SerenityFactor> factors;
  final List<SerenityAction> actions;
  final List<SerenityScorePoint> scoreHistory;
  final DateTime generatedAt;

  const SerenityBriefing({
    required this.score,
    required this.level,
    required this.greeting,
    required this.headline,
    required this.summary,
    required this.metrics,
    required this.factors,
    required this.actions,
    required this.scoreHistory,
    required this.generatedAt,
  });

  factory SerenityBriefing.fromJson(Map<String, dynamic> json) => SerenityBriefing(
        score: json['score'] as int,
        level: SerenityLevelX.fromApi(json['level'] as String),
        greeting: json['greeting'] as String,
        headline: json['headline'] as String,
        summary: json['summary'] as String,
        metrics: (json['metrics'] as List).map((e) => SerenityMetric.fromJson(e as Map<String, dynamic>)).toList(),
        factors: (json['factors'] as List).map((e) => SerenityFactor.fromJson(e as Map<String, dynamic>)).toList(),
        actions: (json['actions'] as List).map((e) => SerenityAction.fromJson(e as Map<String, dynamic>)).toList(),
        scoreHistory: (json['score_history'] as List)
            .map((e) => SerenityScorePoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        generatedAt: DateTime.parse(json['generated_at'] as String),
      );

  @override
  List<Object?> get props => [score, level, headline, generatedAt, scoreHistory];
}
