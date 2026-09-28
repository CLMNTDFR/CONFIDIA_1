import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import 'confidia_confirm_dialog.dart';

Future<bool> confirmLogout(BuildContext context) {
  return showConfidiaConfirmDialog(
    context,
    title: 'Se déconnecter ?',
    message: 'Vous allez quitter votre espace CONFIDIA. Vos données locales restent sur cet appareil.',
    confirmLabel: 'Déconnexion',
    icon: Icons.logout_rounded,
    destructive: true,
  );
}

Future<void> performLogout(BuildContext context, WidgetRef ref) async {
  if (!await confirmLogout(context)) return;
  await ref.read(authStateProvider.notifier).logout();
  if (context.mounted) context.go('/login');
}

/// Compact logout button with confirmation.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => performLogout(context, ref),
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12),
          hoverColor: ConfidiaColors.error.withValues(alpha: isDark ? 0.14 : 0.08),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ConfidiaColors.error.withValues(alpha: 0.3)),
              color: ConfidiaColors.error.withValues(alpha: isDark ? 0.1 : 0.05),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
