import 'package:equatable/equatable.dart';

enum SerenityMomentKind { pointsGained, beforeAfter, valueSaved, congratulations }

class SerenityMoment extends Equatable {
  final SerenityMomentKind kind;
  final String title;
  final String body;
  final int? delta;
  final int? scoreBefore;
  final int? scoreAfter;

  const SerenityMoment({
    required this.kind,
    required this.title,
    required this.body,
    this.delta,
    this.scoreBefore,
    this.scoreAfter,
  });

  bool get useOverlay =>
      kind == SerenityMomentKind.congratulations || kind == SerenityMomentKind.beforeAfter;

  @override
  List<Object?> get props => [kind, title, body, delta, scoreBefore, scoreAfter];
}
