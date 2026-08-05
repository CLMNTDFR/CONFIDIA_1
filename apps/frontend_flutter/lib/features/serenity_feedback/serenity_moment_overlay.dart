import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/utils/serenity_palette.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/serenity_score_ring.dart';
import 'serenity_moment.dart';
import 'serenity_moments_provider.dart';

/// Overlay ou toast riche pour un moment de sérénité.
class SerenityMomentOverlay extends ConsumerWidget {
  const SerenityMomentOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moment = ref.watch(serenityMomentsProvider.select((s) => s.current));
    if (moment == null) return const SizedBox.shrink();
    if (moment.useOverlay) {
      return _SerenityOverlayCard(key: ObjectKey(moment), moment: moment);
    }
    return _SerenityAutoToast(key: ObjectKey(moment), moment: moment);
  }
}

class _SerenityAutoToast extends ConsumerStatefulWidget {
  final SerenityMoment moment;

  const _SerenityAutoToast({super.key, required this.moment});

  @override
  ConsumerState<_SerenityAutoToast> createState() => _SerenityAutoToastState();
}

class _SerenityAutoToastState extends ConsumerState<_SerenityAutoToast> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 3200), _dismissIfSame);
  }

  @override
  void didUpdateWidget(covariant _SerenityAutoToast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moment != widget.moment) {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 3200), _dismissIfSame);
    }
  }

  void _dismissIfSame() {
    if (!mounted) return;
    if (ref.read(serenityMomentsProvider).current == widget.moment) {
      ref.read(serenityMomentsProvider.notifier).dismissCurrent();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = SerenityPalette.excellent;
    final moment = widget.moment;

    return Positioned(
      left: ConfidiaSpacing.md,
      right: ConfidiaSpacing.md,
      bottom: 88,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2E24) : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.shield_rounded, color: accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        moment.title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        moment.body,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ConfidiaColors.textSecondary(isDark),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ref.read(serenityMomentsProvider.notifier).dismissCurrent(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SerenityOverlayCard extends ConsumerStatefulWidget {
  final SerenityMoment moment;

  const _SerenityOverlayCard({super.key, required this.moment});

  @override
  ConsumerState<_SerenityOverlayCard> createState() => _SerenityOverlayCardState();
}

class _SerenityOverlayCardState extends ConsumerState<_SerenityOverlayCard>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _count;
  late final AnimationController _glow;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _scoreTween;

  @override
  void initState() {
    super.initState();
    final before = (widget.moment.scoreBefore ?? widget.moment.scoreAfter ?? 0).toDouble();
    final after = (widget.moment.scoreAfter ?? before).toDouble();

    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _count = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _enter, curve: Curves.easeOutBack),
    );
    _scoreTween = Tween<double>(begin: before, end: after).animate(
      CurvedAnimation(parent: _count, curve: Curves.easeOutCubic),
    );

    _enter.forward();
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _count.forward();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _count.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moment = widget.moment;
    final score = moment.scoreAfter ?? 0;
    // État de l'indice (rouge <50) ≠ signal de réussite (toujours vert).
    final scoreColor = SerenityPalette.forScore(score, palette: context.palette);
    const successColor = SerenityPalette.excellent;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final delta = moment.delta ?? math.max(0, score - (moment.scoreBefore ?? score));
    final isCongrats = moment.kind == SerenityMomentKind.congratulations;
    // Cadre / glow : réussite (vert), sauf félicitations haut score déjà « excellent ».
    final frameColor = successColor;

    return Positioned.fill(
      child: FadeTransition(
        opacity: reduceMotion ? const AlwaysStoppedAnimation(1) : _fade,
        child: Material(
          color: Colors.black.withValues(alpha: 0.58),
          child: Center(
            child: ScaleTransition(
              scale: reduceMotion ? const AlwaysStoppedAnimation(1) : _scale,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.all(ConfidiaSpacing.lg),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_glow, _count]),
                    builder: (context, child) {
                      final glowT = reduceMotion ? 0.35 : _glow.value;
                      final displayScore = reduceMotion
                          ? score
                          : _scoreTween.value.round().clamp(0, 100);
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: isDark ? ConfidiaColors.darkSurfaceElevated : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: frameColor.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: frameColor.withValues(alpha: 0.18 + glowT * 0.14),
                              blurRadius: 32 + glowT * 12,
                              spreadRadius: glowT * 2,
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SerenityScoreRing(
                                score: displayScore,
                                label: isCongrats ? 'Excellent' : 'Indice',
                                color: scoreColor,
                                size: 88,
                                scoreFontSize: 28,
                                labelFontSize: 12,
                                pulse: reduceMotion ? null : _glow,
                                animateFromZero: false,
                              ),
                              const SizedBox(height: 10),
                              _DeltaBadge(delta: delta, successColor: successColor),
                              const SizedBox(height: 16),
                              Text(
                                moment.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                moment.body,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: ConfidiaColors.textSecondary(isDark),
                                      height: 1.4,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              ConfidiaGlowButton(
                                label: 'Continuer',
                                icon: Icons.check_rounded,
                                expand: true,
                                onPressed: () =>
                                    ref.read(serenityMomentsProvider.notifier).dismissCurrent(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final int delta;
  final Color successColor;

  const _DeltaBadge({required this.delta, required this.successColor});

  @override
  Widget build(BuildContext context) {
    if (delta <= 0) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: successColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: successColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.trending_up_rounded, size: 14, color: successColor),
            const SizedBox(width: 6),
            Text(
              '+$delta points de sérénité',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: successColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
