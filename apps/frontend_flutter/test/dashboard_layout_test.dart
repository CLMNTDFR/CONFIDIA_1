import 'package:confidia/features/dashboard/dashboard_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DashboardLayoutNotifier notifier;

  setUp(() {
    notifier = DashboardLayoutNotifier();
  });

  test('default layout hides greeting and exposes visible widgets', () {
    expect(notifier.state.visible, isNotEmpty);
    expect(notifier.state.visible, isNot(contains(DashboardWidgetType.greeting)));
    expect(notifier.state.editMode, isFalse);
  });

  test('toggleWidget hides and restores a block', () {
    final target = DashboardWidgetType.stats;
    expect(notifier.state.visible, contains(target));

    notifier.toggleWidget(target);
    expect(notifier.state.hidden, contains(target));
    expect(notifier.state.visible, isNot(contains(target)));

    notifier.toggleWidget(target);
    expect(notifier.state.hidden, isNot(contains(target)));
    expect(notifier.state.visible, contains(target));
  });

  test('moveVisible reorders without dropping widgets', () {
    final before = List<DashboardWidgetType>.from(notifier.state.visible);
    expect(before.length, greaterThan(1));

    notifier.moveVisible(0, 1);
    final after = notifier.state.visible;

    expect(after.length, before.length);
    expect(after[0], before[1]);
    expect(after[1], before[0]);
    expect(after.toSet(), before.toSet());
  });

  test('reset restores default order and clears hidden', () {
    notifier.toggleWidget(DashboardWidgetType.activity);
    notifier.moveVisible(0, 2);
    notifier.reset();

    expect(notifier.state.hidden, isEmpty);
    expect(notifier.state.editMode, isFalse);
    expect(notifier.state.visible.first, DashboardWidgetType.serenityBriefing);
  });

  test('half-width flags stay stable for grid pairing', () {
    expect(DashboardWidgetType.recentDocs.isHalfWidth, isTrue);
    expect(DashboardWidgetType.serenityBriefing.isHalfWidth, isFalse);
  });
}
