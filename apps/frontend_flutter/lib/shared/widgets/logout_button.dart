import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';

Future<bool> confirmLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Se déconnecter ?'),
      content: const Text('Vous allez quitter votre espace CONFIDIA. Vos données locales restent sur cet appareil.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ConfidiaColors.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Déconnexion'),
        ),
      ],
    ),
  );
  return ok == true;
}

Future<void> performLogout(BuildContext context, WidgetRef ref) async {
  if (!await confirmLogout(context)) return;
  await ref.read(authStateProvider.notifier).logout();
  if (context.mounted) context.go('/login');
}

/// Bouton de déconnexion compact avec confirmation.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => performLogout(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ConfidiaColors.error.withValues(alpha: 0.3)),
              color: ConfidiaColors.error.withValues(alpha: isDark ? 0.1 : 0.05),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout_rounded, size: 16, color: ConfidiaColors.error.withValues(alpha: 0.9)),
                  const SizedBox(width: 8),
                  Text(
                    'Se déconnecter',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: ConfidiaColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
