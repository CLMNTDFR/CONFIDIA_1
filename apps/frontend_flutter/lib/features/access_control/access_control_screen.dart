import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/models/access_control_models.dart';
import '../../shared/widgets/confidia_confirm_dialog.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_glow_chip.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/confidia_snackbar.dart';
import 'widgets/member_permissions_picker.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/planning_ai_panel.dart';
import '../../shared/widgets/status_badge.dart';
import '../onboarding/guided_tour_access_bridge.dart';
import '../onboarding/onboarding_targets.dart';
import 'access_control_provider.dart';
import 'structure_form_sheet.dart';
import 'widgets/org_chart_widget.dart';

class AccessControlScreen extends ConsumerStatefulWidget {
  const AccessControlScreen({super.key});

  @override
  ConsumerState<AccessControlScreen> createState() => _AccessControlScreenState();
}

class _AccessControlScreenState extends ConsumerState<AccessControlScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _headerExpanded = true;
  bool _headerDefaultApplied = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_headerDefaultApplied) {
      _headerExpanded = MediaQuery.sizeOf(context).width >= 900;
      _headerDefaultApplied = true;
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accessControlProvider);
    final permissions = ref.watch(accessPermissionsProvider);
    final roles = ref.watch(accessRolesProvider);

    ref.listen<bool?>(accessTourHeaderExpandedProvider, (prev, next) {
      if (next != null && next != _headerExpanded) {
        setState(() => _headerExpanded = next);
      }
    });
    ref.listen<int?>(accessTourTabIndexProvider, (prev, next) {
      if (next != null && next >= 0 && next < _tabs.length && _tabs.index != next) {
        _tabs.animateTo(next);
      }
    });

    return Column(
      children: [
        KeyedSubtree(
          key: OnboardingTargets.accessHeader,
          child: Padding(
            padding: ConfidiaInsets.page(context).copyWith(bottom: 0),
            child: InkWell(
              onTap: () => setState(() => _headerExpanded = !_headerExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Gouvernance & accès',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            TextSpan(
                              text: '  ·  ${state.activeProfile.label}',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: ConfidiaColors.textSecondary(
                                      Theme.of(context).brightness == Brightness.dark,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      _headerExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _headerExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: ConfidiaInsets.page(context).copyWith(bottom: 0, top: ConfidiaSpacing.xs),
            child: KeyedSubtree(
              key: OnboardingTargets.structureChips,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...state.allProfiles.map(
                    (p) => ConfidiaGlowChip(
                      label: p.label,
                      icon: p.icon,
                      selected: state.activeStructureId == p.id,
                      onTap: () => ref.read(accessControlProvider.notifier).setStructure(p.id),
                    ),
                  ),
                  ConfidiaGlowChip(
                    label: 'Nouvelle structure',
                    icon: Icons.add_rounded,
                    selected: false,
                    onTap: () => showStructureFormSheet(context),
                  ),
                ],
              ),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
        KeyedSubtree(
          key: OnboardingTargets.accessTabs,
          child: Material(
            color: Colors.transparent,
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Organigramme'),
                Tab(text: 'Membres & droits'),
                Tab(text: 'Demandes'),
                Tab(text: 'IA Planning'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _OrgTab(state: state),
              _MembersTab(state: state, permissions: permissions, roles: roles),
              _SharingTab(state: state),
              _PlanningTab(state: state),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrgTab extends ConsumerWidget {
  final AccessControlState state;

  const _OrgTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFamily = state.activeStructureId == 'family';

    return ListView(
      padding: ConfidiaInsets.page(context),
      children: [
        KeyedSubtree(
          key: OnboardingTargets.orgChart,
          child: OrgChartWidget(
            nodes: state.activeData.nodes,
            members: state.activeData.members,
            roles: ref.watch(accessRolesProvider),
            levelLabels: state.activeData.levelLabels,
            onReparentToLevel: (pair) => ref.read(accessControlProvider.notifier).reparentToLevel(pair.$1, pair.$2),
            onReparentAboveTop: (id) => ref.read(accessControlProvider.notifier).reparentAboveTop(id),
            onLinkTypeChanged: (pair) => ref.read(accessControlProvider.notifier).updateNodeLinkType(pair.$1, pair.$2),
            onUpdateLink: (triple) => ref.read(accessControlProvider.notifier).updateHierarchyLink(
                  childId: triple.$1,
                  parentId: triple.$2,
                  linkType: triple.$3,
                ),
            onLevelLabelChanged: (depth, label) => ref.read(accessControlProvider.notifier).setLevelLabel(depth, label),
            onNodeRoleChanged: (pair) => ref.read(accessControlProvider.notifier).updateNodeRole(pair.$1, pair.$2),
            onUpsertRole: (role) => ref.read(accessControlProvider.notifier).upsertRole(role),
            onDeleteRole: (id) => ref.read(accessControlProvider.notifier).deleteCustomRole(id),
            isBuiltInRole: ref.read(accessControlProvider.notifier).isBuiltInRole,
          ),
        ),
        const SizedBox(height: ConfidiaSpacing.md),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Concept', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                isFamily
                    ? 'Sophie partage son CONFIDIA avec Marc pour coordonner calendriers et documents familiaux. L\'admin définit qui voit quoi.'
                    : 'Le directeur configure l\'organigramme et demande l\'accès aux documents sensibles des membres (avec leur consentement).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MembersTab extends ConsumerWidget {
  final AccessControlState state;
  final List<AccessPermission> permissions;
  final List<AccessRoleTemplate> roles;

  const _MembersTab({required this.state, required this.permissions, required this.roles});

  Future<void> _confirmSave(BuildContext context, WidgetRef ref) async {
    final ok = await showConfidiaConfirmDialog(
      context,
      title: 'Enregistrer les droits ?',
      message:
          'Les permissions modifiées seront appliquées à tous les membres de cette structure. '
          'Cette action mettra à jour la configuration d\'accès.',
      confirmLabel: 'Enregistrer',
      icon: Icons.save_rounded,
    );
    if (ok == true) {
      ref.read(accessControlProvider.notifier).saveMembers();
      if (context.mounted) {
        context.showConfidiaSnack('Droits enregistrés', type: ConfidiaSnackType.success);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = state.activeData.members;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Stack(
      children: [
        KeyedSubtree(
          key: OnboardingTargets.membersPanel,
          child: ListView(
            padding: () {
              final pagePad = ConfidiaInsets.page(context);
              final extra = state.membersDirty
                  ? (isDesktop ? 56.0 : ConfidiaMobileShell.fabScrollClearance())
                  : 0.0;
              return pagePad.copyWith(bottom: pagePad.bottom + extra);
            }(),
            children: members.map((member) {
              final role = roles.firstWhere((r) => r.id == member.roleId, orElse: () => roles.last);
              return Padding(
                padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark)
                                .withValues(alpha: 0.12),
                            child: Icon(
                              roleIcon(member.roleId),
                              size: 16,
                              color: ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member.name, style: Theme.of(context).textTheme.titleSmall),
                                Text(member.email, style: Theme.of(context).textTheme.labelSmall),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: role.label,
                            color: ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Droits accordés', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      MemberPermissionsPicker(
                        permissions: permissions,
                        selectedIds: member.permissions,
                        onToggle: (id) => ref.read(accessControlProvider.notifier).togglePermission(member.id, id),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (state.membersDirty)
          Positioned(
            right: ConfidiaSpacing.lg,
            bottom: isDesktop ? ConfidiaSpacing.lg : ConfidiaMobileShell.fabBottom(context),
            left: isDesktop ? null : ConfidiaInsets.page(context).left,
            child: ConfidiaGlowButton(
              label: isDesktop ? 'Enregistrer' : 'Enregistrer les modifications',
              icon: Icons.save_rounded,
              expand: !isDesktop,
              onPressed: () => _confirmSave(context, ref),
            ),
          ),
      ],
    );
  }
}

class _SharingTab extends ConsumerWidget {
  final AccessControlState state;

  const _SharingTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFamily = state.activeStructureId == 'family';

    return ListView(
      padding: ConfidiaInsets.page(context),
      children: [
        if (isFamily)
          GlassCard(
            child: Text(
              'En mode famille, les documents sont partagés implicitement entre parents. '
              'Les demandes formelles s\'appliquent surtout aux contextes club / association.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ...state.sharingRequests.map((req) => Padding(
                padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_active_rounded,
                            size: 18,
                            color: ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${req.requesterName} demande l\'accès',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          StatusBadge(
                            label: req.isPending ? 'En attente' : req.status == 'accepted' ? 'Accepté' : 'Refusé',
                            color: req.isPending
                                ? ConfidiaColors.warning
                                : req.status == 'accepted'
                                    ? ConfidiaColors.success
                                    : ConfidiaColors.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${req.documentType} • ${req.targetName}', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text(req.message, style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        DateFormat('d MMM yyyy · HH:mm', 'fr_FR').format(req.createdAt),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      if (req.isPending) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ConfidiaGlowButton(
                                label: 'Accepter',
                                icon: Icons.check_rounded,
                                expand: true,
                                onPressed: () => ref.read(accessControlProvider.notifier).respondSharing(req.id, true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ConfidiaGlowButton(
                                label: 'Refuser',
                                icon: Icons.close_rounded,
                                primary: false,
                                expand: true,
                                onPressed: () => ref.read(accessControlProvider.notifier).respondSharing(req.id, false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

class _PlanningTab extends ConsumerWidget {
  final AccessControlState state;

  const _PlanningTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(accessControlProvider.notifier);

    return ListView(
      padding: ConfidiaInsets.page(context),
      children: [
        PlanningAiPanel(
          proposal: state.planningProposal,
          loading: state.planningLoading,
          onAnalyze: notifier.analyzePlanning,
          onRegenerate: notifier.regeneratePlanning,
          onAccept: () {
            context.showConfidiaSnack('Proposition appliquée au planning', type: ConfidiaSnackType.success);
            notifier.clearPlanning();
          },
          onReject: notifier.clearPlanning,
          onRefine: notifier.refinePlanning,
        ),
      ],
    );
  }
}
