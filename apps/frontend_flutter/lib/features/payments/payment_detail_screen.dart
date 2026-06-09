import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/widgets/confidia_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/status_badge.dart';
import 'payments_provider.dart';

class PaymentDetailScreen extends ConsumerStatefulWidget {
  final String paymentId;

  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  ConsumerState<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends ConsumerState<PaymentDetailScreen> {
  bool _paying = false;
  String? _successMessage;

  @override
  Widget build(BuildContext context) {
    final payment = ref.watch(paymentsProvider.notifier).byId(widget.paymentId);

    if (payment == null) {
      return const Center(child: Text('Paiement introuvable'));
    }

    final canPay = payment.status == PaymentStatus.pending || payment.status == PaymentStatus.waiting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ConfidiaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            highlighted: true,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: ConfidiaColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(payment.icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                Text(payment.creditor, style: Theme.of(context).textTheme.headlineSmall),
                Text(payment.label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                StatusBadge(label: payment.status.label, color: payment.status.color),
                const SizedBox(height: 20),
                Text(payment.amountFormatted, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: ConfidiaSpacing.md),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(label: 'Référence', value: payment.reference ?? '—'),
                _InfoRow(label: 'Échéance', value: DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(payment.dueDate)),
                if (payment.paidAt != null)
                  _InfoRow(label: 'Payé le', value: DateFormat('d MMM yyyy à HH:mm', 'fr_FR').format(payment.paidAt!)),
                if (payment.documentId != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_rounded, color: ConfidiaColors.primary),
                    title: const Text('Document lié'),
                    subtitle: const Text('Voir la fiche documentaire'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go('/documents/${payment.documentId}'),
                  ),
                if (payment.emailId != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mail_rounded, color: ConfidiaColors.secondary),
                    title: const Text('Email source'),
                    subtitle: const Text('Voir dans la messagerie'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go('/messaging/${payment.emailId}'),
                  ),
              ],
            ),
          ),
          if (_successMessage != null) ...[
            const SizedBox(height: ConfidiaSpacing.md),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: ConfidiaColors.success),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_successMessage!, style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            ),
          ],
          const SizedBox(height: ConfidiaSpacing.xl),
          if (canPay)
            ConfidiaButton(
              label: 'Payer maintenant',
              icon: Icons.payment_rounded,
              loading: _paying,
              loadingLabel: 'Traitement…',
              onPressed: _paying ? null : () => _simulatePay(payment.id),
            ),
        ],
      ),
    );
  }

  Future<void> _simulatePay(String id) async {
    setState(() => _paying = true);
    final msg = await ref.read(paymentsProvider.notifier).payNow(id);
    if (mounted) setState(() { _paying = false; _successMessage = msg; });
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
