import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/spacing.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/services/serenity_service.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_page_reveal.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/status_badge.dart';
import '../messaging/messaging_provider.dart';
import '../serenity_feedback/serenity_moments_provider.dart';
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPay = payment.status == PaymentStatus.pending || payment.status == PaymentStatus.waiting;
    final daysLeft = payment.dueDate.difference(DateTime.now()).inDays;

    return SingleChildScrollView(
      padding: ConfidiaInsets.page(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConfidiaPageReveal(
                index: 0,
                staggerCount: 4,
                child: _PaymentHeroCard(
                  payment: payment,
                  canPay: canPay,
                  daysLeft: daysLeft,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: ConfidiaSpacing.md),
              ConfidiaPageReveal(
                index: 1,
                staggerCount: 4,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.tag_rounded,
                        label: 'Référence',
                        value: payment.reference ?? 'N/A',
                        isDark: isDark,
                      ),
                      _InfoRow(
                        icon: Icons.event_rounded,
                        label: 'Échéance',
                        value: DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(payment.dueDate),
                        isDark: isDark,
                      ),
                      if (payment.paidAt != null)
                        _InfoRow(
                          icon: Icons.check_circle_rounded,
                          label: 'Payé le',
                          value: DateFormat('d MMM yyyy à HH:mm', 'fr_FR').format(payment.paidAt!),
                          isDark: isDark,
                        ),
                    ],
                  ),
                ),
              ),
              if (payment.documentId != null || payment.emailId != null) ...[
                const SizedBox(height: ConfidiaSpacing.md),
                ConfidiaPageReveal(
                  index: 2,
                  staggerCount: 4,
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        if (payment.documentId != null)
                          _LinkTile(
                            icon: Icons.description_rounded,
                            color: ConfidiaColors.textSecondary(isDark),
                            title: 'Document lié',
                            subtitle: 'Consulter la fiche documentaire',
                            onTap: () => context.go('/documents/${payment.documentId}'),
                          ),
                        if (payment.documentId != null && payment.emailId != null)
                          Divider(height: 1, color: ConfidiaColors.border(isDark)),
                        if (payment.emailId != null)
                          _LinkTile(
                            icon: Icons.mail_rounded,
                            color: ConfidiaColors.textSecondary(isDark),
                            title: 'Email source',
                            subtitle: 'Ouvrir dans la messagerie',
                            onTap: () => context.go('/messaging/${payment.emailId}'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: ConfidiaSpacing.md),
                GlassCard(
                  highlighted: true,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ConfidiaColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: ConfidiaColors.success, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_successMessage!, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ],
              if (canPay) ...[
                const SizedBox(height: ConfidiaSpacing.xl),
                ConfidiaPageReveal(
                  index: 3,
                  staggerCount: 4,
                  child: Center(
                    child: ConfidiaGlowButton(
                      label: _paying ? 'Traitement…' : 'Payer maintenant',
                      icon: Icons.payment_rounded,
                      onPressed: _paying ? null : () => _simulatePay(payment.id),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: ConfidiaSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _simulatePay(String id) async {
    setState(() => _paying = true);
    final payment = ref.read(paymentsProvider.notifier).byId(id);
    final penaltyAvoided =
        payment != null ? SerenityService.estimatePenaltyAvoided(payment) : 0.0;
    // Avant payNow : le listen score lit cette valeur pour l'overlay.
    if (payment != null) {
      ref.read(serenityMomentsProvider.notifier).notifyPaymentSuccess(penaltyAvoided: penaltyAvoided);
    }
    final msg = await ref.read(paymentsProvider.notifier).payNow(id);
    // Démo : le courrier lié disparaît aussi du briefing / des priorités.
    final emailId = payment?.emailId;
    if (emailId != null) {
      ref.read(messagingProvider.notifier).markProcessed(emailId);
    }
    if (mounted) setState(() { _paying = false; _successMessage = msg; });
  }
}

class _PaymentHeroCard extends StatelessWidget {
  final PaymentModel payment;
  final bool canPay;
  final int daysLeft;
  final bool isDark;

  const _PaymentHeroCard({
    required this.payment,
    required this.canPay,
    required this.daysLeft,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 420;
    final dueCaption = _dueCaption();
    final dueValue = _dueValue();

    return GlassCard(
      highlighted: true,
      clipContent: false,
      padding: EdgeInsets.fromLTRB(isCompact ? 16 : 20, 16, isCompact ? 16 : 20, 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -24,
            top: -32,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    payment.status.themeColor(context.palette).withValues(alpha: 0.2),
                    payment.status.themeColor(context.palette).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroIcon(icon: payment.icon, color: payment.status.themeColor(context.palette)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        payment.creditor,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(label: payment.status.label, color: payment.status.themeColor(context.palette)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 56),
                  Expanded(
                    child: Text(
                      payment.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ConfidiaColors.textSecondary(isDark),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (payment.reference != null) ...[
                    const SizedBox(width: 12),
                    _HeroMetaChip(
                      icon: Icons.tag_rounded,
                      label: payment.reference!,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(
                  height: 1,
                  color: ConfidiaColors.border(isDark),
                ),
              ),
              if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _HeroAmount(amount: payment.amountFormatted)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (dueCaption != null)
                          Expanded(
                            child: _HeroDueBlock(
                              caption: dueCaption,
                              value: dueValue,
                              color: payment.status.themeColor(context.palette),
                            ),
                          ),
                        Expanded(
                          child: Align(
                            alignment: dueCaption != null ? Alignment.centerRight : Alignment.center,
                            child: _HeroDueBlock(
                              caption: 'Échéance',
                              value: DateFormat('d MMM yyyy', 'fr_FR').format(payment.dueDate),
                              color: ConfidiaColors.textSecondary(isDark),
                              compact: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _HeroAmount(amount: payment.amountFormatted),
                      ),
                    ),
                    if (dueCaption != null)
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.center,
                          child: _HeroDueBlock(caption: dueCaption, value: dueValue, color: payment.status.themeColor(context.palette)),
                        ),
                      ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _HeroDueBlock(
                          caption: 'Échéance',
                          value: DateFormat('d MMM yyyy', 'fr_FR').format(payment.dueDate),
                          color: ConfidiaColors.textSecondary(isDark),
                          compact: true,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String? _dueCaption() {
    if (payment.paidAt != null) return 'Réglé le';
    if (canPay && daysLeft >= 0) return 'Délai restant';
    return null;
  }

  String _dueValue() {
    if (payment.paidAt != null) {
      return DateFormat('d MMM yyyy', 'fr_FR').format(payment.paidAt!);
    }
    if (canPay && daysLeft >= 0) {
      if (daysLeft == 0) return 'Aujourd\'hui';
      return '$daysLeft jour${daysLeft > 1 ? 's' : ''}';
    }
    return DateFormat('d MMM yyyy', 'fr_FR').format(payment.dueDate);
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _HeroIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.88), color.withValues(alpha: 0.42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _HeroAmount extends StatelessWidget {
  final String amount;

  const _HeroAmount({required this.amount});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      amount,
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: ConfidiaColors.textPrimary(isDark),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1,
          ),
    );
  }
}

class _HeroDueBlock extends StatelessWidget {
  final String caption;
  final String value;
  final Color color;
  final bool compact;

  const _HeroDueBlock({
    required this.caption,
    required this.value,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark),
                letterSpacing: 0.2,
              ),
        ),
        SizedBox(height: compact ? 2 : 4),
        Text(
          value,
          style: (compact ? Theme.of(context).textTheme.labelLarge : Theme.of(context).textTheme.titleSmall)?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _HeroMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _HeroMetaChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ConfidiaColors.border(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ConfidiaColors.textSecondary(isDark)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ConfidiaColors.textSecondary(isDark).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: ConfidiaColors.textSecondary(isDark)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark)),
            ],
          ),
        ),
      ),
    );
  }
}
