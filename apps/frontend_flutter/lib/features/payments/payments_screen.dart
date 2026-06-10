import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/confidia_page_reveal.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/confidia_glow_segmented.dart';
import '../../shared/widgets/status_badge.dart';
import 'payments_provider.dart';

enum _PaymentsTab { pending, paid }

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  _PaymentsTab _tab = _PaymentsTab.pending;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(paymentsProvider.notifier);
    final pending = notifier.pending;
    final paid = notifier.paid;
    final showPending = _tab == _PaymentsTab.pending;

    return Column(
      children: [
        ConfidiaPageReveal(
          index: 0,
          staggerCount: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(ConfidiaSpacing.lg, ConfidiaSpacing.lg, ConfidiaSpacing.lg, 0),
            child: _SummaryBanner(total: notifier.totalPending, count: pending.length, next: notifier.nextDue),
          ),
        ),
        const SizedBox(height: ConfidiaSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg),
          child: ConfidiaGlowSegmentedControl<_PaymentsTab>(
            expand: true,
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
            segments: [
              ConfidiaGlowSegment(
                value: _PaymentsTab.pending,
                label: 'À traiter (${pending.length})',
                icon: Icons.pending_actions_rounded,
              ),
              ConfidiaGlowSegment(
                value: _PaymentsTab.paid,
                label: 'Effectués (${paid.length})',
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: ConfidiaSpacing.sm),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: showPending
                ? _PaymentList(
                    key: const ValueKey('pending'),
                    payments: pending,
                    emptyMessage: 'Aucun paiement en attente',
                  )
                : _PaymentList(
                    key: const ValueKey('paid'),
                    payments: paid,
                    emptyMessage: 'Aucun paiement effectué',
                  ),
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

  const _PaymentList({super.key, required this.payments, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Center(child: Text(emptyMessage, style: Theme.of(context).textTheme.bodyMedium));
    }
    return ListView.separated(
      padding: ConfidiaInsets.page(context),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final stagger = ConfidiaPageRevealTiming.staggerCount(
          context,
          payments.length,
          itemExtent: 100,
          overhead: 360,
        );
        return ConfidiaPageReveal(
          index: i,
          staggerCount: stagger,
          child: _PaymentCard(payment: payments[i]),
        );
      },
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(payment.creditor, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(payment.label, style: Theme.of(context).textTheme.bodySmall),
                    Text('Échéance · ${DateFormat('d MMM yyyy', 'fr_FR').format(payment.dueDate)}', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(label: payment.status.label, color: payment.status.color),
              const SizedBox(width: 12),
              Text(payment.amountFormatted, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
