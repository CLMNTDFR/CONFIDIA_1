import 'package:confidia/features/onboarding/guided_tour_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tour steps are a stable ordered sequence', () {
    expect(guidedTourSteps, isNotEmpty);
    expect(guidedTourSteps.first.id, GuidedTourStepId.welcome);
    expect(guidedTourSteps.last.id, GuidedTourStepId.homeReturn);
    expect(
      guidedTourSteps.map((s) => s.id).toSet().length,
      guidedTourSteps.length,
    );
  });

  test('theme browser gates next until all combos are seen', () {
    final appearanceIndex = guidedTourSteps.indexWhere((s) => s.isThemeBrowser);
    expect(appearanceIndex, greaterThanOrEqualTo(0));

    var state = GuidedTourState(active: true, stepIndex: appearanceIndex);
    expect(state.canProceedFromCurrentStep(), isFalse);

    state = state.copyWith(themesSeenMask: (1 << guidedTourThemeCombos.length) - 1);
    expect(state.allThemesSeen, isTrue);
    expect(state.canProceedFromCurrentStep(), isTrue);
  });

  test('non-theme steps always allow proceed when active', () {
    final state = GuidedTourState(active: true, stepIndex: 0);
    expect(state.currentStep?.id, GuidedTourStepId.welcome);
    expect(state.canProceedFromCurrentStep(), isTrue);
  });

  test('notifier advances and completes the tour', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(guidedTourProvider.notifier);
    notifier.arm();
    expect(container.read(guidedTourProvider).armed, isTrue);

    notifier.startIfArmed();
    expect(container.read(guidedTourProvider).active, isTrue);
    expect(container.read(guidedTourProvider).stepIndex, 0);

    notifier.next();
    expect(container.read(guidedTourProvider).stepIndex, 1);

    notifier.skip();
    expect(container.read(guidedTourProvider).active, isFalse);
  });
}
