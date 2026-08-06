import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/widgets/confidia_logo.dart';
import '../../shared/widgets/confidia_button.dart';
import '../../shared/widgets/confidia_text_field.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/mesh_background.dart';
import '../../shared/widgets/theme_toggle_button.dart';
import '../onboarding/guided_tour_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'user');
  final _passwordController = TextEditingController(text: 'user');
  bool _obscurePassword = true;
  bool _authenticating = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({bool demo = false, bool guidedTour = false}) async {
    setState(() => _authenticating = true);
    try {
      if (guidedTour) {
        await ref.read(authStateProvider.notifier).loginDemoGuidedTour();
        ref.read(guidedTourProvider.notifier).arm();
      } else if (demo) {
        await ref.read(authStateProvider.notifier).loginDemo();
      } else {
        if (!_formKey.currentState!.validate()) return;
        await ref.read(authStateProvider.notifier).login(_usernameController.text, _passwordController.text);
      }
      // La redirection vers /welcome est gérée par le routeur (refreshListenable).
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
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
              Positioned(top: 16, right: 16, child: const ThemeToggleButton()),
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
                  'Votre vie administrative,\nsimplifiée.',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: ConfidiaColors.textPrimary(Theme.of(context).brightness == Brightness.dark),
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: ConfidiaSpacing.lg),
                Text(
                  'Centralisez documents, échéances et identité numérique dans un espace sécurisé et intelligent.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: ConfidiaSpacing.xl),
                const _FeatureRow(icon: Icons.folder_copy_rounded, text: 'Gestion documentaire intelligente'),
                const _FeatureRow(icon: Icons.calendar_month_rounded, text: 'Calendrier des échéances'),
                const _FeatureRow(icon: Icons.document_scanner_rounded, text: 'Scan via appareil photo'),
                const _FeatureRow(icon: Icons.shield_rounded, text: 'Authentification sécurisée Keycloak'),
              ],
            ),
          ),
        ),
        Expanded(child: _loginCard(auth)),
      ],
    );
  }

  Widget _buildNarrow(AuthState auth) {
    return Column(
      children: [
        const ConfidiaLogo(size: 44),
        const SizedBox(height: ConfidiaSpacing.xl),
        _loginCard(auth),
      ],
    );
  }

  Widget _loginCard(AuthState auth) {
    final busy = auth.isLoading || _authenticating;

    return GlassCard(
      highlighted: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Connexion', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Accédez à votre espace CONFIDIA', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: ConfidiaSpacing.xl),
            ConfidiaTextFormField(
              controller: _usernameController,
              enabled: !busy,
              labelText: 'Identifiant',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => v?.isEmpty == true ? 'Requis' : null,
            ),
            const SizedBox(height: ConfidiaSpacing.md),
            ConfidiaTextFormField(
              controller: _passwordController,
              enabled: !busy,
              obscureText: _obscurePassword,
              labelText: 'Mot de passe',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) => v?.isEmpty == true ? 'Requis' : null,
            ),
            if (auth.error != null) ...[
              const SizedBox(height: ConfidiaSpacing.md),
              Text(auth.error!, style: const TextStyle(color: ConfidiaColors.error)),
            ],
            const SizedBox(height: ConfidiaSpacing.lg),
            ConfidiaButton(
              label: 'Se connecter',
              loading: busy,
              loadingLabel: 'Connexion…',
              onPressed: busy ? null : () => _handleLogin(),
            ),
            const SizedBox(height: ConfidiaSpacing.sm),
            ConfidiaButton(
              label: 'Mode démo',
              outlined: true,
              loading: busy,
              loadingLabel: 'Connexion…',
              onPressed: busy ? null : () => _handleLogin(demo: true),
            ),
            const SizedBox(height: ConfidiaSpacing.sm),
            ConfidiaButton(
              label: 'Visite guidée',
              outlined: true,
              loading: busy,
              loadingLabel: 'Connexion…',
              onPressed: busy ? null : () => _handleLogin(guidedTour: true),
            ),
            const SizedBox(height: 8),
            Text(
              'Simule une première connexion avec tutoriel Confid•IA',
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ConfidiaSpacing.md),
            Text(
              'Comptes test · user/user · admin/admin · manager/manager',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ConfidiaSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ConfidiaColors.textSecondary(Theme.of(context).brightness == Brightness.dark)),
          const SizedBox(width: ConfidiaSpacing.sm),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
