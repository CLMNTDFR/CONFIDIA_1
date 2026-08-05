import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_context.dart';
import '../day_start/day_start_provider.dart';
import '../onboarding/onboarding_targets.dart';

/// CTA principal du dashboard pour le rituel « Commencer ma journée ».
class StartMyDayHero extends ConsumerStatefulWidget {
  const StartMyDayHero({super.key});

  @override
  ConsumerState<StartMyDayHero> createState() => _StartMyDayHeroState();
}

class _StartMyDayHeroState extends ConsumerState<StartMyDayHero> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(dayStartSessionProvider);
    final completed = session.completedToday;
    final title = completed ? 'Revoir ma journée' : 'Commencer ma journée';
    final disableAnim = MediaQuery.disableAnimationsOf(context);
    final primary = context.palette.primary;
    final secondary = context.palette.secondary;

    return KeyedSubtree(
      key: OnboardingTargets.startMyDay,
      child: Semantics(
        button: true,
        label: title,
        hint: 'Confid•IA résume votre journée en 20 secondes',
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            final notifier = ref.read(dayStartSessionProvider.notifier);
            if (completed) {
              notifier.reopen();
            } else {
              notifier.start();
            }
          },
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: disableAnim ? Duration.zero : const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.22),
                    blurRadius: 18,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: secondary.withValues(alpha: 0.18),
                    blurRadius: 14,
                    spreadRadius: -4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.white.withValues(alpha: 0.95), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Confid•IA résume votre journée en 20 secondes',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                                height: 1.25,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.95), size: 26),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
