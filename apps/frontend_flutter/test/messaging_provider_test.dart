import 'package:confidia/features/messaging/messaging_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unreadCount provider tracks markRead', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initialUnread = container.read(messagingUnreadCountProvider);
    expect(initialUnread, greaterThan(0));

    final unreadId = container.read(messagingProvider).firstWhere((e) => !e.isRead).id;
    container.read(messagingProvider.notifier).markRead(unreadId);

    expect(container.read(messagingUnreadCountProvider), initialUnread - 1);
  });

  test('toggleStar flips starred flag', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final email = container.read(messagingProvider).first;
    final before = email.isStarred;
    container.read(messagingProvider.notifier).toggleStar(email.id);
    expect(container.read(messagingProvider.notifier).byId(email.id)!.isStarred, !before);
  });
}
