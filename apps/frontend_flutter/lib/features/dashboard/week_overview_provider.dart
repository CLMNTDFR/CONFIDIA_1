import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../shared/data/mock_week_overview_events.dart';
import '../../shared/models/week_overview_model.dart';
import '../../shared/services/week_overview_service.dart';
import '../calendar/calendar_provider.dart';

final weekOverviewScopesProvider = StateProvider<Set<WeekCalendarScope>>(
  (ref) => WeekCalendarScope.values.toSet(),
);

final weekOverviewProvider = Provider<WeekOverview>((ref) {
  final scopes = ref.watch(weekOverviewScopesProvider);
  final demo = ref.watch(authStateProvider).isDemoSession;
  return WeekOverviewService.compute(
    events: demo ? MockWeekOverviewEvents.events : ref.watch(calendarProvider).items,
    scopes: scopes,
  );
});
