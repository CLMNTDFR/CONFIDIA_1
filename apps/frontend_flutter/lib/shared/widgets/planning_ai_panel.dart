import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/models/access_control_models.dart';
import 'ai_streaming_text.dart';
import 'cofid_ia_brand.dart';
import 'confidia_glow_button.dart';
import 'confidia_text_field.dart';
import 'glass_card.dart';

class PlanningAiPanel extends StatefulWidget {
  final PlanningProposal? proposal;
  final bool loading;
  final VoidCallback onAnalyze;
  final VoidCallback onRegenerate;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final void Function(String prompt) onRefine;
  final String analyzeLabel;

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
  });

  @override
  State<PlanningAiPanel> createState() => _PlanningAiPanelState();
}

class _PlanningAiPanelState extends State<PlanningAiPanel> {
  final _refineCtrl = TextEditingController();
  bool _streaming = false;
  bool _refineVisible = false;
  bool _hasRefineText = false;
  int _streamKey = 0;

  @override
  void initState() {
    super.initState();
    _refineCtrl.addListener(_onRefineTextChanged);
  }

  void _onRefineTextChanged() {
    final hasText = _refineCtrl.text.isNotEmpty;
    if (hasText != _hasRefineText) setState(() => _hasRefineText = hasText);
  }

  @override
  void dispose() {
    _refineCtrl.removeListener(_onRefineTextChanged);
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
      });
    }
  }

  void _submitRefine() {
    final prompt = _refineCtrl.text.trim();
    if (prompt.isEmpty || widget.loading) return;
    widget.onRefine(prompt);
  }

  @override
  Widget build(BuildContext context) {
    final proposal = widget.proposal;
    final hasResult = proposal != null;
    final isActive = widget.loading || _streaming;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CofidIaPanelHeader(
            speaking: isActive,
            subtitle: hasResult
                ? null
                : 'Détecte les conflits et propose des réajustements sur l\'agenda affiché.',
          ),
          if (!hasResult) ...[
            const SizedBox(height: 14),
            ConfidiaGlowButton(
              label: widget.loading ? 'Analyse en cours…' : widget.analyzeLabel,
              icon: Icons.psychology_rounded,
              expand: true,
              onPressed: widget.loading ? null : widget.onAnalyze,
            ),
            if (widget.loading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
          if (hasResult) ...[
            const SizedBox(height: ConfidiaSpacing.md),
            if (proposal.conflicts.isNotEmpty) ...[
              ...proposal.conflicts.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
                  child: _ConflictTile(conflict: c),
                ),
              ),
              const SizedBox(height: ConfidiaSpacing.sm),
            ],
            Divider(
              height: 1,
              color: ConfidiaColors.border(Theme.of(context).brightness == Brightness.dark).withValues(alpha: 0.45),
            ),
            const SizedBox(height: ConfidiaSpacing.sm),
            AiStreamingText(
              key: ValueKey(_streamKey),
              text: proposal.proposal,
              showThinkingRobot: false,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.55),
              onStreamStart: () => setState(() => _streaming = true),
              onComplete: () => setState(() => _streaming = false),
            ),
            if (proposal.alternatives.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Alternatives', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ...proposal.alternatives.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('• $a', style: Theme.of(context).textTheme.labelSmall),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                _ProposalIconButton(
                  icon: Icons.check_rounded,
                  tooltip: 'Accepter',
                  primary: true,
                  onPressed: widget.onAccept,
                ),
                const SizedBox(width: 6),
                _ProposalIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Refuser',
                  onPressed: widget.onReject,
                ),
                const SizedBox(width: 6),
                _ProposalIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Nouvelle proposition',
                  onPressed: widget.loading ? null : widget.onRegenerate,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ConfidiaGlowButton(
                    label: 'Ajuster',
                    icon: Icons.tune_rounded,
                    primary: _refineVisible,
                    expand: true,
                    onPressed: widget.loading
                        ? null
                        : () => setState(() => _refineVisible = true),
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _refineVisible ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: ConfidiaSpacing.sm),
                child: _RefinePromptField(
                  controller: _refineCtrl,
                  enabled: !widget.loading,
                  showSend: _hasRefineText,
                  onSend: _submitRefine,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProposalIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool primary;

  const _ProposalIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            width: 40,
            height: 40,
            decoration: primary
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: enabled
                          ? [
                              context.palette.primary.withValues(alpha: 0.92),
                              context.palette.secondary.withValues(alpha: 0.78),
                            ]
                          : [
                              context.palette.primary.withValues(alpha: 0.4),
                              context.palette.secondary.withValues(alpha: 0.35),
                            ],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: enabled ? 0.18 : 0.08)),
                  )
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                    border: Border.all(color: ConfidiaColors.border(isDark).withValues(alpha: 0.65)),
                  ),
            child: Icon(
              icon,
              size: 20,
              color: primary
                  ? Colors.white.withValues(alpha: enabled ? 1 : 0.6)
                  : (enabled ? context.palette.primary : ConfidiaColors.textSecondary(isDark)),
            ),
          ),
        ),
      ),
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

    return TextFormField(
      controller: controller,
      enabled: enabled,
      minLines: 1,
      maxLines: 6,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: ConfidiaTextFormField.fieldStyle(context),
      onFieldSubmitted: (_) => onSend(),
      decoration: InputDecoration(
        hintText: 'Ex : Sophie récupère Léa à la place de Marc',
        isDense: true,
        filled: true,
        fillColor: isDark
            ? ConfidiaColors.darkSurfaceElevated.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.92),
        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: ConfidiaColors.textSecondary(isDark),
            ),
        contentPadding: EdgeInsets.fromLTRB(14, 12, showSend ? 4 : 14, 12),
        prefixIcon: Icon(Icons.edit_rounded, size: 18, color: ConfidiaColors.textSecondary(isDark)),
        prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 38),
        suffixIcon: showSend
            ? IconButton(
                tooltip: 'Envoyer',
                icon: Icon(Icons.send_rounded, size: 18, color: context.palette.primary),
                onPressed: enabled ? onSend : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: ConfidiaColors.border(isDark).withValues(alpha: 0.75)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: ConfidiaColors.border(isDark).withValues(alpha: 0.75)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: context.palette.primary.withValues(alpha: 0.55), width: 1.5),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: context.palette.primary.withValues(alpha: 0.04),
        border: Border.all(color: context.palette.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                conflict.severity == 'high' ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                size: 16,
                color: conflict.severity == 'high' ? ConfidiaColors.error : ConfidiaColors.warning,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(conflict.title, style: Theme.of(context).textTheme.labelLarge)),
            ],
          ),
          const SizedBox(height: 4),
          ...conflict.events.map((e) => Text('• $e', style: Theme.of(context).textTheme.labelSmall)),
        ],
      ),
    );
  }
}
