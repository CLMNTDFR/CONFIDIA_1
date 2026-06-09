import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/status_badge.dart';
import 'payments_provider.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(paymentsProvider.notifier);
    final pending = notifier.pending;
    final paid = notifier.paid;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(ConfidiaSpacing.lg, ConfidiaSpacing.lg, ConfidiaSpacing.lg, 0),
          child: _SummaryBanner(total: notifier.totalPending, count: pending.length, next: notifier.nextDue),
        ),
        const SizedBox(height: ConfidiaSpacing.md),
        TabBar(
          controller: _tabs,
          labelColor: ConfidiaColors.primary,
          tabs: [
            Tab(text: 'À traiter (${pending.length})'),
            Tab(text: 'Effectués (${paid.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _PaymentList(payments: pending, emptyMessage: 'Aucun paiement en attente'),
              _PaymentList(payments: paid, emptyMessage: 'Aucun paiement effectué'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final double total;
  final int count;
  final PaymentModel? next;

  const _SummaryBanner({required this.total, required this.count, this.next});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      highlighted: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Montant total à régler', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (b) => ConfidiaColors.brandGradient.createShader(b),
                  child: Text(
                    '${total.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
                Text('$count paiement${count > 1 ? 's' : ''} en attente', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (next != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Prochaine échéance', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(next!.creditor, style: Theme.of(context).textTheme.titleSmall),
                Text(DateFormat('d MMM yyyy', 'fr_FR').format(next!.dueDate), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: ConfidiaColors.primary)),
              ],
            ),
        ],
      ),
    );
  }
}

class _PaymentList extends StatelessWidget {
  final List<PaymentModel> payments;
  final String emptyMessage;

  const _PaymentList({required this.payments, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Center(child: Text(emptyMessage, style: Theme.of(context).textTheme.bodyMedium));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(ConfidiaSpacing.lg),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _PaymentCard(payment: payments[i]),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? ConfidiaColors.darkSurfaceVariant.withValues(alpha: 0.5) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.go('/payments/${payment.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ConfidiaColors.border(isDark)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [payment.status.color.withValues(alpha: 0.2), payment.status.color.withValues(alpha: 0.05)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(payment.icon, color: payment.status.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(payment.creditor, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        StatusBadge(label: payment.status.label, color: payment.status.color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(payment.label, style: Theme.of(context).textTheme.bodySmall),
                    Text('Échéance · ${DateFormat('d MMM yyyy', 'fr_FR').format(payment.dueDate)}', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(payment.amountFormatted, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
