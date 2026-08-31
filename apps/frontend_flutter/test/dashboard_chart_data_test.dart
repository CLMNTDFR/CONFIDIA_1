import 'package:confidia/features/dashboard/dashboard_chart_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });
  test('live expense trend has no demo baseline', () {
    final points = DashboardChartData.expenseTrend(seedDemo: false);
    expect(points.length, 6);
    expect(points.every((p) => p.value == 0), isTrue);
  });

  test('live hub activity has no demo padding', () {
    final months = DashboardChartData.hubActivity(seedDemo: false);
    expect(months.length, 6);
    expect(
      months.every((m) => m.documents == 0 && m.emails == 0 && m.payments == 0),
      isTrue,
    );
  });
}
