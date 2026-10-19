import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/data/mock_access_control.dart';
import '../../shared/widgets/confidia_confirm_dialog.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/confidia_snackbar.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/premium_search_field.dart';
import '../../shared/widgets/status_badge.dart';
import '../onboarding/guided_tour_access_bridge.dart';
import '../onboarding/onboarding_targets.dart';
import 'governance_models.dart';
import 'governance_provider.dart';
import 'space_edit_sheet.dart';
import 'structure_form_sheet.dart';
import 'widgets/member_permissions_picker.dart';
import 'widgets/org_chart_widget.dart';

/// Live account: one organisation, with the chart, the rights and the invitations on separate tabs.
class LiveGovernanceView extends ConsumerStatefulWidget {
  const LiveGovernanceView({super.key});

  @override
  ConsumerState<LiveGovernanceView> createState() => _LiveGovernanceViewState();
}

class _LiveGovernanceViewState extends ConsumerState<LiveGovernanceView> with SingleTickerProviderStateMixin {
  Timer? _searchTimer;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() action, {String? success}) async {
    final error = await action();
    if (!mounted) return;
    if (error != null) {
      context.showConfidiaSnack(error, type: ConfidiaSnackType.error);
      return;
    }
    if (success != null) {
      context.showConfidiaSnack(success, type: ConfidiaSnackType.success);
    }
  }

  void _onSearch(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(governanceProvider.notifier).search(value);
    });
  }

  void _openInvitations() => _tabs.animateTo(2);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(governanceProvider);
    final workspace = state.workspace;
    final notifier = ref.read(governanceProvider.notifier);
    final pending = workspace?.receivedInvitations.where((item) => item.status == 'pending').length ?? 0;

    ref.listen<int?>(accessTourTabIndexProvider, (prev, next) {
      if (next != null && next >= 0 && next < _tabs.length && _tabs.index != next) {
        _tabs.animateTo(next, duration: const Duration(milliseconds: 200));
      }
    });

    return Column(
      children: [
        Padding(
          padding: ConfidiaInsets.page(context).copyWith(bottom: 0),
          child: KeyedSubtree(
            key: OnboardingTargets.accessHeader,
            child: KeyedSubtree(
              key: OnboardingTargets.structureChips,
              child: _SpaceHeader(
                workspace: workspace,
                loading: state.loading,
                pendingInvitations: pending,
                onOpenInvitations: _openInvitations,
              ),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            tabs: [
              const Tab(text: 'Organigramme'),
              const Tab(text: 'Membres & droits'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Invitations'),
                    if (pending > 0) ...[
                      const SizedBox(width: 6),
                      StatusBadge(label: '$pending', color: context.palette.primary),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _scroll(
                KeyedSubtree(
                  key: OnboardingTargets.orgChart,
                  child: workspace == null
                      ? _ChartPlaceholder(
                          loading: state.loading,
                          onRetry: () => ref.read(governanceProvider.notifier).refresh(),
                        )
                      : OrgChartWidget(
                          nodes: governanceNodes(workspace),
                          members: governanceMembers(workspace),
                          roles: liveGovernanceRoles,
                          levelLabels: workspace.levels,
                          showRoleManager: false,
                          onReparentToLevel: (pair) => _run(() => notifier.reparentToLevel(pair.$1, pair.$2)),
                          onReparentAboveTop: (id) => _run(() => notifier.reparentAboveTop(id)),
                          onLinkTypeChanged: (pair) => _run(() => notifier.changeLinkType(pair.$1, pair.$2)),
                          onUpdateLink: (triple) => _run(
                            () => notifier.updateLink(childId: triple.$1, parentId: triple.$2, linkType: triple.$3),
                          ),
                          onLevelLabelChanged: (depth, label) => _run(() => notifier.setLevelLabel(depth, label)),
                          onNodeRoleChanged: (pair) => _run(() => notifier.changeRole(pair.$1, pair.$2)),
                          onUpsertRole: (_) {},
                          onDeleteRole: (_) {},
                          isBuiltInRole: (_) => true,
                        ),
                ),
              ),
              _scroll(
                KeyedSubtree(
                  key: OnboardingTargets.membersPanel,
                  child: workspace == null
                      ? const SizedBox(height: 48)
                      : _MembersBlock(
                          workspace: workspace,
                          onToggle: (memberId, permissionId) =>
                              _run(() => notifier.togglePermission(memberId, permissionId)),
                          onRemove: (member) async {
                            final ok = await showConfidiaConfirmDialog(
                              context,
                              title: 'Retirer ${member.name} ?',
                              message: 'Cette personne quitte l\'organigramme. Son propre espace n\'est pas effacé.',
                              confirmLabel: 'Retirer',
                              icon: Icons.person_remove_outlined,
                            );
                            if (ok == true) await _run(() => notifier.removeMember(member.id));
                          },
                        ),
                ),
              ),
              _scroll(
                workspace == null
                    ? const SizedBox(height: 48)
                    : _InvitationsBlock(
                        workspace: workspace,
                        results: state.results,
                        onSearch: _onSearch,
                        onInvite: (person) => _run(() => notifier.invite(person.id), success: 'Invitation envoyée'),
                        onAction: (invitation, action) => _run(
                          () => notifier.invitationAction(invitation.id, action),
                          success: switch (action) {
                            'accept' => 'Invitation acceptée',
                            'refuse' => 'Invitation refusée',
                            'cancel' => 'Invitation annulée',
                            _ => 'Invitation mise à jour',
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scroll(Widget child) {
    return ListView(
      padding: ConfidiaInsets.page(context),
      children: [child],
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  final bool loading;
  final VoidCallback onRetry;

  const _ChartPlaceholder({required this.loading, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: SizedBox(
        height: 120,
        child: Center(
          child: loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Impossible de charger l\'espace.'),
                    TextButton(onPressed: onRetry, child: const Text('Réessayer')),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SpaceHeader extends ConsumerWidget {
  final GovernanceWorkspace? workspace;
  final bool loading;
  final int pendingInvitations;
  final VoidCallback onOpenInvitations;

  const _SpaceHeader({
    required this.workspace,
    required this.loading,
    required this.pendingInvitations,
    required this.onOpenInvitations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = workspace?.name ?? 'Famille';
    final kind = workspace == null ? 'Espace' : governanceKindLabel(workspace!.kind);
    final icon = StructureIconOptions.iconFor(workspace?.icon);
    final subtitle = loading && workspace == null
        ? 'Ouverture de l\'espace…'
        : workspace == null
            ? 'L\'espace n\'a pas pu être ouvert.'
            : '$kind · créé avec votre compte';
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                    Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConfidiaGlowButton(
                label: 'Modifier',
                icon: Icons.edit_outlined,
                onPressed: workspace == null || !workspace!.canManage ? null : () => showSpaceEditSheet(context, ref),
              ),
            ],
          ),
          if (pendingInvitations > 0) ...[
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onOpenInvitations,
              child: Text(
                pendingInvitations == 1 ? '1 invitation à traiter' : '$pendingInvitations invitations à traiter',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MembersBlock extends StatelessWidget {
  final GovernanceWorkspace workspace;
  final void Function(String memberId, String permissionId) onToggle;
  final Future<void> Function(GovernanceMember member) onRemove;

  const _MembersBlock({
    required this.workspace,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Membres et droits', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Ces droits sont enregistrés pour chaque membre. Les documents et l\'agenda restent ceux de l\'espace.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          for (final member in workspace.members) ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, style: Theme.of(context).textTheme.titleSmall),
                      Text(member.email, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                StatusBadge(label: governanceRoleLabel(member.role), color: palette.primary),
                if (workspace.canManage && member.role != 'owner')
                  IconButton(
                    tooltip: 'Retirer',
                    onPressed: () => onRemove(member),
                    icon: const Icon(Icons.person_remove_outlined, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            MemberPermissionsPicker(
              permissions: MockAccessControl.permissions,
              selectedIds: member.permissions,
              onToggle: workspace.canManage ? (id) => onToggle(member.id, id) : (_) {},
            ),
          ],
        ],
      ),
    );
  }
}

class _InvitationsBlock extends StatelessWidget {
  final GovernanceWorkspace workspace;
  final List<GovernancePerson> results;
  final ValueChanged<String> onSearch;
  final ValueChanged<GovernancePerson> onInvite;
  final void Function(GovernanceInvitation invitation, String action) onAction;

  const _InvitationsBlock({
    required this.workspace,
    required this.results,
    required this.onSearch,
    required this.onInvite,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final memberIds = {for (final member in workspace.members) member.userId};
    final pendingIds = {
      for (final invitation in workspace.sentInvitations)
        if (invitation.status == 'pending') invitation.inviteeId,
    };
    final pendingReceived = workspace.receivedInvitations.where((item) => item.status == 'pending').length;

    return Column(
      children: [
        _InvitationSection(
          icon: Icons.move_to_inbox_rounded,
          title: 'Reçues',
          subtitle: 'Les espaces qui vous invitent.',
          count: pendingReceived,
          children: [
            if (workspace.receivedInvitations.isEmpty)
              const _InvitationEmpty(icon: Icons.mark_email_unread_outlined, label: 'Aucune invitation reçue.')
            else
              for (final invitation in workspace.receivedInvitations)
                _InvitationTile(
                  name: invitation.organizationName,
                  detail: 'Invité par ${invitation.inviterName}',
                  status: invitation.status,
                  actions: invitation.status == 'pending'
                      ? [
                          ConfidiaGlowButton(
                            label: 'Accepter',
                            icon: Icons.check_rounded,
                            onPressed: () => onAction(invitation, 'accept'),
                          ),
                          ConfidiaGlowButton(
                            label: 'Refuser',
                            icon: Icons.close_rounded,
                            primary: false,
                            onPressed: () => onAction(invitation, 'refuse'),
                          ),
                        ]
                      : const [],
                ),
          ],
        ),
        if (workspace.canManage) ...[
          const SizedBox(height: ConfidiaSpacing.md),
          _InvitationSection(
            icon: Icons.person_add_alt_1_rounded,
            title: 'Inviter',
            subtitle: 'Recherchez un profil Confidia déjà inscrit.',
            children: [
              PremiumSearchField(
                hintText: 'Nom ou e-mail d\'un profil Confidia',
                onChanged: onSearch,
              ),
              for (final person in results)
                _InvitationTile(
                  name: person.name,
                  detail: person.email,
                  actions: [
                    if (memberIds.contains(person.id))
                      const StatusBadge(label: 'Déjà membre', color: ConfidiaColors.success)
                    else if (pendingIds.contains(person.id))
                      const StatusBadge(label: 'En attente', color: ConfidiaColors.warning)
                    else
                      ConfidiaGlowButton(
                        label: 'Inviter',
                        icon: Icons.send_rounded,
                        onPressed: () => onInvite(person),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: ConfidiaSpacing.md),
          _InvitationSection(
            icon: Icons.outbox_rounded,
            title: 'Envoyées',
            subtitle: 'Le statut de chaque invitation est enregistré.',
            count: workspace.sentInvitations.length,
            children: [
              if (workspace.sentInvitations.isEmpty)
                const _InvitationEmpty(icon: Icons.outgoing_mail, label: 'Aucune invitation envoyée.')
              else
                for (final invitation in workspace.sentInvitations)
                  _InvitationTile(
                    name: invitation.inviteeName,
                    detail: invitation.inviteeEmail,
                    status: invitation.status,
                    centerActions: true,
                    actions: invitation.status == 'pending'
                        ? [
                            ConfidiaGlowButton(
                              label: 'Annuler',
                              icon: Icons.close_rounded,
                              primary: false,
                              onPressed: () => onAction(invitation, 'cancel'),
                            ),
                          ]
                        : const [],
                  ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InvitationSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int? count;
  final List<Widget> children;

  const _InvitationSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: palette.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (count != null && count! > 0) StatusBadge(label: '$count', color: palette.primary),
            ],
          ),
          const SizedBox(height: ConfidiaSpacing.md),
          ..._spaced(children),
        ],
      ),
    );
  }

  List<Widget> _spaced(List<Widget> items) {
    if (items.length < 2) return items;
    final spaced = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) spaced.add(const SizedBox(height: ConfidiaSpacing.sm));
      spaced.add(items[i]);
    }
    return spaced;
  }
}

class _InvitationEmpty extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InvitationEmpty({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
        border: Border.all(color: ConfidiaColors.border(isDark)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: ConfidiaColors.textSecondary(isDark)),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _InvitationTile extends StatelessWidget {
  final String name;
  final String detail;
  final String? status;
  final List<Widget> actions;
  final bool centerActions;

  const _InvitationTile({
    required this.name,
    required this.detail,
    this.status,
    this.actions = const [],
    this.centerActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(ConfidiaSpacing.radiusMd),
        border: Border.all(color: ConfidiaColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Initials(name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                    Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (status != null) ...[
                const SizedBox(width: 8),
                StatusBadge(label: invitationStatusLabel(status!), color: _invitationStatusColor(status!, palette.primary)),
              ],
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: centerActions ? Alignment.center : Alignment.centerLeft,
              child: Wrap(spacing: 8, runSpacing: 8, children: actions),
            ),
          ],
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;

  const _Initials(this.name);

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final letters = parts.length >= 2
        ? '${parts.first[0]}${parts[1][0]}'
        : parts.isEmpty
            ? '?'
            : parts.first.substring(0, 1);
    return CircleAvatar(
      radius: 18,
      backgroundColor: context.palette.primary.withValues(alpha: 0.16),
      child: Text(
        letters.toUpperCase(),
        style: TextStyle(color: context.palette.primary, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

Color _invitationStatusColor(String status, Color accent) => switch (status) {
      'pending' => ConfidiaColors.warning,
      'accepted' => ConfidiaColors.success,
      'refused' || 'cancelled' => ConfidiaColors.error,
      _ => accent,
    };
