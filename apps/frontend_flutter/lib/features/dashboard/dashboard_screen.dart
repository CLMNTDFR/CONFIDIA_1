import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/document_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final docs = MockData.documents;
    final events = MockData.calendarEvents;
    final notifications = MockData.notifications;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ConfidiaSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                highlighted: true,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (b) => ConfidiaColors.brandGradient.createShader(b),
                            child: Text('Bonjour 👋', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(height: 4),
                          Text('Bienvenue sur CONFIDIA · $dateStr', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    if (isWide)
                      Row(
                        children: [
                          OutlinedButton.icon(onPressed: () => context.go('/scan'), icon: const Icon(Icons.document_scanner_rounded, size: 18), label: const Text('Scanner')),
                          const SizedBox(width: ConfidiaSpacing.sm),
                          ElevatedButton.icon(onPressed: () => context.go('/upload'), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Importer')),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: ConfidiaSpacing.lg),
              isWide ? _buildWideStats(docs, events, notifications) : _buildNarrowStats(docs, events, notifications),
              const SizedBox(height: ConfidiaSpacing.lg),
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _RecentDocuments(docs: docs)),
                        const SizedBox(width: ConfidiaSpacing.md),
                        Expanded(flex: 2, child: _UpcomingDeadlines(events: events)),
                      ],
                    )
                  : Column(
                      children: [
                        _RecentDocuments(docs: docs),
                        const SizedBox(height: ConfidiaSpacing.md),
                        _UpcomingDeadlines(events: events),
                      ],
                    ),
              const SizedBox(height: ConfidiaSpacing.lg),
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _ImportantDocuments(docs: docs.where((d) => d.isImportant).toList())),
                        const SizedBox(width: ConfidiaSpacing.md),
                        Expanded(child: _RecentActivity(notifications: notifications)),
                      ],
                    )
                  : Column(
                      children: [
                        _ImportantDocuments(docs: docs.where((d) => d.isImportant).toList()),
                        const SizedBox(height: ConfidiaSpacing.md),
                        _RecentActivity(notifications: notifications),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideStats(docs, events, notifications) {
    return Row(
      children: [
        Expanded(child: StatCard(label: 'Documents', value: '${docs.length}', icon: Icons.folder_copy_rounded, color: ConfidiaColors.primary, trend: '+2')),
        const SizedBox(width: ConfidiaSpacing.md),
        Expanded(child: StatCard(label: 'Échéances', value: '${events.length}', icon: Icons.event_rounded, color: ConfidiaColors.accent)),
        const SizedBox(width: ConfidiaSpacing.md),
        Expanded(child: StatCard(label: 'Non lues', value: '${notifications.where((n) => !n.read).length}', icon: Icons.notifications_active_rounded, color: ConfidiaColors.secondary)),
        const SizedBox(width: ConfidiaSpacing.md),
        Expanded(child: StatCard(label: 'Catégories', value: '${MockData.categories.length - 1}', icon: Icons.category_rounded, color: ConfidiaColors.success)),
      ],
    );
  }

  Widget _buildNarrowStats(docs, events, notifications) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: StatCard(label: 'Documents', value: '${docs.length}', icon: Icons.folder_copy_rounded, color: ConfidiaColors.primary)),
          const SizedBox(width: ConfidiaSpacing.md),
          Expanded(child: StatCard(label: 'Échéances', value: '${events.length}', icon: Icons.event_rounded, color: ConfidiaColors.accent)),
        ]),
        const SizedBox(height: ConfidiaSpacing.md),
        Row(children: [
          Expanded(child: StatCard(label: 'Non lues', value: '${notifications.where((n) => !n.read).length}', icon: Icons.notifications_active_rounded, color: ConfidiaColors.secondary)),
          const SizedBox(width: ConfidiaSpacing.md),
          Expanded(child: StatCard(label: 'Catégories', value: '${MockData.categories.length - 1}', icon: Icons.category_rounded, color: ConfidiaColors.success)),
        ]),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({required this.title, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _RecentDocuments extends StatelessWidget {
  final List<DocumentModel> docs;
  const _RecentDocuments({required this.docs});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Documents récents', actionLabel: 'Voir tout', onAction: () => context.go('/documents')),
          const SizedBox(height: ConfidiaSpacing.md),
          ...docs.take(4).map((doc) => _DocumentTile(doc: doc)),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final DocumentModel doc;
  const _DocumentTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: ConfidiaColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.picture_as_pdf_rounded, color: ConfidiaColors.primary, size: 20),
      ),
      title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${doc.category ?? 'Non classé'} · ${doc.fileSizeFormatted}'),
      trailing: doc.isImportant ? const Icon(Icons.star_rounded, color: ConfidiaColors.warning, size: 18) : null,
      onTap: () => context.go('/documents/${doc.id}'),
    );
  }
}

class _UpcomingDeadlines extends StatelessWidget {
  final List events;
  const _UpcomingDeadlines({required this.events});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Échéances', actionLabel: 'Calendrier', onAction: () => context.go('/calendar')),
          const SizedBox(height: ConfidiaSpacing.md),
          ...events.take(4).map((event) => Padding(
                padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
                child: Row(
                  children: [
                    Container(width: 4, height: 40, decoration: BoxDecoration(color: event.color ?? ConfidiaColors.primary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: ConfidiaSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title, style: Theme.of(context).textTheme.titleSmall),
                          Text(DateFormat('d MMM yyyy', 'fr_FR').format(event.start), style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ImportantDocuments extends StatelessWidget {
  final List<DocumentModel> docs;
  const _ImportantDocuments({required this.docs});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Documents importants', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: ConfidiaSpacing.md),
          ...docs.map((doc) => _DocumentTile(doc: doc)),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final List notifications;
  const _RecentActivity({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Activité récente', actionLabel: 'Voir tout', onAction: () => context.go('/notifications')),
          const SizedBox(height: ConfidiaSpacing.md),
          ...notifications.take(4).map((n) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: ConfidiaColors.primary.withValues(alpha: 0.12),
                  child: const Icon(Icons.bolt_rounded, size: 16, color: ConfidiaColors.primary),
                ),
                title: Text(n.title, style: Theme.of(context).textTheme.titleSmall),
                subtitle: Text(n.message, maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
        ],
      ),
    );
  }
}
