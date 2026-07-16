import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import 'ai_streaming_text.dart';
import 'confidia_ai_robot.dart';
import 'confidia_animated_logo.dart';

/// Profil de vitesse : connexion (boucle modérée) vs chargement post-login (4,5 s).
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

class _LogoAuthTransitionState extends State<LogoAuthTransition> with SingleTickerProviderStateMixin {
  late final AnimationController _main;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _aiOpacity;
  bool _completing = false;
  bool _completeFired = false;
  bool _showAiMessage = false;
  bool _aiSpeaking = false;

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
          tween: Tween(begin: 0.72, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 28,
        ),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 52),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.94).chain(CurveTween(curve: Curves.easeInCubic)),
          weight: 20,
        ),
      ]).animate(_main);

      _logoOpacity = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
          weight: 24,
        ),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 56),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 20,
        ),
      ]).animate(_main);

      _aiOpacity = TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween(0.0), weight: 22),
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 14,
        ),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 44),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 20,
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

      _aiOpacity = ConstantTween(0.0).animate(_main);
    }
  }

  @override
  void didUpdateWidget(LogoAuthTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _completing = false;
      _completeFired = false;
      _showAiMessage = false;
      _aiSpeaking = false;
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
    _showAiMessage = false;
    _main.forward(from: 0);
    if (_isWelcome) {
      Future<void>.delayed(const Duration(milliseconds: 680), () {
        if (mounted && widget.active) {
          setState(() {
            _showAiMessage = true;
            _aiSpeaking = true;
          });
        }
      });
    }
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
        duration: Duration(milliseconds: _isWelcome ? 280 : 400),
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: ColoredBox(
                    color: (isDark ? const Color(0xFF0A0A12) : Colors.white).withValues(alpha: isDark ? 0.42 : 0.38),
                  ),
                ),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: _main,
                  builder: (context, _) {
                    if (_isWelcome) {
                      return _buildWelcomeContent(context, isDark);
                    }
                    return _buildConnectionContent(context, isDark);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeContent(BuildContext context, bool isDark) {
    final message = widget.subtitle ?? 'Chargement de votre espace';

    // Hauteur réservée pour la bulle : le logo reste fixe quand le message apparaît.
    const messageSlotHeight = 96.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ConfidiaSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: _logoOpacity.value,
            child: Transform.scale(
              scale: _logoScale.value,
              child: const ConfidiaAnimatedLogo(size: 68, showText: false),
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: messageSlotHeight,
            child: Opacity(
              opacity: _aiOpacity.value,
              child: Transform.translate(
                offset: Offset(0, (1 - _aiOpacity.value) * 8),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _WelcomeAiMessage(
                    visible: _showAiMessage,
                    message: message,
                    speaking: _aiSpeaking,
                    onSpeakingChanged: (v) => setState(() => _aiSpeaking = v),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionContent(BuildContext context, bool isDark) {
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

class _WelcomeAiMessage extends StatelessWidget {
  final bool visible;
  final String message;
  final bool speaking;
  final ValueChanged<bool> onSpeakingChanged;

  const _WelcomeAiMessage({
    required this.visible,
    required this.message,
    required this.speaking,
    required this.onSpeakingChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.palette;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: palette.primary.withValues(alpha: isDark ? 0.22 : 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ConfidiaAiRobot(size: 34, speaking: speaking),
                const SizedBox(width: 12),
                Expanded(
                  child: Center(
                    child: AiStreamingText(
                      key: ValueKey(message),
                      text: message,
                      showThinkingRobot: false,
                      textAlign: TextAlign.center,
                      thinkingDelay: const Duration(milliseconds: 120),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        letterSpacing: 0.15,
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : ConfidiaColors.lightTextPrimary,
                      ),
                      onStreamStart: () {},
                      onComplete: () => onSpeakingChanged(false),
                    ),
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
