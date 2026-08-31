import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';
import '../models/access_control_models.dart';
import 'ai_streaming_text.dart';
import 'cofid_ia_brand.dart';
import 'confidia_ai_robot.dart';
import 'confidia_button.dart';
import 'confidia_demo_badge.dart';
import 'confidia_glow_button.dart';
import 'confidia_tappable.dart';
import 'confidia_text_field.dart';
import 'confidia_tooltip.dart';
import 'glass_card.dart';

/// Panneau Confid•IA (calendrier / gouvernance) : analyse, proposition, ajustement.
class PlanningAiPanel extends StatefulWidget {
  final PlanningProposal? proposal;
  final bool loading;
  final VoidCallback onAnalyze;
  final VoidCallback onRegenerate;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final void Function(String prompt) onRefine;
  final String analyzeLabel;
  final bool initiallyExpanded;

  const PlanningAiPanel({
    super.key,
    required this.proposal,
    required this.loading,
    required this.onAnalyze,
    required this.onRegenerate,
    required this.onAccept,
    required this.onReject,
    required this.onRefine,
    this.analyzeLabel = 'Analyser le planning',
    this.initiallyExpanded = false,
  });

  @override
  State<PlanningAiPanel> createState() => _PlanningAiPanelState();
}

class _PlanningAiPanelState extends State<PlanningAiPanel> {
  final _refineCtrl = TextEditingController();
  bool _streaming = false;
  bool _refineVisible = false;
  late bool _expanded;
  int _streamKey = 0;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void dispose() {
    _refineCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PlanningAiPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldText = oldWidget.proposal?.proposal;
    final newText = widget.proposal?.proposal;
    if (newText != null && newText != oldText && !widget.loading) {
      setState(() {
        _streaming = true;
        _streamKey++;
        _refineVisible = false;
        _refineCtrl.clear();
        _expanded = true;
      });
    }
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (!_expanded) _streaming = false;
    });
  }

  void _setStreaming(bool value) {
    if (!mounted || _streaming == value) return;
    setState(() => _streaming = value);
  }

  void _submitRefine() {
    final prompt = _refineCtrl.text.trim();
    if (prompt.isEmpty || widget.loading) return;
    widget.onRefine(prompt);
  }

  String get _collapsedHint {
    if (widget.proposal != null) return 'Proposition disponible';
    if (widget.loading) return 'Analyse en cours…';
    return 'Conflits et réajustements';
  }

  @override
  Widget build(BuildContext context) {
    final proposal = widget.proposal;
    final hasResult = proposal != null;
    final isActive = widget.loading || _streaming;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = ConfidiaColors.textSecondary(isDark);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConfidiaTappable(
            onTap: _toggleExpanded,
            pressScale: 0.99,
            borderRadius: AppRadius.mdAll,
            hoverOverlay: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  ConfidiaAiRobot(size: 32, speaking: isActive && _expanded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            CofidIaBrand(fontSize: 14, fontWeight: FontWeight.w700),
                            SizedBox(width: 8),
                            ConfidiaDemoBadge(compact: true),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _collapsedHint,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: AppDurations.fast,
                    child: Icon(Icons.expand_more_rounded, size: 22, color: muted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppDurations.snappy,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Divider(height: 1, color: AppBorders.subtle(isDark).color),
                        const SizedBox(height: 14),
                        if (!hasResult)
                          _EmptyState(
                            loading: widget.loading,
                            analyzeLabel: widget.analyzeLabel,
                            onAnalyze: widget.onAnalyze,
                          )
                        else ...[
                          if (proposal.conflicts.isNotEmpty) ...[
                            for (final c in proposal.conflicts)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ConflictTile(conflict: c),
                              ),
                            const SizedBox(height: 4),
                          ],
                          AiStreamingText(
                            key: ValueKey(_streamKey),
                            text: proposal.proposal,
                            showThinkingRobot: false,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  height: 1.55,
                                  color: ConfidiaColors.textPrimary(isDark).withValues(alpha: 0.92),
                                ),
                            onStreamStart: () => _setStreaming(true),
                            onComplete: () => _setStreaming(false),
                          ),
                          if (proposal.alternatives.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              'Alternatives',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: muted,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            for (final a in proposal.alternatives)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('·  ', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted)),
                                    Expanded(
                                      child: Text(
                                        a,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: muted,
                                              height: 1.4,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          const SizedBox(height: 16),
                          _ProposalActions(
                            loading: widget.loading,
                            onAccept: widget.onAccept,
                            onReject: widget.onReject,
                            onRegenerate: widget.onRegenerate,
                            onToggleRefine: () => setState(() => _refineVisible = !_refineVisible),
                          ),
                          AnimatedSize(
                            duration: AppDurations.snappy,
                            curve: Curves.easeOutCubic,
                            child: _refineVisible
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _refineCtrl,
                                      builder: (context, value, _) => _RefinePromptField(
                                        controller: _refineCtrl,
                                        enabled: !widget.loading,
                                        showSend: value.text.isNotEmpty,
                                        onSend: _submitRefine,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool loading;
  final String analyzeLabel;
  final VoidCallback onAnalyze;

  const _EmptyState({
    required this.loading,
    required this.analyzeLabel,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = ConfidiaColors.textSecondary(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        color: AppColors.surface2(isDark).withValues(alpha: isDark ? 0.45 : 0.55),
        border: Border.fromBorderSide(AppBorders.subtle(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Détecte les conflits et propose des réajustements\nsur l\'agenda affiché.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: muted,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          ConfidiaGlowButton(
            label: loading ? 'Analyse en cours…' : analyzeLabel,
            icon: Icons.psychology_rounded,
            expand: true,
            onPressed: loading ? null : onAnalyze,
          ),
        ],
      ),
    );
  }
}

class _ProposalActions extends StatelessWidget {
  final bool loading;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onRegenerate;
  final VoidCallback onToggleRefine;

  const _ProposalActions({
    required this.loading,
    required this.onAccept,
    required this.onReject,
    required this.onRegenerate,
    required this.onToggleRefine,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConfidiaGlowButton(
          label: 'Accepter',
          icon: Icons.check_rounded,
          expand: true,
          onPressed: loading ? null : onAccept,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ConfidiaIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Refuser',
              compact: true,
              onPressed: loading ? null : onReject,
            ),
            const SizedBox(width: 6),
            ConfidiaIconButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Nouvelle proposition',
              compact: true,
              onPressed: loading ? null : onRegenerate,
            ),
            const Spacer(),
            ConfidiaGlowButton(
              label: 'Ajuster',
              icon: Icons.tune_rounded,
              primary: false,
              onPressed: loading ? null : onToggleRefine,
            ),
          ],
        ),
      ],
    );
  }
}

class _RefinePromptField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool showSend;
  final VoidCallback onSend;

  const _RefinePromptField({
    required this.controller,
    required this.enabled,
    required this.showSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = ConfidiaColors.textSecondary(isDark);

    return TextFormField(
      controller: controller,
      enabled: enabled,
      minLines: 1,
      maxLines: 5,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: ConfidiaTextFormField.fieldStyle(context),
      onFieldSubmitted: (_) => onSend(),
      decoration: InputDecoration(
        hintText: 'Ex : Sophie récupère Léa à la place de Marc',
        isDense: true,
        filled: true,
        fillColor: AppColors.surface2(isDark).withValues(
          alpha: isDark ? AppOpacity.inputFillDark : AppOpacity.inputFillLight,
        ),
        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: muted.withValues(alpha: 0.45),
            ),
        contentPadding: EdgeInsets.fromLTRB(14, 12, showSend ? 4 : 14, 12),
        suffixIcon: showSend
            ? ConfidiaTooltip(
                message: 'Envoyer',
                child: IconButton(
                  icon: Icon(Icons.arrow_upward_rounded, size: 18, color: context.palette.primary),
                  onPressed: enabled ? onSend : null,
                  mouseCursor: SystemMouseCursors.click,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        border: AppBorders.input(isDark: isDark),
        enabledBorder: AppBorders.input(isDark: isDark),
        focusedBorder: AppBorders.input(
          isDark: isDark,
          accent: context.palette.primary.withValues(alpha: AppOpacity.borderFocus),
          width: AppBorders.focus,
        ),
      ),
    );
  }
}

class _ConflictTile extends StatelessWidget {
  final PlanningConflict conflict;

  const _ConflictTile({required this.conflict});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final high = conflict.severity == 'high';
    final accent = high ? ConfidiaColors.error : ConfidiaColors.warning;
    final muted = ConfidiaColors.textSecondary(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        color: AppColors.surface2(isDark).withValues(alpha: isDark ? 0.55 : 0.7),
        border: Border.all(color: accent.withValues(alpha: isDark ? 0.28 : 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                high ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conflict.title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (conflict.events.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final e in conflict.events)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  e,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted, height: 1.35),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
