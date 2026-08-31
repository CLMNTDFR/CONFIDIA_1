import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/workspace_session.dart';
import '../../shared/data/mock_ecosystem.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/services/mock_ai_service.dart';

class PaymentsNotifier extends StateNotifier<List<PaymentModel>> {
  PaymentsNotifier(this._ref) : super(demoSeedOrEmpty(_ref.read(authStateProvider), MockEcosystem.payments)) {
    _ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (!workspaceSessionChanged(prev, next)) return;
      state = demoSeedOrEmpty(next, MockEcosystem.payments);
    });
  }

  final Ref _ref;
  final _ai = const MockAiService();

  List<PaymentModel> get pending =>
      state.where((p) => p.status == PaymentStatus.pending || p.status == PaymentStatus.waiting).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  List<PaymentModel> get paid =>
      state.where((p) => p.status == PaymentStatus.paid).toList()
        ..sort((a, b) => (b.paidAt ?? b.dueDate).compareTo(a.paidAt ?? a.dueDate));

  double get totalPending => pending.fold(0, (s, p) => s + p.amount);

  PaymentModel? get nextDue {
    if (pending.isEmpty) return null;
    return pending.first;
  }

  PaymentModel? byId(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<String> payNow(String id) async {
    await Future.delayed(const Duration(milliseconds: 1800));
    final payment = byId(id);
    if (payment == null) return 'Paiement introuvable';
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(status: PaymentStatus.paid, paidAt: DateTime.now()) else p,
    ];
    return _ai.generatePaymentConfirmation(payment.creditor, payment.amount);
  }
}

final paymentsProvider = StateNotifierProvider<PaymentsNotifier, List<PaymentModel>>((ref) {
  return PaymentsNotifier(ref);
});
