import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/mock_week_overview_events.dart';
import '../../shared/models/week_overview_model.dart';
import '../../shared/services/week_overview_service.dart';

final weekOverviewScopesProvider = StateProvider<Set<WeekCalendarScope>>(
  (ref) => WeekCalendarScope.values.toSet(),
);

final weekOverviewProvider = Provider<WeekOverview>((ref) {
  final scopes = ref.watch(weekOverviewScopesProvider);

  return WeekOverviewService.compute(
    events: MockWeekOverviewEvents.events,
    scopes: scopes,
  );
});
