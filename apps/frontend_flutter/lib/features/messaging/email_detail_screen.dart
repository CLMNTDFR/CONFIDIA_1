import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/models/ai_insight_model.dart';
import '../../shared/widgets/confidia_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/provider_chip.dart';
import '../../shared/widgets/confidia_page_reveal.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/status_badge.dart';
import 'messaging_provider.dart';

class EmailDetailScreen extends ConsumerWidget {
  final String emailId;

  const EmailDetailScreen({super.key, required this.emailId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(messagingProvider.notifier);
    final email = notifier.byId(emailId);

    if (email == null) return const Center(child: Text('Message introuvable'));

    final insight = notifier.ai.analyzeEmail(email);

    return SingleChildScrollView(
      padding: ConfidiaInsets.page(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => context.go('/messaging'), icon: const Icon(Icons.arrow_back_rounded)),
              Expanded(child: Text(email.subject, style: Theme.of(context).textTheme.titleLarge, maxLines: 2)),
              IconButton(
                icon: Icon(email.isStarred ? Icons.star_rounded : Icons.star_outline_rounded, color: ConfidiaColors.warning),
                onPressed: () => ref.read(messagingProvider.notifier).toggleStar(email.id),
              ),
            ],
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          Row(
            children: [
              MailProviderChip(provider: email.provider),
              const SizedBox(width: 8),
              Text(email.accountEmail, style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              Text(DateFormat('d MMM yyyy · HH:mm', 'fr_FR').format(email.receivedAt), style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: ConfidiaSpacing.lg),
          ConfidiaPageReveal(
            index: 0,
            staggerCount: 3,
            child: _AiInsightCard(insight: insight),
          ),
          const SizedBox(height: ConfidiaSpacing.md),
          ConfidiaPageReveal(
            index: 1,
            staggerCount: 3,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('De : ${email.sender}', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 16),
                  Text(email.body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
                ],
              ),
            ),
          ),
          const SizedBox(height: ConfidiaSpacing.lg),
          ConfidiaPageReveal(
            index: 2,
            staggerCount: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Actions rapides', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: ConfidiaSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (email.documentId != null)
                      _ActionChip(icon: Icons.description_rounded, label: 'Fiche documentaire', onTap: () => context.go('/documents/${email.documentId}')),
                    _ActionChip(icon: Icons.auto_awesome_rounded, label: 'Analyser avec l\'IA', onTap: () => _showSnack(context, 'Analyse IA terminée')),
                    _ActionChip(icon: Icons.archive_rounded, label: 'Archiver', onTap: () => _showSnack(context, 'Email archivé')),
                    _ActionChip(icon: Icons.notifications_active_rounded, label: 'Créer un rappel', onTap: () => _showSnack(context, 'Rappel créé')),
                    if (email.eventId != null)
                      _ActionChip(icon: Icons.calendar_month_rounded, label: 'Voir au calendrier', onTap: () => context.go('/calendar')),
                    if (email.paymentId != null)
                      _ActionChip(icon: Icons.payment_rounded, label: 'Payer', onTap: () => context.go('/payments/${email.paymentId}')),
                    _ActionChip(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Marquer traité',
                      onTap: () {
                        ref.read(messagingProvider.notifier).markProcessed(email.id);
                        _showSnack(context, 'Email marqué comme traité');
                      },
                    ),
                  ],
                ),
                if (!email.isProcessed && email.paymentId != null) ...[
                  const SizedBox(height: ConfidiaSpacing.lg),
                  ConfidiaButton(label: 'Payer maintenant', icon: Icons.payment_rounded, onPressed: () => context.go('/payments/${email.paymentId}')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }
}

class _AiInsightCard extends StatelessWidget {
  final AiInsightModel insight;

  const _AiInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      highlighted: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: ConfidiaColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text('Résumé IA', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              StatusBadge(label: 'Priorité ${insight.priority.label}', color: insight.priority.color),
            ],
          ),
          const SizedBox(height: 12),
          Text(insight.summary, style: Theme.of(context).textTheme.bodyMedium),
          if (insight.detectedAmount != null || insight.detectedDeadline != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (insight.detectedAmount != null)
                  _MetricChip(icon: Icons.euro_rounded, label: '${insight.detectedAmount!.toStringAsFixed(2)} €'),
                if (insight.detectedDeadline != null) ...[
                  const SizedBox(width: 8),
                  _MetricChip(icon: Icons.event_rounded, label: DateFormat('d MMM yyyy', 'fr_FR').format(insight.detectedDeadline!)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ConfidiaColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ConfidiaColors.primary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: ConfidiaColors.primary),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
