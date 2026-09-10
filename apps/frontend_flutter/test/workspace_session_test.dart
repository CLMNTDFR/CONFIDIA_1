import 'package:confidia/features/calendar/calendar_provider.dart';
import 'package:confidia/features/documents/documents_provider.dart';
import 'package:confidia/features/messaging/messaging_provider.dart';
import 'package:confidia/features/notifications/notifications_provider.dart';
import 'package:confidia/features/payments/payments_provider.dart';
import 'package:confidia/shared/data/mock_ecosystem.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/session_containers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('demo session keeps mock calendar, documents, payments, mail and alerts', () {
    final container = sessionContainer(demoAuthNotifier());
    addTearDown(container.dispose);

    expect(container.read(calendarProvider).items, isNotEmpty);
    expect(
      container.read(documentsProvider).items.length,
      MockEcosystem.documents.length,
    );
    expect(container.read(paymentsProvider), isNotEmpty);
    expect(container.read(messagingProvider), isNotEmpty);
    expect(container.read(notificationsProvider), isNotEmpty);
    expect(container.read(calendarProvider).items.length, MockEcosystem.allCalendarEvents.length);
  });

  test('live session starts with an empty workspace', () {
    final container = sessionContainer(liveAuthNotifier());
    addTearDown(container.dispose);

    expect(container.read(calendarProvider).items, isEmpty);
    expect(container.read(documentsProvider).items, isEmpty);
    expect(container.read(paymentsProvider), isEmpty);
    expect(container.read(messagingProvider), isEmpty);
    expect(container.read(notificationsProvider), isEmpty);
    expect(container.read(paymentsProvider.notifier).totalPending, 0);
    expect(container.read(notificationsUnreadCountProvider), 0);
  });
}
