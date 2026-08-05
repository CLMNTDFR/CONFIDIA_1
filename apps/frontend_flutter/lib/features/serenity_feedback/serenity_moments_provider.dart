import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding/guided_tour_provider.dart';
import 'serenity_moment.dart';

class SerenityMomentsState {
  final List<SerenityMoment> queue;
  final DateTime? congratulationsDay;

  const SerenityMomentsState({
    this.queue = const [],
    this.congratulationsDay,
  });

  SerenityMoment? get current => queue.isEmpty ? null : queue.first;

  SerenityMomentsState copyWith({
    List<SerenityMoment>? queue,
    DateTime? congratulationsDay,
  }) {
    return SerenityMomentsState(
      queue: queue ?? this.queue,
      congratulationsDay: congratulationsDay ?? this.congratulationsDay,
    );
  }
}

class SerenityMomentsNotifier extends StateNotifier<SerenityMomentsState> {
  SerenityMomentsNotifier(this._ref) : super(const SerenityMomentsState());

  final Ref _ref;
  double? _pendingPenaltyAvoided;

  void enqueue(SerenityMoment moment) {
    if (_ref.read(guidedTourProvider).active) return;
    state = state.copyWith(queue: [...state.queue, moment]);
  }

  void dismissCurrent() {
    if (state.queue.isEmpty) return;
    state = state.copyWith(queue: state.queue.skip(1).toList());
  }

  /// Mémorise la pénalité évitée pour l'inclure dans le prochain moment de score.
  void notifyPaymentSuccess({required double penaltyAvoided}) {
    if (penaltyAvoided >= 1) {
      _pendingPenaltyAvoided = penaltyAvoided;
    }
  }

  /// Branché depuis AppShell via ref.listen(serenityBriefingProvider...).
  void onScoreChanged(int? previous, int next, String levelLabel) {
    if (previous == null) return;
    final delta = next - previous;
    if (delta <= 0) {
      _pendingPenaltyAvoided = null;
      return;
    }
    if (_ref.read(guidedTourProvider).active) return;

    final penalty = _pendingPenaltyAvoided;
    _pendingPenaltyAvoided = null;

    final now = DateTime.now();
    final alreadyToday = state.congratulationsDay != null &&
        state.congratulationsDay!.year == now.year &&
        state.congratulationsDay!.month == now.month &&
        state.congratulationsDay!.day == now.day;

    if (next >= 80 && !alreadyToday) {
      enqueue(SerenityMoment(
        kind: SerenityMomentKind.congratulations,
        title: 'Félicitations',
        body: _composeBody(
          previous: previous,
          next: next,
          levelLabel: levelLabel,
          penalty: penalty,
          congratulations: true,
        ),
        delta: delta,
        scoreAfter: next,
        scoreBefore: previous,
      ));
      state = state.copyWith(congratulationsDay: DateTime(now.year, now.month, now.day));
      return;
    }

    // Toujours l'overlay premium (avant, seuls les gains ≥ 5 pts l'ouvraient).
    enqueue(SerenityMoment(
      kind: SerenityMomentKind.beforeAfter,
      title: 'Sérénité en hausse',
      body: _composeBody(
        previous: previous,
        next: next,
        levelLabel: levelLabel,
        penalty: penalty,
      ),
      delta: delta,
      scoreBefore: previous,
      scoreAfter: next,
    ));
  }

  static String _composeBody({
    required int previous,
    required int next,
    required String levelLabel,
    double? penalty,
    bool congratulations = false,
  }) {
    final base = congratulations
        ? 'Votre indice est passé à $next. Niveau : $levelLabel.'
        : 'Indice $previous/100 → $next/100';
    if (penalty != null && penalty >= 1) {
      return '$base\nVous évitez environ ${penalty.toStringAsFixed(0)} € de pénalités.';
    }
    return base;
  }
}

final serenityMomentsProvider =
    StateNotifierProvider<SerenityMomentsNotifier, SerenityMomentsState>((ref) {
  return SerenityMomentsNotifier(ref);
});
