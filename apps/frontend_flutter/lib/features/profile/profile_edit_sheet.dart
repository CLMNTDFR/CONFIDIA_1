import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/api/api_error_message.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../shared/models/user_model.dart';
import '../../shared/widgets/confidia_dropdown_field.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_modal_sheet.dart';
import '../../shared/widgets/confidia_snackbar.dart';
import '../../shared/widgets/confidia_text_field.dart';
import 'profile_avatar_provider.dart';

enum ProfileEditField { phone, organization, locale, timezone }

const _localeOptions = <String>['fr_FR', 'en_US'];
const _timezoneOptions = <String>[
  'Europe/Paris',
  'Europe/Brussels',
  'America/New_York',
];

String _titleFor(ProfileEditField? focusField) => switch (focusField) {
      null => 'Modifier le profil',
      ProfileEditField.phone => 'Téléphone',
      ProfileEditField.organization => 'Espace',
      ProfileEditField.locale => 'Langue',
      ProfileEditField.timezone => 'Fuseau horaire',
    };

Future<void> showProfileEditSheet(
  BuildContext context,
  UserModel user, {
  ProfileEditField? focusField,
}) {
  return showConfidiaSheet<void>(
    context: context,
    title: _titleFor(focusField),
    child: _ProfileEditContent(user: user, focusField: focusField),
  );
}

Future<void> showProfileAvatarSheet(BuildContext context) {
  return showConfidiaSheet<void>(
    context: context,
    title: 'Photo de profil',
    child: const _ProfileAvatarOptions(),
  );
}

class _ProfileAvatarOptions extends ConsumerWidget {
  const _ProfileAvatarOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPhoto = ref.watch(profileAvatarProvider) != null;
    final primary = context.palette.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.photo_library_rounded, color: primary),
          title: const Text('Choisir depuis la galerie'),
          mouseCursor: SystemMouseCursors.click,
          onTap: () async {
            Navigator.pop(context);
            final error = await ref.read(profileAvatarProvider.notifier).pickAndSave(ImageSource.gallery);
            if (!context.mounted || error == null) return;
            showConfidiaSnackBar(context, error, type: ConfidiaSnackType.error);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.photo_camera_rounded, color: primary),
          title: const Text('Prendre une photo'),
          mouseCursor: SystemMouseCursors.click,
          onTap: () async {
            Navigator.pop(context);
            final error = await ref.read(profileAvatarProvider.notifier).pickAndSave(ImageSource.camera);
            if (!context.mounted || error == null) return;
            showConfidiaSnackBar(context, error, type: ConfidiaSnackType.error);
          },
        ),
        if (hasPhoto)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline_rounded, color: ConfidiaColors.error),
            title: const Text('Supprimer la photo', style: TextStyle(color: ConfidiaColors.error)),
            mouseCursor: SystemMouseCursors.click,
            onTap: () async {
              Navigator.pop(context);
              final error = await ref.read(profileAvatarProvider.notifier).remove();
              if (!context.mounted || error == null) return;
              showConfidiaSnackBar(context, error, type: ConfidiaSnackType.error);
            },
          ),
      ],
    );
  }
}

class _ProfileEditContent extends ConsumerStatefulWidget {
  final UserModel user;
  final ProfileEditField? focusField;

  const _ProfileEditContent({required this.user, this.focusField});

  @override
  ConsumerState<_ProfileEditContent> createState() => _ProfileEditContentState();
}

class _ProfileEditContentState extends ConsumerState<_ProfileEditContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _orgCtrl;
  late String _locale;
  late String _timezone;
  bool _saving = false;

  bool get _isFullForm => widget.focusField == null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _firstNameCtrl = TextEditingController(text: u.firstName);
    _lastNameCtrl = TextEditingController(text: u.lastName);
    _emailCtrl = TextEditingController(text: u.email);
    _phoneCtrl = TextEditingController(text: u.phone ?? '');
    _orgCtrl = TextEditingController(text: u.organization ?? '');
    _locale = _localeOptions.contains(UserModel.normalizeLocale(u.locale))
        ? UserModel.normalizeLocale(u.locale)
        : 'fr_FR';
    _timezone = _timezoneOptions.contains(u.timezone) ? u.timezone : 'Europe/Paris';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  UserModel _buildUpdatedUser() {
    final phone = _phoneCtrl.text.trim();
    final org = _orgCtrl.text.trim();
    return switch (widget.focusField) {
      ProfileEditField.phone => widget.user.copyWith(
          phone: phone.isEmpty ? null : phone,
          clearPhone: phone.isEmpty,
        ),
      ProfileEditField.organization => widget.user.copyWith(organization: org),
      ProfileEditField.locale => widget.user.copyWith(locale: _locale),
      ProfileEditField.timezone => widget.user.copyWith(timezone: _timezone),
      null => widget.user.copyWith(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          phone: phone.isEmpty ? null : phone,
          organization: org,
          locale: _locale,
          timezone: _timezone,
          clearPhone: phone.isEmpty,
        ),
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    setState(() => _saving = true);
    final updated = _buildUpdatedUser();
    final demo = ref.read(authStateProvider).isDemoSession;
    final auth = ref.read(authStateProvider.notifier);

    try {
      if (demo) {
        auth.updateLocalUser(updated);
      } else {
        final saved = await ref.read(profileApiServiceProvider).updateProfile(updated);
        auth.updateLocalUser(saved);
      }
      if (!mounted) return;
      showConfidiaSnackBar(context, 'Profil mis à jour', type: ConfidiaSnackType.success);
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      showConfidiaSnackBar(
        context,
        apiErrorMessage(error, fallback: 'Impossible d\'enregistrer le profil'),
        type: ConfidiaSnackType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isFullForm) ..._fullFields(),
          if (widget.focusField == ProfileEditField.phone) _phoneField(autofocus: true),
          if (widget.focusField == ProfileEditField.organization) _orgField(autofocus: true),
          if (widget.focusField == ProfileEditField.locale) _localeField(),
          if (widget.focusField == ProfileEditField.timezone) _timezoneField(),
          const SizedBox(height: ConfidiaSpacing.lg),
          Center(
            child: ConfidiaGlowButton(
              label: _saving ? 'Enregistrement…' : 'Enregistrer',
              icon: Icons.check_rounded,
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _fullFields() {
    return [
      ConfidiaTextFormField(
        controller: _firstNameCtrl,
        labelText: 'Prénom',
        prefixIcon: Icons.person_outline_rounded,
        textInputAction: TextInputAction.next,
        validator: (v) => v?.trim().isEmpty == true ? 'Requis' : null,
      ),
      const SizedBox(height: ConfidiaSpacing.sm),
      ConfidiaTextFormField(
        controller: _lastNameCtrl,
        labelText: 'Nom',
        prefixIcon: Icons.badge_outlined,
        textInputAction: TextInputAction.next,
        validator: (v) => v?.trim().isEmpty == true ? 'Requis' : null,
      ),
      const SizedBox(height: ConfidiaSpacing.sm),
      // Email lié à l'auth : non modifiable tant qu'il n'y a pas de flux backend dédié.
      ConfidiaTextFormField(
        controller: _emailCtrl,
        labelText: 'Email',
        prefixIcon: Icons.email_outlined,
        enabled: false,
      ),
      const SizedBox(height: ConfidiaSpacing.sm),
      _phoneField(),
      const SizedBox(height: ConfidiaSpacing.sm),
      _orgField(),
      const SizedBox(height: ConfidiaSpacing.sm),
      _localeField(),
      const SizedBox(height: ConfidiaSpacing.sm),
      _timezoneField(),
    ];
  }

  Widget _phoneField({bool autofocus = false}) {
    return ConfidiaTextFormField(
      controller: _phoneCtrl,
      autofocus: autofocus,
      labelText: 'Téléphone',
      prefixIcon: Icons.phone_outlined,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _save(),
    );
  }

  Widget _orgField({bool autofocus = false}) {
    return ConfidiaTextFormField(
      controller: _orgCtrl,
      autofocus: autofocus,
      labelText: 'Espace',
      hintText: 'Famille, club, personnel',
      prefixIcon: Icons.business_outlined,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _save(),
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? 'Le nom de l\'espace est requis' : null,
    );
  }

  Widget _localeField() {
    return ConfidiaDropdownField<String>(
      value: _locale,
      items: _localeOptions,
      itemLabel: (code) => code == 'en_US' ? 'English (US)' : 'Français',
      labelText: 'Langue',
      prefixIcon: Icons.language_rounded,
      onChanged: (v) {
        if (v != null) setState(() => _locale = v);
      },
    );
  }

  Widget _timezoneField() {
    return ConfidiaDropdownField<String>(
      value: _timezone,
      items: _timezoneOptions,
      itemLabel: (tz) => tz.replaceAll('_', ' '),
      labelText: 'Fuseau horaire',
      prefixIcon: Icons.schedule_rounded,
      onChanged: (v) {
        if (v != null) setState(() => _timezone = v);
      },
    );
  }
}
