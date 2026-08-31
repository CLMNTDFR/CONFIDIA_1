import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/workspace_session.dart';
import '../../shared/data/mock_ecosystem.dart';
import '../../shared/models/notification_model.dart';

class NotificationsNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationsNotifier(this._ref)
      : super(demoSeedOrEmpty(_ref.read(authStateProvider), MockEcosystem.notifications)) {
    _ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (!workspaceSessionChanged(prev, next)) return;
      state = demoSeedOrEmpty(next, MockEcosystem.notifications);
    });
  }

  final Ref _ref;

  int get unreadCount => state.where((n) => !n.read).length;

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id)
          NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            read: true,
            createdAt: n.createdAt,
            actionUrl: n.actionUrl,
          )
        else
          n,
    ];
  }

  void markAllRead() {
    state = [
      for (final n in state)
        NotificationModel(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          read: true,
          createdAt: n.createdAt,
          actionUrl: n.actionUrl,
        ),
    ];
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<NotificationModel>>((ref) {
  return NotificationsNotifier(ref);
});

final notificationsUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.read).length;
});
