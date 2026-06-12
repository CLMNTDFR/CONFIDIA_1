import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';

/// Affiche du texte progressivement, comme une réponse IA en cours de rédaction.
class AiStreamingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration thinkingDelay;
  final VoidCallback? onComplete;

  const AiStreamingText({
    super.key,
    required this.text,
    this.style,
    this.thinkingDelay = const Duration(milliseconds: 450),
    this.onComplete,
  });

  @override
  State<AiStreamingText> createState() => _AiStreamingTextState();
}

class _AiStreamingTextState extends State<AiStreamingText> with TickerProviderStateMixin {
  late final AnimationController _stream;
  late final AnimationController _cursor;
  bool _thinking = true;

  @override
  void initState() {
    super.initState();
    final length = widget.text.characters.length;
    _stream = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (length * 26).clamp(1600, 6500)),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete?.call();
      });
    _cursor = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))
      ..repeat(reverse: true);

    Future<void>.delayed(widget.thinkingDelay, () {
      if (!mounted) return;
      setState(() => _thinking = false);
      _stream.forward();
    });
  }

  @override
  void dispose() {
    _stream.dispose();
    _cursor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.65);

    if (_thinking) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThinkingDots(style: style),
        ],
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_stream, _cursor]),
      builder: (context, _) {
        final count = (_stream.value * widget.text.characters.length).round().clamp(0, widget.text.characters.length);
        final visible = widget.text.characters.take(count).toString();
        final done = _stream.value >= 1;

        return RichText(
          text: TextSpan(
            style: style,
            children: [
              TextSpan(text: visible),
              if (!done)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.25, end: 1).animate(_cursor),
                    child: Container(
                      width: 2,
                      height: (style?.fontSize ?? 14) * 1.1,
                      margin: const EdgeInsets.only(left: 1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.palette.primary.withValues(alpha: 0.5),
                            context.palette.secondary,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  final TextStyle? style;

  const _ThinkingDots({this.style});

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = ConfidiaColors.textSecondary(isDark);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_pulse.value + i * 0.22) % 1.0;
            final opacity = 0.25 + (phase < 0.5 ? phase : 1 - phase) * 1.5;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: opacity.clamp(0.2, 1)),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
