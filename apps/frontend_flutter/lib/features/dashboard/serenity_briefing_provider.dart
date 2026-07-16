import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../shared/data/mock_ecosystem.dart';
import '../../shared/models/serenity_briefing_model.dart';
import '../../shared/services/serenity_service.dart';
import '../messaging/messaging_provider.dart';
import '../payments/payments_provider.dart';
import '../calendar/calendar_provider.dart';

/// Briefing calculé depuis les providers locaux (source UI principale).
final serenityBriefingProvider = Provider<SerenityBriefing>((ref) {
  final user = ref.watch(authStateProvider).user;
  final firstName = user?.firstName ?? 'Amandine';

  return SerenityService.build(
    firstName: firstName,
    emails: ref.watch(messagingProvider),
    events: ref.watch(calendarProvider),
    payments: ref.watch(paymentsProvider),
    notifications: MockEcosystem.notifications,
    documents: MockEcosystem.documents,
  );
});
