import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/workspace_session.dart';
import '../../shared/models/serenity_briefing_model.dart';
import '../../shared/services/serenity_service.dart';
import '../calendar/calendar_provider.dart';
import '../documents/documents_provider.dart';
import '../messaging/messaging_provider.dart';
import '../notifications/notifications_provider.dart';
import '../payments/payments_provider.dart';

/// Briefing computed from the current account providers (demo or live).
final serenityBriefingProvider = Provider<SerenityBriefing>((ref) {
  final auth = ref.watch(authStateProvider);
  return SerenityService.build(
    firstName: sessionFirstName(auth),
    emails: ref.watch(messagingProvider),
    events: ref.watch(calendarProvider).items,
    payments: ref.watch(paymentsProvider),
    notifications: ref.watch(notificationsProvider),
    documents: ref.watch(documentsProvider).items,
    seedHistory: auth.isDemoSession,
  );
});
