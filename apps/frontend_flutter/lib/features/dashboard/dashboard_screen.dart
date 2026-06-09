import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_ecosystem.dart';
import '../../shared/models/ai_insight_model.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/services/mock_ai_service.dart';
import '../../shared/widgets/provider_chip.dart';
import '../../shared/widgets/status_badge.dart';
import '../payments/payments_provider.dart';
import '../../shared/models/document_model.dart';
import '../../shared/widgets/confidia_button.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_glow_chip.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/stagger_fade.dart';
import '../calendar/calendar_provider.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(dashboardLayoutProvider);
    final user = ref.watch(authStateProvider).user;
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    final bottomInset = layout.editMode ? (layout.hidden.isNotEmpty ? 168.0 : 88.0) : ConfidiaSpacing.lg;

    return Stack(
      children: [
        ReorderableListView.builder(
          padding: EdgeInsets.fromLTRB(ConfidiaSpacing.lg, ConfidiaSpacing.lg, ConfidiaSpacing.lg, bottomInset),
          buildDefaultDragHandles: false,
          onReorder: ref.read(dashboardLayoutProvider.notifier).reorderVisible,
          itemCount: layout.visible.length,
          itemBuilder: (context, index) {
            final type = layout.visible[index];
            return Padding(
              key: ValueKey(type),
              padding: const EdgeInsets.only(bottom: ConfidiaSpacing.md),
              child: StaggerFade(
                index: index,
                child: _buildWidget(context, ref, type, index, user?.firstName ?? 'vous', dateStr, layout.editMode),
              ),
            );
          },
        ),
        if (layout.editMode) ...[
          Positioned(
            left: ConfidiaSpacing.lg,
            right: ConfidiaSpacing.lg,
            bottom: layout.hidden.isNotEmpty ? 88 : ConfidiaSpacing.lg,
            child: _EditModeActions(
              onReset: () => ref.read(dashboardLayoutProvider.notifier).reset(),
              onDone: () => ref.read(dashboardLayoutProvider.notifier).toggleEditMode(),
            ),
          ),
          if (layout.hidden.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _HiddenWidgetsPanel(
                hidden: layout.hidden.toList(),
                onRestore: (type) => ref.read(dashboardLayoutProvider.notifier).toggleWidget(type),
              ),
            ),
        ] else
          Positioned(
            right: ConfidiaSpacing.lg,
            bottom: ConfidiaSpacing.lg,
            child: _CustomizeFab(onPressed: () => ref.read(dashboardLayoutProvider.notifier).toggleEditMode()),
          ),
      ],
    );
  }

  Widget _buildWidget(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetType type,
    int index,
    String name,
    String dateStr,
    bool editMode,
  ) {
    final docs = MockEcosystem.documents;
    final events = ref.watch(calendarProvider);
    final notifications = MockEcosystem.notifications;
    ref.watch(paymentsProvider);
    final paymentsNotifier = ref.read(paymentsProvider.notifier);
    final pendingPayments = paymentsNotifier.pending;
    final totalPending = paymentsNotifier.totalPending;
    final nextPayment = paymentsNotifier.nextDue;

    final content = switch (type) {
      DashboardWidgetType.greeting => _GreetingWidget(name: name),
      DashboardWidgetType.stats => _StatsWidget(docs: docs, events: events, notifications: notifications, pendingCount: pendingPayments.length),
      DashboardWidgetType.quickActions => const _QuickActionsWidget(),
      DashboardWidgetType.pendingPayments => _PendingPaymentsWidget(payments: pendingPayments, total: totalPending, next: nextPayment),
      DashboardWidgetType.recentDocs => _RecentDocsWidget(docs: docs),
      DashboardWidgetType.deadlines => _DeadlinesWidget(events: events),
      DashboardWidgetType.importantDocs => _ImportantDocsWidget(docs: docs.where((d) => d.isImportant).toList()),
      DashboardWidgetType.activity => _ActivityWidget(notifications: notifications),
      DashboardWidgetType.connectedAccounts => const _ConnectedAccountsWidget(),
      DashboardWidgetType.aiAnalyzed => const _AiAnalyzedWidget(),
    };

    if (!editMode) return content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WidgetEditBar(
          index: index,
          label: type.label,
          icon: _iconForType(type),
          onHide: () => ref.read(dashboardLayoutProvider.notifier).toggleWidget(type),
        ),
        Opacity(opacity: 0.92, child: content),
      ],
    );
  }
}

IconData _iconForType(DashboardWidgetType type) => switch (type) {
      DashboardWidgetType.greeting => Icons.waving_hand_rounded,
      DashboardWidgetType.stats => Icons.insights_rounded,
      DashboardWidgetType.quickActions => Icons.bolt_rounded,
      DashboardWidgetType.pendingPayments => Icons.payments_rounded,
      DashboardWidgetType.recentDocs => Icons.folder_copy_rounded,
      DashboardWidgetType.deadlines => Icons.event_rounded,
      DashboardWidgetType.importantDocs => Icons.star_rounded,
      DashboardWidgetType.activity => Icons.history_rounded,
      DashboardWidgetType.connectedAccounts => Icons.hub_rounded,
      DashboardWidgetType.aiAnalyzed => Icons.auto_awesome_rounded,
    };

class _WidgetEditBar extends StatelessWidget {
  final int index;
  final String label;
  final IconData icon;
  final VoidCallback onHide;

  const _WidgetEditBar({required this.index, required this.label, required this.icon, required this.onHide});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ConfidiaColors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
            ConfidiaColors.secondary.withValues(alpha: isDark ? 0.18 : 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ConfidiaColors.secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: _EditActionChip(icon: Icons.drag_indicator_rounded, label: 'Déplacer'),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 16, color: ConfidiaColors.secondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge, overflow: TextOverflow.ellipsis),
          ),
          _EditActionChip(icon: Icons.visibility_off_outlined, label: 'Masquer', onTap: onHide),
        ],
      ),
    );
  }
}

class _EditActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _EditActionChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HiddenWidgetsPanel extends StatelessWidget {
  final List<DashboardWidgetType> hidden;
  final ValueChanged<DashboardWidgetType> onRestore;

  const _HiddenWidgetsPanel({required this.hidden, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (isDark ? const Color(0xFF14141E) : Colors.white).withValues(alpha: 0.85),
                (isDark ? const Color(0xFF0E0E16) : const Color(0xFFF8F6FC)).withValues(alpha: 0.95),
              ],
            ),
            border: Border(top: BorderSide(color: ConfidiaColors.secondary.withValues(alpha: 0.3))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.widgets_outlined, size: 18, color: ConfidiaColors.secondary),
                  const SizedBox(width: 8),
                  Text('Blocs masqués · à réactiver', style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: hidden.map((type) {
                  return ActionChip(
                    avatar: Icon(_iconForType(type), size: 16, color: ConfidiaColors.primary),
                    label: Text(type.label),
                    backgroundColor: ConfidiaColors.primary.withValues(alpha: 0.1),
                    side: BorderSide(color: ConfidiaColors.primary.withValues(alpha: 0.25)),
                    onPressed: () => onRestore(type),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditModeActions extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onDone;

  const _EditModeActions({required this.onReset, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final fgColor = isDark ? Colors.white : Colors.black;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            elevation: isDark ? 0 : 1,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            child: InkWell(
              onTap: onReset,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ConfidiaColors.border(isDark)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restore_rounded, size: 18, color: fgColor),
                    const SizedBox(width: 8),
                    Text(
                      'Réinitialiser',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: fgColor,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ConfidiaButton(label: 'Terminer', icon: Icons.check_rounded, compact: true, onPressed: onDone),
        ),
      ],
    );
  }
}

class _CustomizeFab extends StatelessWidget {
  final VoidCallback onPressed;

  const _CustomizeFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ConfidiaColors.brandGradient,
        boxShadow: [BoxShadow(color: ConfidiaColors.secondary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: FloatingActionButton.small(
        heroTag: 'dashboard_edit',
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.tune_rounded, color: Colors.white),
      ),
    );
  }
}

class _GreetingWidget extends StatelessWidget {
  final String name;
  const _GreetingWidget({required this.name});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final weekdayRaw = DateFormat('EEEE', 'fr_FR').format(now);
    final weekday = weekdayRaw.isNotEmpty ? '${weekdayRaw[0].toUpperCase()}${weekdayRaw.substring(1)}' : weekdayRaw;
    final monthRaw = DateFormat('MMMM', 'fr_FR').format(now);
    final month = monthRaw.isNotEmpty ? '${monthRaw[0].toUpperCase()}${monthRaw.substring(1)}' : monthRaw;
    final day = DateFormat('d', 'fr_FR').format(now);

    return GlassCard(
      highlighted: true,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  'Bonjour ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ConfidiaColors.textSecondary(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                ShaderMask(
                  shaderCallback: (b) => ConfidiaColors.brandGradient.createShader(b),
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ConfidiaColors.primary.withValues(alpha: isDark ? 0.22 : 0.1),
                  ConfidiaColors.secondary.withValues(alpha: isDark ? 0.18 : 0.08),
                ],
              ),
              border: Border.all(color: ConfidiaColors.secondary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  weekday,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ConfidiaColors.textSecondary(isDark),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: isDark ? Colors.white : ConfidiaColors.primary,
                        ),
                  ),
                ),
                Text(
                  month,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: ConfidiaColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsWidget extends StatelessWidget {
  final List<DocumentModel> docs;
  final List events;
  final List notifications;
  final int pendingCount;
  const _StatsWidget({required this.docs, required this.events, required this.notifications, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return StatsRow(stats: [
      CompactStat(label: 'Documents', value: '${docs.length}', icon: Icons.folder_copy_rounded, color: ConfidiaColors.primary),
      CompactStat(label: 'Paiements', value: '$pendingCount', icon: Icons.payments_rounded, color: ConfidiaColors.accent),
      CompactStat(label: 'Alertes', value: '${notifications.where((n) => !n.read).length}', icon: Icons.notifications_rounded, color: ConfidiaColors.secondary),
      CompactStat(label: 'Emails', value: '${MockEcosystem.emails.length}', icon: Icons.mail_rounded, color: ConfidiaColors.success),
    ]);
  }
}

class _QuickActionsWidget extends StatelessWidget {
  const _QuickActionsWidget();

  @override
  Widget build(BuildContext context) {
    return ConfidiaGlowChipBar(
      centered: true,
      children: [
        ConfidiaGlowChip(
          label: 'Messagerie',
          icon: Icons.mail_rounded,
          selected: false,
          onTap: () => context.go('/messaging'),
        ),
        ConfidiaGlowChip(
          label: 'Paiements',
          icon: Icons.payments_rounded,
          selected: false,
          onTap: () => context.go('/payments'),
        ),
        ConfidiaGlowChip(
          label: 'Scanner',
          icon: Icons.document_scanner_rounded,
          selected: false,
          onTap: () => context.go('/scan'),
        ),
      ],
    );
  }
}

class _PendingPaymentsWidget extends StatelessWidget {
  final List<PaymentModel> payments;
  final double total;
  final PaymentModel? next;

  const _PendingPaymentsWidget({required this.payments, required this.total, this.next});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Paiements en attente', onTap: () => context.go('/payments')),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${total.toStringAsFixed(2)} € à régler', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    if (next != null)
                      Text('Prochaine · ${next!.creditor} · ${DateFormat('d MMM', 'fr_FR').format(next!.dueDate)}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (next != null)
                ConfidiaGlowButton(
                  label: 'Payer',
                  icon: Icons.payment_rounded,
                  onPressed: () => context.go('/payments/${next!.id}'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...payments.take(3).map((p) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(p.icon, color: p.status.color, size: 20),
                title: Text(p.creditor, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(p.label, style: Theme.of(context).textTheme.labelSmall),
                trailing: Text(p.amountFormatted, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                onTap: () => context.go('/payments/${p.id}'),
              )),
        ],
      ),
    );
  }
}

class _ConnectedAccountsWidget extends StatelessWidget {
  const _ConnectedAccountsWidget();

  @override
  Widget build(BuildContext context) {
    final accounts = MockEcosystem.connectedAccounts.take(4);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Comptes connectés', onTap: () => context.go('/settings')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: accounts.map((a) => MailProviderChip(provider: a.provider)).toList(),
          ),
          const SizedBox(height: 8),
          Text('${MockEcosystem.connectedAccounts.length} comptes · Synchronisation active', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AiAnalyzedWidget extends StatelessWidget {
  const _AiAnalyzedWidget();

  @override
  Widget build(BuildContext context) {
    const ai = MockAiService();
    final docs = MockEcosystem.documents.take(3);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Documents analysés par IA', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              StatusBadge(label: '${MockEcosystem.analyzedDocumentsCount} docs', color: ConfidiaColors.secondary),
            ],
          ),
          const SizedBox(height: 8),
          ...docs.map((d) {
            final insight = ai.analyzeDocument(d);
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_awesome_rounded, color: ConfidiaColors.secondary, size: 18),
              title: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(insight.summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
              trailing: StatusBadge(label: insight.priority.label, color: insight.priority.color),
              onTap: () => context.go('/documents/${d.id}'),
            );
          }),
        ],
      ),
    );
  }
}

class _RecentDocsWidget extends StatelessWidget {
  final List<DocumentModel> docs;
  const _RecentDocsWidget({required this.docs});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Documents récents', onTap: () => context.go('/documents')),
          ...docs.take(3).map((d) => _DocRow(doc: d)),
        ],
      ),
    );
  }
}

class _DeadlinesWidget extends StatelessWidget {
  final List events;
  const _DeadlinesWidget({required this.events});

  @override
  Widget build(BuildContext context) {
    final sorted = List.from(events)..sort((a, b) => a.start.compareTo(b.start));

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Prochaines échéances', onTap: () => context.go('/calendar')),
          ...sorted.take(3).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 3, height: 32, decoration: BoxDecoration(color: e.color ?? ConfidiaColors.primary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.title, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(DateFormat('d MMM', 'fr_FR').format(e.start), style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ImportantDocsWidget extends StatelessWidget {
  final List<DocumentModel> docs;
  const _ImportantDocsWidget({required this.docs});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Documents importants', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...docs.map((d) => _DocRow(doc: d)),
        ],
      ),
    );
  }
}

class _ActivityWidget extends StatelessWidget {
  final List notifications;
  const _ActivityWidget({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Activité', onTap: () => context.go('/notifications')),
          ...notifications.take(3).map((n) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bolt_rounded, size: 18, color: ConfidiaColors.primary),
                title: Text(n.title, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(n.message, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              )),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const Spacer(),
          ConfidiaGlowLink(label: 'Voir tout', onTap: onTap),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final DocumentModel doc;
  const _DocRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.picture_as_pdf_rounded, color: ConfidiaColors.primary, size: 20),
      title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${doc.category ?? 'Non classé'} · ${doc.fileSizeFormatted}', style: Theme.of(context).textTheme.labelSmall),
      trailing: doc.isImportant ? const Icon(Icons.star_rounded, color: ConfidiaColors.warning, size: 16) : null,
      onTap: () => context.go('/documents/${doc.id}'),
    );
  }
}
