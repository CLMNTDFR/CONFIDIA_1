import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/api/api_error_message.dart';
import '../../core/theme/spacing.dart';
import '../../features/auth/register_validators.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_modal_sheet.dart';
import '../../shared/widgets/confidia_snackbar.dart';
import '../../shared/widgets/confidia_text_field.dart';

Future<void> showProfilePasswordSheet(BuildContext context) {
  return showConfidiaSheet<void>(
    context: context,
    title: 'Changer le mot de passe',
    child: const _ProfilePasswordContent(),
  );
}

class _ProfilePasswordContent extends ConsumerStatefulWidget {
  const _ProfilePasswordContent();

  @override
  ConsumerState<_ProfilePasswordContent> createState() => _ProfilePasswordContentState();
}

class _ProfilePasswordContentState extends ConsumerState<_ProfilePasswordContent> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (ref.read(authStateProvider).isDemoSession) {
      showConfidiaSnackBar(
        context,
        'Changement de mot de passe indisponible en mode démo',
        type: ConfidiaSnackType.warning,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(profileApiServiceProvider).changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (!mounted) return;
      showConfidiaSnackBar(context, 'Mot de passe mis à jour', type: ConfidiaSnackType.success);
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      showConfidiaSnackBar(
        context,
        apiErrorMessage(error, fallback: 'Impossible de changer le mot de passe'),
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
          ConfidiaTextFormField(
            controller: _currentCtrl,
            labelText: 'Mot de passe actuel',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureCurrent,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              icon: Icon(_obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
              onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          ConfidiaTextFormField(
            controller: _newCtrl,
            labelText: 'Nouveau mot de passe',
            prefixIcon: Icons.lock_rounded,
            obscureText: _obscureNew,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
            validator: RegisterValidators.password,
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          ConfidiaTextFormField(
            controller: _confirmCtrl,
            labelText: 'Confirmer',
            prefixIcon: Icons.lock_rounded,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) => RegisterValidators.passwordConfirm(v, _newCtrl.text),
          ),
          const SizedBox(height: ConfidiaSpacing.lg),
          Center(
            child: ConfidiaGlowButton(
              label: _saving ? 'Enregistrement…' : 'Mettre à jour',
              icon: Icons.check_rounded,
              onPressed: _saving ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}
