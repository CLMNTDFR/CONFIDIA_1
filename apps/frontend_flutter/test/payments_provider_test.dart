import 'package:confidia/features/payments/payments_provider.dart';
import 'package:confidia/shared/models/payment_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pending list and totals stay consistent', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(paymentsProvider.notifier);
    final pending = notifier.pending;

    expect(pending, isNotEmpty);
    expect(
      pending.every((p) => p.status == PaymentStatus.pending || p.status == PaymentStatus.waiting),
      isTrue,
    );
    expect(notifier.totalPending, pending.fold<double>(0, (s, p) => s + p.amount));
    expect(notifier.nextDue?.id, pending.first.id);
  });
}
