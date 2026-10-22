import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/models/user_model.dart';
import '../../shared/widgets/confidia_demo_badge.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_tappable.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/logout_button.dart';
import '../../shared/widgets/mobile_shell_insets.dart';
import '../../shared/widgets/user_avatar.dart';
import 'profile_avatar_provider.dart';
import 'profile_edit_sheet.dart';
import 'profile_password_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.user;
    final avatarBase64 = ref.watch(profileAvatarProvider);
    if (user == null) {
      if (!auth.isAuthenticated || auth.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Padding(
          padding: ConfidiaInsets.page(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Impossible de charger le profil. Vérifiez que l\'API est démarrée.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: ConfidiaSpacing.md),
              ConfidiaGlowButton(
                label: 'Réessayer',
                icon: Icons.refresh_rounded,
                onPressed: () => ref.read(authStateProvider.notifier).reloadUser(),
              ),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: ConfidiaInsets.page(context),
      children: [
        _ProfileHero(
          user: user,
          avatarBase64: avatarBase64,
          onAvatarTap: () => showProfileAvatarSheet(context),
          onEdit: () => showProfileEditSheet(context, user),
        ),
        const SizedBox(height: ConfidiaSpacing.md),
        const _SectionTitle(label: 'Coordonnées'),
        const SizedBox(height: 8),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.phone_rounded,
                title: 'Téléphone',
                subtitle: user.phone?.isNotEmpty == true ? user.phone! : 'Non renseigné',
                onTap: () => showProfileEditSheet(
                  context,
                  user,
                  focusField: ProfileEditField.phone,
                ),
              ),
              Divider(height: 1, color: ConfidiaColors.border(isDark)),
              _InfoTile(
                icon: Icons.business_rounded,
                title: 'Espace',
                subtitle: user.organization?.isNotEmpty == true ? user.organization! : 'Non renseigné',
                onTap: () => showProfileEditSheet(
                  context,
                  user,
                  focusField: ProfileEditField.organization,
                ),
              ),
              Divider(height: 1, color: ConfidiaColors.border(isDark)),
              _InfoTile(
                icon: Icons.language_rounded,
                title: 'Langue',
                subtitle: user.localeLabel,
                onTap: () => showProfileEditSheet(
                  context,
                  user,
                  focusField: ProfileEditField.locale,
                ),
              ),
              Divider(height: 1, color: ConfidiaColors.border(isDark)),
              _InfoTile(
                icon: Icons.schedule_rounded,
                title: 'Fuseau horaire',
                subtitle: user.timezoneLabel,
                onTap: () => showProfileEditSheet(
                  context,
                  user,
                  focusField: ProfileEditField.timezone,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ConfidiaSpacing.md),
        _SectionTitle(label: 'Accès & services', demo: auth.isDemoSession),
        const SizedBox(height: 8),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.account_tree_rounded,
                title: 'Gouvernance & accès',
                subtitle: auth.isDemoSession
                    ? 'Structures, rôles et droits'
                    : 'Organigramme, droits et invitations',
                demo: auth.isDemoSession,
                onTap: () => context.go('/access-control'),
              ),
              Divider(height: 1, color: ConfidiaColors.border(isDark)),
              _InfoTile(
                icon: Icons.link_rounded,
                title: 'Comptes & intégrations',
                subtitle: 'Comptes connectés et stockage',
                demo: true,
                onTap: () => context.go('/settings'),
              ),
            ],
          ),
        ),
        const SizedBox(height: ConfidiaSpacing.md),
        const _SectionTitle(label: 'Sécurité'),
        const SizedBox(height: 8),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.lock_outline_rounded,
                title: 'Changer le mot de passe',
                onTap: () => showProfilePasswordSheet(context),
              ),
              Divider(height: 1, color: ConfidiaColors.border(isDark)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LogoutButton(),
              ),
            ],
          ),
        ),
        const SizedBox(height: ConfidiaSpacing.xl),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final UserModel user;
  final String? avatarBase64;
  final VoidCallback onAvatarTap;
  final VoidCallback onEdit;

  const _ProfileHero({
    required this.user,
    required this.avatarBase64,
    required this.onAvatarTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      highlighted: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatarLarge(
                user: user,
                radius: 36,
                imageBase64: avatarBase64,
                onTap: onAvatarTap,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: ConfidiaTappable(
                  onTap: onAvatarTap,
                  pressScale: 0.92,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.palette.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: ConfidiaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  user.roleLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.palette.primary,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: ConfidiaSpacing.sm),
          ConfidiaGlowButton(
            label: 'Modifier',
            icon: Icons.edit_outlined,
            primary: false,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final bool demo;

  const _SectionTitle({required this.label, this.demo = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark),
                letterSpacing: 0.4,
              ),
        ),
        if (demo) ...[
          const SizedBox(width: 8),
          const ConfidiaDemoBadge(compact: true),
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool demo;

  const _InfoTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.demo = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Icon(icon, size: 18, color: context.palette.primary),
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle!, style: Theme.of(context).textTheme.labelSmall) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (demo) const ConfidiaDemoBadge(compact: true),
          if (demo && onTap != null) const SizedBox(width: 8),
          if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
      mouseCursor: onTap != null ? SystemMouseCursors.click : null,
      onTap: onTap,
    );
  }
}
