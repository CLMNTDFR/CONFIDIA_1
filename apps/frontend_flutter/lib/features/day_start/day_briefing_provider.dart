import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/workspace_session.dart';
import '../calendar/calendar_provider.dart';
import '../documents/documents_provider.dart';
import '../messaging/messaging_provider.dart';
import '../notifications/notifications_provider.dart';
import '../payments/payments_provider.dart';
import 'day_briefing_model.dart';
import 'day_briefing_service.dart';

/// Briefing du jour recalculé depuis les providers du compte courant.
final dayBriefingProvider = Provider<DayBriefing>((ref) {
  return DayBriefingService.build(
    firstName: sessionFirstName(ref.watch(authStateProvider)),
    emails: ref.watch(messagingProvider),
    events: ref.watch(calendarProvider).items,
    payments: ref.watch(paymentsProvider),
    notifications: ref.watch(notificationsProvider),
    documents: ref.watch(documentsProvider).items,
  );
});
