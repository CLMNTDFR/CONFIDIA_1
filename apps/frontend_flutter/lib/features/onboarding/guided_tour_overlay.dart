import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/widgets/confidia_ai_robot.dart';
import '../../shared/widgets/cofid_ia_brand.dart';
import 'guided_tour_demo.dart';
import 'guided_tour_provider.dart';
import 'onboarding_targets.dart';

/// Overlay spotlight + bulle Confid•IA pour la visite guidée.
class GuidedTourOverlay extends ConsumerStatefulWidget {
  const GuidedTourOverlay({super.key});

  @override
  ConsumerState<GuidedTourOverlay> createState() => _GuidedTourOverlayState();
}

class _GuidedTourOverlayState extends ConsumerState<GuidedTourOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _holeCtrl;
  late final AnimationController _bubbleCtrl;

  Rect? _holeFrom;
  Rect? _holeTo;
  double? _bubbleTop;
  double? _bubbleTopFrom;
  double? _bubbleLeft;
  bool _centeredBubble = true;
  bool _besideHole = false;
  bool _speaking = true;
  bool _isFirstEntrance = true;
  int _stepGeneration = 0;

  static const _stepAnim = Duration(milliseconds: 300);
  static const _entranceAnim = Duration(milliseconds: 520);
  static const _routeSettle = Duration(milliseconds: 380);

  @override
  void initState() {
    super.initState();
    _holeCtrl = AnimationController(vsync: this, duration: _stepAnim);
    _bubbleCtrl = AnimationController(vsync: this, duration: _entranceAnim);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onStepChanged(animate: false));
  }

  @override
  void dispose() {
    _holeCtrl.dispose();
    _bubbleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GuidedTourState>(guidedTourProvider, (prev, next) {
      if (prev?.active == true && !next.active) {
        GuidedTourDemo.onTourEnded(ref);
        return;
      }
      if (prev?.stepIndex != next.stepIndex || prev?.active != next.active) {
        _onStepChanged(animate: prev?.active == true && next.active);
      }
    });

    final tour = ref.watch(guidedTourProvider);
    final step = tour.currentStep;
    if (!tour.active || step == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([_holeCtrl, _bubbleCtrl]),
        builder: (context, _) {
          final hole = _lerpHole(_holeCtrl.value);
          final t = Curves.easeOutCubic.transform(_bubbleCtrl.value);
          final bubbleOpacity = t;
          final bubbleSlide = (1 - t) * (_isFirstEntrance ? 18 : 10);
          final bubbleScale = _isFirstEntrance ? (0.92 + 0.08 * t) : 1.0;

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: CustomPaint(
                    painter: _SpotlightPainter(
                      hole: hole,
                      scrimColor: Colors.black.withValues(alpha: isDark ? 0.62 : 0.48),
                      borderColor: context.palette.primary.withValues(alpha: 0.45),
                      glowColor: context.palette.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
              _buildBubbleSlot(
                context: context,
                step: step,
                tour: tour,
                screenSize: size,
                safePadding: padding,
                opacity: bubbleOpacity,
                slide: bubbleSlide,
                scale: bubbleScale,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onStepChanged({required bool animate}) async {
    final generation = ++_stepGeneration;
    if (!mounted) return;
    setState(() => _speaking = true);

    if (animate && _bubbleCtrl.value > 0) {
      _bubbleCtrl.duration = _stepAnim;
      await _bubbleCtrl.reverse();
      if (!mounted || generation != _stepGeneration) return;
    } else {
      _bubbleCtrl.value = 0;
    }

    final step = ref.read(guidedTourProvider).currentStep;
    if (step == null) return;

    await _ensureRoute(step.route);
    if (!mounted || generation != _stepGeneration) return;

    if (step.demoAction == GuidedTourDemoAction.initThemes) {
      ref.read(guidedTourProvider.notifier).initThemes();
    }

    if (step.demoAction == GuidedTourDemoAction.prepareAccess ||
        step.demoAction == GuidedTourDemoAction.prepareMembers ||
        step.route == '/access-control') {
      await GuidedTourDemo.run(
        ref,
        step.demoAction == GuidedTourDemoAction.prepareMembers
            ? GuidedTourDemoAction.prepareMembers
            : GuidedTourDemoAction.prepareAccess,
      );
      if (!mounted || generation != _stepGeneration) return;
    }

    await _measureAndPlace(animate: animate || !_isFirstEntrance);
    if (!mounted || generation != _stepGeneration) return;

    _bubbleCtrl.duration = _isFirstEntrance ? _entranceAnim : _stepAnim;
    await _bubbleCtrl.forward(from: 0);
    if (!mounted || generation != _stepGeneration) return;

    if (_isFirstEntrance) {
      setState(() => _isFirstEntrance = false);
    }

    if (step.demoAction == GuidedTourDemoAction.demoStructures) {
      unawaited(GuidedTourDemo.run(ref, GuidedTourDemoAction.demoStructures));
    }
  }

  Future<void> _ensureRoute(String? route) async {
    if (route == null || !mounted) return;
    final router = GoRouter.of(context);
    final current = GoRouterState.of(context).matchedLocation;
    if (current == route) return;
    router.go(route);
    await Future<void>.delayed(_routeSettle);
    if (!mounted) return;
    // Laisse un frame pour monter les GlobalKeys de la nouvelle page.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  Future<void> _measureAndPlace({required bool animate}) async {
    final step = ref.read(guidedTourProvider).currentStep;
    if (step == null) return;

    final key = step.targetKeyFor(context);
    Rect? target;

    // Retry léger si la page vient de changer (clés pas encore montées).
    for (var attempt = 0; attempt < 4 && key != null; attempt++) {
      if (key.currentContext != null) break;
      await Future<void>.delayed(Duration(milliseconds: 60 + attempt * 40));
      if (!mounted || !context.mounted) return;
    }

    if (key?.currentContext != null) {
      final ctx = key!.currentContext!;
      final scrollable = Scrollable.maybeOf(ctx);
      if (scrollable != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: animate ? const Duration(milliseconds: 260) : Duration.zero,
          curve: Curves.easeOutCubic,
          alignment: 0.18,
        );
        if (!mounted || !context.mounted) return;
      }
      target = _rectForKey(key);
    }

    if (!context.mounted) return;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final alignment = step.bubbleAlignmentFor(context);
    final beside = alignment == Alignment.centerRight && target != null;
    final nextTop = _computeBubbleTop(
      hole: target,
      preferBelow: alignment == Alignment.bottomCenter,
      beside: beside,
      screenSize: size,
      safePadding: padding,
    );
    final nextLeft = beside ? target.right + 16 : null;
    final nextCentered = target == null;

    setState(() {
      _holeFrom = _currentHole();
      _holeTo = target;
      _bubbleTopFrom = _bubbleTop;
      _bubbleTop = nextTop;
      _bubbleLeft = nextLeft;
      _centeredBubble = nextCentered;
      _besideHole = beside;
    });

    if (animate && (_holeFrom != _holeTo || _bubbleTopFrom != _bubbleTop)) {
      _holeCtrl.forward(from: 0);
    } else {
      _holeCtrl.value = 1;
      _holeFrom = _holeTo;
    }
  }

  Rect? _rectForKey(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, box.size.width, box.size.height)
        .inflate(6)
        .intersect(Offset.zero & MediaQuery.sizeOf(context));
  }

  Rect? _currentHole() {
    if (_holeCtrl.isAnimating || _holeCtrl.value < 1) {
      return _lerpHole(_holeCtrl.value);
    }
    return _holeTo;
  }

  Rect? _lerpHole(double t) {
    final from = _holeFrom;
    final to = _holeTo;
    if (from == null && to == null) return null;
    if (from == null) return Rect.lerp(to!.deflate(12), to, t);
    if (to == null) {
      // Pas de cible (ex. retour accueil) : fermer le spotlight, pas de trou résiduel.
      if (t >= 1) return null;
      final collapsed = Rect.fromCenter(center: from.center, width: 0, height: 0);
      return Rect.lerp(from, collapsed, Curves.easeInOutCubic.transform(t));
    }
    return Rect.lerp(from, to, Curves.easeInOutCubic.transform(t));
  }

  double _computeBubbleTop({
    required Rect? hole,
    required bool preferBelow,
    required bool beside,
    required Size screenSize,
    required EdgeInsets safePadding,
  }) {
    const bubbleApproxHeight = 200.0;
    const gap = 12.0;
    final minTop = safePadding.top + 8;
    final maxTop = screenSize.height - safePadding.bottom - bubbleApproxHeight;

    if (hole == null) {
      return ((screenSize.height - bubbleApproxHeight) / 2).clamp(minTop, maxTop);
    }

    if (beside) {
      final centered = hole.center.dy - bubbleApproxHeight / 2;
      return centered.clamp(minTop, maxTop);
    }

    double top;
    if (preferBelow) {
      top = hole.bottom + gap;
      if (top + bubbleApproxHeight > screenSize.height - safePadding.bottom - 12) {
        top = hole.top - gap - bubbleApproxHeight;
      }
    } else {
      top = hole.top - gap - bubbleApproxHeight;
      if (top < minTop) top = hole.bottom + gap;
    }
    return top.clamp(minTop, maxTop);
  }

  Widget _buildBubbleSlot({
    required BuildContext context,
    required GuidedTourStep step,
    required GuidedTourState tour,
    required Size screenSize,
    required EdgeInsets safePadding,
    required double opacity,
    required double slide,
    required double scale,
  }) {
    final t = Curves.easeInOutCubic.transform(_holeCtrl.value);
    final top = _bubbleTopFrom == null || _bubbleTop == null
        ? (_bubbleTop ?? (screenSize.height / 2 - 100))
        : lerpDouble(_bubbleTopFrom!, _bubbleTop!, t)!;

    final bubble = Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: _TourSpeechBubble(
            key: ValueKey('${step.id}_${OnboardingTargets.isWideLayout(context)}'),
            message: step.messageFor(context),
            stepIndex: tour.stepIndex,
            totalSteps: tour.totalSteps,
            isLast: tour.isLastStep,
            speaking: _speaking,
            emphasizeEntrance: step.id == GuidedTourStepId.welcome,
            themeBrowser: step.isThemeBrowser
                ? _ThemeBrowserData(
                    index: tour.themeIndex,
                    label: tour.currentThemeLabel,
                    seenCount: tour.themesSeenCount,
                    total: guidedTourThemeCombos.length,
                    allSeen: tour.allThemesSeen,
                    onPrevious: () => ref.read(guidedTourProvider.notifier).previousTheme(),
                    onNext: () => ref.read(guidedTourProvider.notifier).nextTheme(),
                  )
                : null,
            canProceed: tour.canProceedFromCurrentStep(),
            onSpeakingDone: () {
              if (mounted) setState(() => _speaking = false);
            },
            onNext: () => ref.read(guidedTourProvider.notifier).next(),
            onSkip: () => ref.read(guidedTourProvider.notifier).skip(),
          ),
        ),
      ),
    );

    if (_centeredBubble && _holeTo == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.lg),
          child: bubble,
        ),
      );
    }

    if (_besideHole && _bubbleLeft != null) {
      return Positioned(
        left: _bubbleLeft,
        right: ConfidiaSpacing.lg,
        top: top,
        child: Align(alignment: Alignment.topLeft, child: bubble),
      );
    }

    return Positioned(
      left: ConfidiaSpacing.md,
      right: ConfidiaSpacing.md,
      top: top,
      child: bubble,
    );
  }
}

class _ThemeBrowserData {
  final int index;
  final String label;
  final int seenCount;
  final int total;
  final bool allSeen;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _ThemeBrowserData({
    required this.index,
    required this.label,
    required this.seenCount,
    required this.total,
    required this.allSeen,
    required this.onPrevious,
    required this.onNext,
  });
}

class _TourSpeechBubble extends StatefulWidget {
  final String message;
  final int stepIndex;
  final int totalSteps;
  final bool isLast;
  final bool speaking;
  final bool emphasizeEntrance;
  final _ThemeBrowserData? themeBrowser;
  final bool canProceed;
  final VoidCallback onSpeakingDone;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TourSpeechBubble({
    super.key,
    required this.message,
    required this.stepIndex,
    required this.totalSteps,
    required this.isLast,
    required this.speaking,
    this.emphasizeEntrance = false,
    this.themeBrowser,
    this.canProceed = true,
    required this.onSpeakingDone,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<_TourSpeechBubble> createState() => _TourSpeechBubbleState();
}

class _TourSpeechBubbleState extends State<_TourSpeechBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _contentCtrl;

  @override
  void initState() {
    super.initState();
    _contentCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.emphasizeEntrance ? 480 : 280),
    )..forward().whenComplete(() {
        if (mounted) widget.onSpeakingDone();
      });
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;
    final robotFade = CurvedAnimation(
      parent: _contentCtrl,
      curve: widget.emphasizeEntrance
          ? const Interval(0.0, 0.55, curve: Curves.easeOutCubic)
          : Curves.easeOut,
    );
    final textFade = CurvedAnimation(
      parent: _contentCtrl,
      curve: widget.emphasizeEntrance
          ? const Interval(0.28, 1.0, curve: Curves.easeOutCubic)
          : Curves.easeOut,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF16161F).withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.primary.withValues(alpha: isDark ? 0.24 : 0.14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeTransition(
                  opacity: robotFade,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, widget.emphasizeEntrance ? 0.12 : 0.04),
                      end: Offset.zero,
                    ).animate(robotFade),
                    child: Row(
                      children: [
                        ConfidiaAiRobot(size: 36, speaking: widget.speaking),
                        const SizedBox(width: 8),
                        const Expanded(child: CofidIaBrand(fontSize: 14)),
                        Text(
                          '${widget.stepIndex + 1}/${widget.totalSteps}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: ConfidiaColors.textSecondary(isDark),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: textFade,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(textFade),
                    child: Text(
                      widget.message,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        letterSpacing: 0.1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.92)
                            : ConfidiaColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ),
                if (widget.themeBrowser != null) ...[
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: textFade,
                    child: _ThemeBrowserControls(data: widget.themeBrowser!, isDark: isDark),
                  ),
                ],
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: textFade,
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: widget.onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: ConfidiaColors.textSecondary(isDark),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Passer'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: widget.canProceed ? widget.onNext : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: palette.primary.withValues(alpha: 0.28),
                          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(widget.isLast ? 'Terminer' : 'Suivant'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeBrowserControls extends StatelessWidget {
  final _ThemeBrowserData data;
  final bool isDark;

  const _ThemeBrowserControls({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        border: Border.all(color: ConfidiaColors.border(isDark)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ThemeNavButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Thème précédent',
                onTap: data.onPrevious,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    data.label,
                    key: ValueKey(data.index),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.primary,
                        ),
                  ),
                ),
              ),
              _ThemeNavButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Thème suivant',
                onTap: data.onNext,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(data.total, (i) {
              final active = i == data.index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 16 : 6,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: active
                      ? palette.primary
                      : ConfidiaColors.textSecondary(isDark).withValues(alpha: 0.35),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            data.allSeen
                ? 'Les 4 ambiances ont été parcourues'
                : '${data.seenCount}/${data.total} ambiances découvertes',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ConfidiaColors.textSecondary(isDark),
                ),
          ),
        ],
      ),
    );
  }
}

class _ThemeNavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ThemeNavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: palette.primary.withValues(alpha: isDark ? 0.16 : 0.1),
              border: Border.all(color: palette.primary.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, size: 22, color: palette.primary),
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final Color scrimColor;
  final Color borderColor;
  final Color glowColor;

  _SpotlightPainter({
    required this.hole,
    required this.scrimColor,
    required this.borderColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hole == null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = scrimColor);
      return;
    }

    final rrect = RRect.fromRectAndRadius(hole!, const Radius.circular(16));
    final cut = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(cut, Paint()..color = scrimColor);

    // Halo très léger, juste pour lire le contour sans éclairer la zone.
    canvas.drawRRect(
      rrect.inflate(1),
      Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.hole != hole ||
        oldDelegate.scrimColor != scrimColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.glowColor != glowColor;
  }
}
