import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';
import 'cofid_ia_brand.dart';
import 'confidia_ai_robot.dart';
import 'confidia_animated_logo.dart';

/// Profil de vitesse : connexion (boucle modérée) vs chargement post-login.
enum LogoTransitionProfile { connection, welcome }

/// Overlay de chargement post-login ou pendant la connexion.
class LogoAuthTransition extends StatefulWidget {
  final bool active;
  final String? subtitle;
  final VoidCallback? onComplete;
  final bool loopUntilInactive;
  final LogoTransitionProfile profile;

  const LogoAuthTransition({
    super.key,
    required this.active,
    this.subtitle,
    this.onComplete,
    this.loopUntilInactive = true,
    this.profile = LogoTransitionProfile.connection,
  });

  @override
  State<LogoAuthTransition> createState() => _LogoAuthTransitionState();
}

class _LogoAuthTransitionState extends State<LogoAuthTransition>
    with TickerProviderStateMixin {
  late final AnimationController _main;
  late final AnimationController _breathe;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _heroOpacity;
  late final Animation<double> _heroRise;
  late final Animation<double> _heroScale;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _brandOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _textRise;
  late final Animation<double> _progress;
  late final Animation<double> _exitOpacity;
  bool _completing = false;
  bool _completeFired = false;

  bool get _isWelcome => widget.profile == LogoTransitionProfile.welcome;

  Duration get _cycleDuration => _isWelcome
      ? const Duration(milliseconds: 3200)
      : const Duration(milliseconds: 2400);

  @override
  void initState() {
    super.initState();
    _main = AnimationController(vsync: this, duration: _cycleDuration);
    _breathe = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _buildAnimations();
    _main.addStatusListener(_onMainStatus);
    if (widget.active) _startCycle();
  }

  void _buildAnimations() {
    if (_isWelcome) {
      // Quiet Settle: scène fixe, pas de bascule speaking / bulle.
      _heroOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _main, curve: const Interval(0.0, 0.18, curve: Curves.easeOutCubic)),
      );
      _heroRise = Tween<double>(begin: 14, end: 0).animate(
        CurvedAnimation(parent: _main, curve: const Interval(0.0, 0.2, curve: Curves.easeOutCubic)),
      );
      _heroScale = Tween<double>(begin: 0.92, end: 1).animate(
        CurvedAnimation(parent: _main, curve: const Interval(0.0, 0.2, curve: Curves.easeOutCubic)),
      );
      _glowOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _main, curve: const Interval(0.04, 0.22, curve: Curves.easeOut)),
      );
      _brandOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _main, curve: const Interval(0.14, 0.32, curve: Curves.easeOut)),
      );
      _textOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _main, curve: const Interval(0.2, 0.38, curve: Curves.easeOut)),
      );
      _textRise = Tween<double>(begin: 8, end: 0).animate(
        CurvedAnimation(parent: _main, curve: const Interval(0.2, 0.38, curve: Curves.easeOutCubic)),
      );
      _progress = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _main, curve: const Interval(0.24, 0.84, curve: Curves.easeInOutCubic)),
      );
      _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _main, curve: const Interval(0.86, 1.0, curve: Curves.easeIn)),
      );

      // Unused on welcome; keep valid animations for connection branch reuse.
      _logoScale = const AlwaysStoppedAnimation(1);
      _logoOpacity = const AlwaysStoppedAnimation(0);
    } else {
      _logoScale = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.5, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 30,
        ),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.9).chain(CurveTween(curve: Curves.easeInCubic)),
          weight: 20,
        ),
      ]).animate(_main);

      _logoOpacity = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
          weight: 22,
        ),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 58),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 20,
        ),
      ]).animate(_main);

      _heroOpacity = const AlwaysStoppedAnimation(0);
      _heroRise = const AlwaysStoppedAnimation(0);
      _heroScale = const AlwaysStoppedAnimation(1);
      _glowOpacity = const AlwaysStoppedAnimation(0);
      _brandOpacity = const AlwaysStoppedAnimation(0);
      _textOpacity = const AlwaysStoppedAnimation(0);
      _textRise = const AlwaysStoppedAnimation(0);
      _progress = const AlwaysStoppedAnimation(0);
      _exitOpacity = const AlwaysStoppedAnimation(1);
    }
  }

  @override
  void didUpdateWidget(LogoAuthTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _completing = false;
      _completeFired = false;
      _startCycle();
    } else if (!widget.active && oldWidget.active && !_completing) {
      _finishAndExit();
    }
  }

  void _onMainStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_completing || !widget.loopUntilInactive) {
      _fireComplete();
      return;
    }
    if (widget.active) {
      _main.forward(from: 0.32);
    }
  }

  void _fireComplete() {
    if (_completeFired) return;
    _completeFired = true;
    widget.onComplete?.call();
  }

  void _startCycle() {
    _completeFired = false;
    _main.forward(from: 0);
    if (_isWelcome) {
      _breathe.repeat(reverse: true);
    } else {
      _breathe.stop();
      _breathe.value = 0;
    }
  }

  void _finishAndExit() {
    _completing = true;
    final exitMs = _isWelcome ? 420 : 700;
    _main.animateTo(1.0, duration: Duration(milliseconds: exitMs), curve: Curves.easeInCubic);
  }

  @override
  void dispose() {
    _main.removeStatusListener(_onMainStatus);
    _main.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active && !_completing) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AbsorbPointer(
      child: AnimatedOpacity(
        opacity: widget.active || _completing ? 1 : 0,
        duration: Duration(milliseconds: _isWelcome ? 280 : 400),
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: ColoredBox(
                    color: AppColors.surface0(isDark).withValues(
                      alpha: isDark ? AppOpacity.veilDark : AppOpacity.veilLight,
                    ),
                  ),
                ),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_main, _breathe]),
                  builder: (context, _) {
                    if (_isWelcome) {
                      return _buildWelcomeContent(context, isDark, reduceMotion);
                    }
                    return _buildConnectionContent(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeContent(BuildContext context, bool isDark, bool reduceMotion) {
    final message = widget.subtitle ?? 'Chargement de votre espace…';
    final palette = context.palette;
    final breathe = reduceMotion ? 0.35 : _breathe.value;
    final glowPulse = 0.55 + breathe * 0.45;
    final sceneOpacity = _exitOpacity.value;

    // Empreinte fixe : jamais de recalcul mid-scene (plus de speaking on/off).
    const robotSize = 64.0;
    const glowPad = 36.0;
    const stageSize = robotSize + glowPad * 2;

    return Opacity(
      opacity: sceneOpacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: stageSize,
              height: stageSize,
              child: Opacity(
                opacity: _heroOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, _heroRise.value),
                  child: Transform.scale(
                    scale: _heroScale.value,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Opacity(
                          opacity: _glowOpacity.value * glowPulse,
                          child: Container(
                            width: robotSize * 1.15,
                            height: robotSize * 1.15,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: palette.primary.withValues(alpha: isDark ? 0.28 : 0.18),
                                  blurRadius: 28 + breathe * 8,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: palette.secondary.withValues(alpha: isDark ? 0.18 : 0.12),
                                  blurRadius: 18,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const ConfidiaAiRobot(size: robotSize, speaking: false),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: Opacity(
                opacity: _brandOpacity.value,
                child: const Center(child: CofidIaBrand(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: Opacity(
                opacity: _textOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, _textRise.value),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.82)
                                : ConfidiaColors.lightTextPrimary.withValues(alpha: 0.78),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            height: 1.4,
                          ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 196,
              height: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    ),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress.value.clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [palette.primary, palette.secondary],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.xl),
      child: Opacity(
        opacity: _logoOpacity.value,
        child: Transform.scale(
          scale: _logoScale.value,
          child: const ConfidiaAnimatedLogo(size: 56, showText: true),
        ),
      ),
    );
  }
}