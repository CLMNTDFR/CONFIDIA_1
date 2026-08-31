import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/widgets/confidia_button.dart';
import '../../shared/widgets/confidia_logo.dart';
import '../../shared/widgets/confidia_text_field.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/mesh_background.dart';
import '../../shared/widgets/theme_toggle_button.dart';
import 'register_validators.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _emailConfirm = TextEditingController();
  final _username = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  bool _fieldsUnlocked = false;
  String _passwordLive = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _fieldsUnlocked = true);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _emailConfirm.dispose();
    _username.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    setState(() => _submitting = true);
    final notifier = ref.read(authStateProvider.notifier);
    await notifier.register(
      email: _email.text,
      emailConfirm: _emailConfirm.text,
      username: _username.text,
      firstName: _firstName.text,
      lastName: _lastName.text,
      password: _password.text,
      passwordConfirm: _passwordConfirm.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(
      authStateProvider.select((s) => AuthState(isLoading: s.isLoading, error: s.error)),
    );
    final isWide = MediaQuery.of(context).size.width >= 900;
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned(top: 16, right: 16, child: ThemeToggleButton()),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(ConfidiaSpacing.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: isWide ? _buildWide(auth) : _buildNarrow(auth),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWide(AuthState auth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(ConfidiaSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ConfidiaLogo(size: 48),
                const SizedBox(height: ConfidiaSpacing.xxl),
                Text(
                  'Créez votre espace\nCONFIDIA.',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: ConfidiaColors.textPrimary(
                          Theme.of(context).brightness == Brightness.dark,
                        ),
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: ConfidiaSpacing.lg),
                Text(
                  'Un compte pour centraliser documents, échéances et identité. Le mot de passe reste chez Keycloak, le profil dans CONFIDIA.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _formCard(auth)),
      ],
    );
  }

  Widget _buildNarrow(AuthState auth) {
    return Column(
      children: [
        const ConfidiaLogo(size: 44),
        const SizedBox(height: ConfidiaSpacing.xl),
        _formCard(auth),
      ],
    );
  }

  Widget _formCard(AuthState auth) {
    final busy = auth.isLoading || _submitting;
    return GlassCard(
      highlighted: true,
      child: AutofillGroup(
        child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Créer un compte', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Renseignez vos informations. Vous serez connecté ensuite.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: ConfidiaSpacing.xl),
            ConfidiaTextFormField(
              controller: _email,
              enabled: !busy,
              readOnly: !_fieldsUnlocked,
              labelText: 'Adresse e-mail',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: RegisterValidators.email,
            ),
            const SizedBox(height: ConfidiaSpacing.md),
            ConfidiaTextFormField(
              controller: _emailConfirm,
              enabled: !busy,
              readOnly: !_fieldsUnlocked,
              labelText: 'Confirmation de l\'e-mail',
              prefixIcon: Icons.mark_email_read_outlined,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: (v) => RegisterValidators.emailConfirm(v, _email.text),
            ),
            const SizedBox(height: ConfidiaSpacing.md),
            ConfidiaTextFormField(
              controller: _username,
              enabled: !busy,
              readOnly: !_fieldsUnlocked,
              labelText: 'Nom d\'utilisateur',
              prefixIcon: Icons.alternate_email_rounded,
              autofillHints: const [AutofillHints.newUsername],
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              validator: RegisterValidators.username,
            ),
            const SizedBox(height: ConfidiaSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ConfidiaTextFormField(
                    controller: _firstName,
                    enabled: !busy,
                    readOnly: !_fieldsUnlocked,
                    labelText: 'Prénom',
                    prefixIcon: Icons.badge_outlined,
                    autofillHints: const [AutofillHints.givenName],
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (v) => RegisterValidators.requiredName(v, label: 'Le prénom'),
                  ),
                ),
                const SizedBox(width: ConfidiaSpacing.md),
                Expanded(
                  child: ConfidiaTextFormField(
                    controller: _lastName,
                    enabled: !busy,
                    readOnly: !_fieldsUnlocked,
                    labelText: 'Nom',
                    prefixIcon: Icons.badge_outlined,
                    autofillHints: const [AutofillHints.familyName],
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (v) => RegisterValidators.requiredName(v, label: 'Le nom'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ConfidiaSpacing.md),
            ConfidiaTextFormField(
              controller: _password,
              enabled: !busy,
              readOnly: !_fieldsUnlocked,
              obscureText: _obscurePassword,
              labelText: 'Mot de passe',
              prefixIcon: Icons.lock_outline_rounded,
              autofillHints: const [AutofillHints.newPassword],
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              onChanged: (v) => setState(() => _passwordLive = v),
              validator: RegisterValidators.password,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: ConfidiaSpacing.sm),
            _PasswordRules(value: _passwordLive),
            const SizedBox(height: ConfidiaSpacing.md),
            ConfidiaTextFormField(
              controller: _passwordConfirm,
              enabled: !busy,
              readOnly: !_fieldsUnlocked,
              obscureText: _obscureConfirm,
              labelText: 'Confirmation du mot de passe',
              prefixIcon: Icons.lock_person_outlined,
              autofillHints: const [AutofillHints.newPassword],
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: busy ? null : (_) => _submit(),
              validator: (v) => RegisterValidators.passwordConfirm(v, _password.text),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: ConfidiaSpacing.md),
              Text(auth.error!, style: const TextStyle(color: ConfidiaColors.error)),
            ],
            const SizedBox(height: ConfidiaSpacing.lg),
            ConfidiaButton(
              label: 'Créer mon compte',
              loading: busy,
              loadingLabel: 'Création…',
              onPressed: busy ? null : _submit,
            ),
            const SizedBox(height: ConfidiaSpacing.md),
            ConfidiaButton(
              label: 'Déjà un compte ? Se connecter',
              outlined: true,
              onPressed: busy ? null : () => context.go('/login'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _PasswordRules extends StatelessWidget {
  final String value;

  const _PasswordRules({required this.value});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _RuleChip(label: '12 caractères', ok: RegisterValidators.passwordHasLength(value)),
        _RuleChip(label: 'Majuscule', ok: RegisterValidators.passwordHasUpper(value)),
        _RuleChip(label: 'Chiffre', ok: RegisterValidators.passwordHasDigit(value)),
        _RuleChip(label: 'Spécial', ok: RegisterValidators.passwordHasSpecial(value)),
      ],
    );
  }
}

class _RuleChip extends StatelessWidget {
  final String label;
  final bool ok;

  const _RuleChip({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = ok ? ConfidiaColors.success : ConfidiaColors.textSecondary(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_rounded : Icons.circle_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
