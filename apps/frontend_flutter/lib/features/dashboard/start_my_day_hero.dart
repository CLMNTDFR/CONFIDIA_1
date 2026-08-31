import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';
import '../../shared/widgets/confidia_demo_badge.dart';
import '../../shared/widgets/confidia_tappable.dart';
import '../day_start/day_start_provider.dart';
import '../onboarding/onboarding_targets.dart';

/// CTA principal du dashboard pour le rituel « Commencer ma journée ».
class StartMyDayHero extends ConsumerWidget {
  const StartMyDayHero({super.key});

  static const _benefitCopy = 'Votre journée résumée en 20 secondes';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(dayStartSessionProvider);
    final completed = session.completedToday;
    final title = completed ? 'Revoir ma journée' : 'Commencer ma journée';
    final primary = context.palette.primary;
    final secondary = context.palette.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(16);

    return KeyedSubtree(
      key: OnboardingTargets.startMyDay,
      child: Semantics(
        button: true,
        label: title,
        hint: _benefitCopy,
        child: ConfidiaTappable(
          onTap: () {
            final notifier = ref.read(dayStartSessionProvider.notifier);
            if (completed) {
              notifier.reopen();
            } else {
              notifier.start();
            }
          },
          pressScale: 0.97,
          borderRadius: radius,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, secondary],
              ),
              boxShadow: AppShadows.soft(isDark: isDark, accent: primary),
            ),
            child: Row(
              children: [
                Icon(Icons.wb_sunny_outlined, color: Colors.white.withValues(alpha: 0.95), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const ConfidiaDemoBadge(compact: true, onAccent: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _benefitCopy,
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
    );
  }
}
