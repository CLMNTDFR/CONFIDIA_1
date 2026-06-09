import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/widgets/glass_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return SingleChildScrollView(
        padding: const EdgeInsets.all(ConfidiaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: ConfidiaColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: ConfidiaColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: ConfidiaSpacing.md),
                  Text(user.fullName, style: Theme.of(context).textTheme.headlineMedium),
                  Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: ConfidiaSpacing.sm),
                  Wrap(
                    spacing: ConfidiaSpacing.sm,
                    children: user.roles
                        .map((role) => Chip(
                              label: Text(role),
                              backgroundColor: ConfidiaColors.secondary.withValues(alpha: 0.15),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ConfidiaSpacing.xl),
            GlassCard(
                child: Column(
                  children: [
                    _ProfileField(icon: Icons.person_outline, label: 'Prénom', value: user.firstName),
                    const Divider(height: 1),
                    _ProfileField(icon: Icons.person_outline, label: 'Nom', value: user.lastName),
                    const Divider(height: 1),
                    _ProfileField(icon: Icons.email_outlined, label: 'Email', value: user.email),
                    const Divider(height: 1),
                    _ProfileField(
                      icon: Icons.phone_outlined,
                      label: 'Téléphone',
                      value: user.phone ?? 'Non renseigné',
                    ),
                    const Divider(height: 1),
                    _ProfileField(
                      icon: Icons.business_outlined,
                      label: 'Organisation',
                      value: user.organization ?? 'Non renseigné',
                    ),
                  ],
                ),
              ),
            const SizedBox(height: ConfidiaSpacing.xxl),
          ],
        ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileField({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: ConfidiaColors.darkTextSecondary),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
