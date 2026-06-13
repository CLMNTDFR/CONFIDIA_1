import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import 'confidia_animated_logo.dart';

/// Profil de vitesse : connexion (boucle modérée) vs chargement post-login (4,5 s).
enum LogoTransitionProfile { connection, welcome }

/// Overlay de chargement : logo + CONFIDIA + Hub numérique avec anneau animé.
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

class _LogoAuthTransitionState extends State<LogoAuthTransition> with SingleTickerProviderStateMixin {
  late final AnimationController _main;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _subtitleOpacity;
  bool _completing = false;
  bool _completeFired = false;

  bool get _isWelcome => widget.profile == LogoTransitionProfile.welcome;

  Duration get _cycleDuration => _isWelcome
      ? const Duration(milliseconds: 4500)
      : const Duration(milliseconds: 2400);

  @override
  void initState() {
    super.initState();
    _main = AnimationController(vsync: this, duration: _cycleDuration);
    _buildAnimations();

    _main.addStatusListener(_onMainStatus);
    if (widget.active) _startCycle();
  }

  void _buildAnimations() {
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
                    animation: _main,
                    builder: (context, _) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: const ConfidiaAnimatedLogo(size: 56, showText: true),
                              ),
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 28),
                              Opacity(
                                opacity: _subtitleOpacity.value,
                                child: Text(
                                  widget.subtitle!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.65,
                                    height: 1.45,
                                    color: ConfidiaColors.textSecondary(isDark),
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
