import 'package:confidia/features/serenity_feedback/serenity_moment.dart';
import 'package:confidia/features/serenity_feedback/serenity_moments_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('moments queue enqueue and dismiss', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(serenityMomentsProvider.notifier);
    notifier.enqueue(const SerenityMoment(
      kind: SerenityMomentKind.pointsGained,
      title: 'Gain',
      body: '+3 points de sérénité',
      delta: 3,
    ));

    expect(container.read(serenityMomentsProvider).current?.title, 'Gain');
    notifier.dismissCurrent();
    expect(container.read(serenityMomentsProvider).current, isNull);
  });

  test('notifyPaymentSuccess stores penalty for next score moment', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(serenityMomentsProvider.notifier);
    notifier.notifyPaymentSuccess(penaltyAvoided: 12);
    expect(container.read(serenityMomentsProvider).current, isNull);

    notifier.onScoreChanged(40, 43, 'Correct');
    final current = container.read(serenityMomentsProvider).current;
    expect(current?.kind, SerenityMomentKind.beforeAfter);
    expect(current?.useOverlay, isTrue);
    expect(current?.delta, 3);
    expect(current?.body, contains('12'));
  });

  test('any positive score delta opens premium overlay moment', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(serenityMomentsProvider.notifier).onScoreChanged(50, 52, 'Bon');
    final current = container.read(serenityMomentsProvider).current;
    expect(current?.kind, SerenityMomentKind.beforeAfter);
    expect(current?.useOverlay, isTrue);
    expect(current?.scoreBefore, 50);
    expect(current?.scoreAfter, 52);
  });
}
