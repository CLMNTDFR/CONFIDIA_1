import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/mock_ecosystem.dart';
import '../../shared/models/email_model.dart';
import '../../shared/services/mock_ai_service.dart';

class MessagingNotifier extends StateNotifier<List<EmailModel>> {
  MessagingNotifier() : super(List.from(MockEcosystem.emails));

  final _ai = const MockAiService();

  List<EmailModel> get inbox => List.from(state)..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

  List<EmailModel> get unread => inbox.where((e) => !e.isRead).toList();

  int get unreadCount => unread.length;

  EmailModel? byId(String id) {
    try {
      return state.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void markRead(String id) {
    state = [for (final e in state) if (e.id == id) e.copyWith(isRead: true) else e];
  }

  void markProcessed(String id) {
    state = [for (final e in state) if (e.id == id) e.copyWith(isRead: true, isProcessed: true) else e];
  }

  void toggleStar(String id) {
    state = [for (final e in state) if (e.id == id) e.copyWith(isStarred: !e.isStarred) else e];
  }

  MockAiService get ai => _ai;
}

final messagingProvider = StateNotifierProvider<MessagingNotifier, List<EmailModel>>((ref) {
  return MessagingNotifier();
});

/// Narrow rebuilds for mail badges (shell) without watching the full inbox list identity elsewhere.
final messagingUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(messagingProvider).where((e) => !e.isRead).length;
});

final mailFilterProvider = StateProvider<MailProvider?>((ref) => null);
