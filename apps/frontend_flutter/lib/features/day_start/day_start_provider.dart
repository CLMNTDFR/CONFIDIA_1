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

enum DayStartPhase { idle, preparing, streaming, ready }

class DayStartSession {
  final DayStartPhase phase;
  final DayBriefing? briefing;
  final DateTime? completedOnDay;

  const DayStartSession({
    this.phase = DayStartPhase.idle,
    this.briefing,
    this.completedOnDay,
  });

  bool get isOpen => phase != DayStartPhase.idle;

  bool get completedToday {
    if (completedOnDay == null) return false;
    final now = DateTime.now();
    return completedOnDay!.year == now.year &&
        completedOnDay!.month == now.month &&
        completedOnDay!.day == now.day;
  }

  DayStartSession copyWith({
    DayStartPhase? phase,
    DayBriefing? briefing,
    DateTime? completedOnDay,
    bool clearBriefing = false,
  }) {
    return DayStartSession(
      phase: phase ?? this.phase,
      briefing: clearBriefing ? null : (briefing ?? this.briefing),
      completedOnDay: completedOnDay ?? this.completedOnDay,
    );
  }
}

class DayStartNotifier extends StateNotifier<DayStartSession> {
  DayStartNotifier(this._ref) : super(const DayStartSession());

  final Ref _ref;

  DayBriefing _buildBriefing() {
    return DayBriefingService.build(
      firstName: sessionFirstName(_ref.read(authStateProvider)),
      emails: _ref.read(messagingProvider),
      events: _ref.read(calendarProvider),
      payments: _ref.read(paymentsProvider),
      notifications: _ref.read(notificationsProvider),
      documents: _ref.read(documentsProvider).items,
    );
  }

  /// Recalcule le briefing à partir des données live (factures payées exclues).
  void refreshBriefing() {
    if (state.briefing == null && !state.isOpen) return;
    final briefing = _buildBriefing();
    state = state.copyWith(briefing: briefing);
  }

  Future<void> start() async {
    if (state.isOpen) return;
    state = state.copyWith(phase: DayStartPhase.preparing);

    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    state = state.copyWith(phase: DayStartPhase.streaming, briefing: _buildBriefing());
  }

  void markReady() {
    if (state.phase != DayStartPhase.streaming) return;
    state = state.copyWith(phase: DayStartPhase.ready);
  }

  void dismiss() {
    final now = DateTime.now();
    state = DayStartSession(
      phase: DayStartPhase.idle,
      briefing: state.briefing,
      completedOnDay: DateTime(now.year, now.month, now.day),
    );
  }

  /// Rouvre le briefing avec les données à jour (priorités résolues disparues).
  Future<void> reopen() async {
    state = state.copyWith(phase: DayStartPhase.preparing);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    state = state.copyWith(phase: DayStartPhase.ready, briefing: _buildBriefing());
  }

  /// Ouvre le briefing depuis le chip top bar (start ou reopen selon le jour).
  Future<void> openFromChip() async {
    if (state.isOpen) {
      refreshBriefing();
      return;
    }
    if (state.completedToday) {
      await reopen();
    } else {
      await start();
    }
  }
}

final dayStartSessionProvider =
    StateNotifierProvider<DayStartNotifier, DayStartSession>((ref) {
  final notifier = DayStartNotifier(ref);
  ref.listen(paymentsProvider, (_, __) => notifier.refreshBriefing());
  ref.listen(messagingProvider, (_, __) => notifier.refreshBriefing());
  return notifier;
});
