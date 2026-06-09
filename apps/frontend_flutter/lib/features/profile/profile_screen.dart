import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/logout_button.dart';
import '../../shared/widgets/stagger_fade.dart';
import '../../shared/widgets/user_avatar.dart';
import 'profile_avatar_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final avatarBase64 = ref.watch(profileAvatarProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final docCount = MockData.documents.length;
    final eventCount = MockData.calendarEvents.length;
    final unread = MockData.notifications.where((n) => !n.read).length;
    final isWide = MediaQuery.of(context).size.width >= 720;

    return SingleChildScrollView(
      padding: ConfidiaInsets.page(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              StaggerFade(
                index: 0,
                child: GlassCard(
                  highlighted: true,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          UserAvatarLarge(
                            user: user,
                            imageBase64: avatarBase64,
                            onTap: () => _showAvatarOptions(context, ref),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Material(
                              color: ConfidiaColors.primary,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: () => _showAvatarOptions(context, ref),
                                customBorder: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(user.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        children: user.roles
                            .map((r) => Chip(
                                  label: Text(r, style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ConfidiaSpacing.md),
              StaggerFade(
                index: 1,
                child: Row(
                  children: [
                    Expanded(child: _MetricTile(label: 'Documents', value: '$docCount', icon: Icons.folder_copy_rounded, color: ConfidiaColors.primary)),
                    const SizedBox(width: ConfidiaSpacing.sm),
                    Expanded(child: _MetricTile(label: 'Échéances', value: '$eventCount', icon: Icons.event_rounded, color: ConfidiaColors.accent)),
                    const SizedBox(width: ConfidiaSpacing.sm),
                    Expanded(child: _MetricTile(label: 'Alertes', value: '$unread', icon: Icons.notifications_rounded, color: ConfidiaColors.secondary)),
                  ],
                ),
              ),
              const SizedBox(height: ConfidiaSpacing.md),
              StaggerFade(
                index: 2,
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ProfileTile(icon: Icons.person_rounded, title: 'Informations', subtitle: '${user.firstName} ${user.lastName}'),
                      const Divider(height: 1),
                      _ProfileTile(icon: Icons.email_rounded, title: 'Email', subtitle: user.email),
                      const Divider(height: 1),
                      _ProfileTile(icon: Icons.phone_rounded, title: 'Téléphone', subtitle: user.phone ?? 'Non renseigné'),
                      const Divider(height: 1),
                      _ProfileTile(icon: Icons.business_rounded, title: 'Organisation', subtitle: user.organization ?? 'Non renseigné'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ConfidiaSpacing.lg),
              StaggerFade(
                index: 3,
                child: const LogoutButton(),
              ),
              if (isWide) const SizedBox(height: ConfidiaSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAvatarOptions(BuildContext context, WidgetRef ref) async {
    final hasPhoto = ref.read(profileAvatarProvider) != null;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choisir depuis la galerie'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(profileAvatarProvider.notifier).pickAndSave(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(profileAvatarProvider.notifier).pickAndSave(ImageSource.camera);
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: ConfidiaColors.error),
                title: const Text('Supprimer la photo', style: TextStyle(color: ConfidiaColors.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(profileAvatarProvider.notifier).remove();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? ConfidiaColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ConfidiaColors.border(isDark)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: ConfidiaColors.primary, size: 18),
      title: Text(title, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
