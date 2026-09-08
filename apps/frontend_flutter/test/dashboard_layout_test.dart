import 'package:confidia/features/dashboard/dashboard_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DashboardLayoutNotifier notifier;

  setUp(() {
    notifier = DashboardLayoutNotifier();
  });

  test('default layout hides greeting and redundant widgets', () {
    expect(notifier.state.visible, isNotEmpty);
    expect(notifier.state.visible, isNot(contains(DashboardWidgetType.greeting)));
    expect(notifier.state.editMode, isFalse);
    expect(notifier.state.hidden, equals(kDefaultHiddenDashboardWidgets));
    expect(notifier.state.visible, isNot(contains(DashboardWidgetType.quickActions)));
    expect(notifier.state.visible, isNot(contains(DashboardWidgetType.stats)));
    expect(notifier.state.visible, isNot(contains(DashboardWidgetType.activity)));
    expect(notifier.state.visible, isNot(contains(DashboardWidgetType.aiAnalyzed)));
    expect(notifier.state.visible, isNot(contains(DashboardWidgetType.importantDocs)));
    expect(notifier.state.visible.first, DashboardWidgetType.serenityBriefing);
  });

  test('toggleWidget hides and restores a block', () {
    final target = DashboardWidgetType.weekOverview;
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

  test('reset restores default order and default hidden', () {
    notifier.toggleWidget(DashboardWidgetType.weekOverview);
    notifier.moveVisible(0, 2);
    notifier.reset();

    expect(notifier.state.hidden, equals(kDefaultHiddenDashboardWidgets));
    expect(notifier.state.editMode, isFalse);
    expect(notifier.state.order, equals(kDefaultDashboardOrder));
    expect(notifier.state.visible.first, DashboardWidgetType.serenityBriefing);
  });

  test('out-of-MVP widgets stay visible with demo flag', () {
    expect(
      notifier.state.visible,
      containsAll([
        DashboardWidgetType.expensesTrend,
        DashboardWidgetType.paymentsOverview,
        DashboardWidgetType.hubActivity,
        DashboardWidgetType.pendingPayments,
        DashboardWidgetType.connectedAccounts,
      ]),
    );
    expect(DashboardWidgetType.expensesTrend.isDemo, isTrue);
    expect(DashboardWidgetType.paymentsOverview.isDemo, isTrue);
    expect(DashboardWidgetType.hubActivity.isDemo, isTrue);
    expect(DashboardWidgetType.pendingPayments.isDemo, isTrue);
    expect(DashboardWidgetType.connectedAccounts.isDemo, isTrue);
  });

  test('serenityBriefing label is Indice de sérénité', () {
    expect(DashboardWidgetType.serenityBriefing.label, 'Indice de sérénité');
  });

  test('half-width flags stay stable for grid pairing', () {
    expect(DashboardWidgetType.recentDocs.isHalfWidth, isTrue);
    expect(DashboardWidgetType.serenityBriefing.isHalfWidth, isFalse);
  });
}
