import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import 'confidia_logo.dart';

/// Profil de vitesse : connexion (boucle modérée) vs accueil (4,5 s).
enum LogoTransitionProfile { connection, welcome }

/// Animation fluide du logo CONFIDIA : apparition, respiration, disparition.
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

class _LogoAuthTransitionState extends State<LogoAuthTransition> with TickerProviderStateMixin {
  late final AnimationController _main;
  late final AnimationController _ring;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _glowPulse;
  bool _completing = false;
  bool _completeFired = false;

  bool get _isWelcome => widget.profile == LogoTransitionProfile.welcome;

  Duration get _cycleDuration => _isWelcome
      ? const Duration(milliseconds: 4500)
      : const Duration(milliseconds: 2400);

  Duration get _ringDuration => _isWelcome
      ? const Duration(milliseconds: 6000)
      : const Duration(milliseconds: 5000);

  @override
  void initState() {
    super.initState();
    _main = AnimationController(vsync: this, duration: _cycleDuration);
    _ring = AnimationController(vsync: this, duration: _ringDuration)..repeat();

    if (_isWelcome) {
      _logoScale = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.6, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 25,
        ),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 45),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.92).chain(CurveTween(curve: Curves.easeInCubic)),
          weight: 30,
        ),
      ]).animate(_main);

      _logoOpacity = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
          weight: 22,
        ),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 48),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 30,
        ),
      ]).animate(_main);

      _subtitleOpacity = TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween(0.0), weight: 18),
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
          weight: 12,
        ),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 30,
        ),
      ]).animate(_main);
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

      _subtitleOpacity = TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween(0.0), weight: 18),
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
          weight: 12,
        ),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 20,
        ),
      ]).animate(_main);
    }

    _glowPulse = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _ring, curve: Curves.easeInOut),
    );

    _main.addStatusListener(_onMainStatus);
    if (widget.active) _startCycle();
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
  }

  void _finishAndExit() {
    _completing = true;
    final exitMs = _isWelcome ? 500 : 700;
    _main.animateTo(1.0, duration: Duration(milliseconds: exitMs), curve: Curves.easeInCubic);
  }

  @override
  void dispose() {
    _main.removeStatusListener(_onMainStatus);
    _main.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active && !_completing) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AbsorbPointer(
      child: AnimatedOpacity(
        opacity: widget.active || _completing ? 1 : 0,
        duration: Duration(milliseconds: _isWelcome ? 250 : 400),
        child: SizedBox.expand(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: ColoredBox(
                color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.88),
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_main, _ring]),
                    builder: (context, _) {
                      final breathe = 1 + math.sin(_ring.value * math.pi * 2) * 0.02;
                      final ringAngle = _ring.value * 2 * math.pi;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform.scale(
                                scale: _logoScale.value * breathe,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Transform.rotate(
                                      angle: ringAngle,
                                      child: Container(
                                        width: 168,
                                        height: 168,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: SweepGradient(
                                            colors: [
                                              ConfidiaColors.primary.withValues(alpha: _glowPulse.value * 0.12),
                                              ConfidiaColors.secondary.withValues(alpha: _glowPulse.value * 0.5),
                                              ConfidiaColors.accent.withValues(alpha: _glowPulse.value * 0.3),
                                              ConfidiaColors.primary.withValues(alpha: _glowPulse.value * 0.12),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 130,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: ConfidiaColors.secondary.withValues(alpha: 0.2 * _glowPulse.value),
                                            blurRadius: 48,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const ConfidiaLogo(size: 68),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 32),
                              Opacity(
                                opacity: _subtitleOpacity.value,
                                child: Text(
                                  widget.subtitle!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: ConfidiaColors.textSecondary(isDark),
                                        letterSpacing: 0.4,
                                      ),
                                ),
                              ),
                            ],
                          ],
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
