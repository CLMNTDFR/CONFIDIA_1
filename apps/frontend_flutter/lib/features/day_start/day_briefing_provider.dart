import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../shared/data/mock_ecosystem.dart';
import '../calendar/calendar_provider.dart';
import '../messaging/messaging_provider.dart';
import '../payments/payments_provider.dart';
import 'day_briefing_model.dart';
import 'day_briefing_service.dart';

/// Briefing du jour recalculé depuis les providers live (dashboard + rituel).
final dayBriefingProvider = Provider<DayBriefing>((ref) {
  final user = ref.watch(authStateProvider).user;
  return DayBriefingService.build(
    firstName: user?.firstName ?? 'Amandine',
    emails: ref.watch(messagingProvider),
    events: ref.watch(calendarProvider),
    payments: ref.watch(paymentsProvider),
    notifications: MockEcosystem.notifications,
    documents: MockEcosystem.documents,
  );
});
