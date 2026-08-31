import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/logo_auth_transition.dart';
import '../../shared/widgets/welcome_ambient_background.dart';
import '../calendar/calendar_provider.dart';
import '../dashboard/dashboard_provider.dart';
import '../documents/documents_provider.dart';
import '../onboarding/guided_tour_provider.dart';
import '../../core/auth/auth_provider.dart';

class WelcomeSplashScreen extends ConsumerStatefulWidget {
  const WelcomeSplashScreen({super.key});

  static const splashDuration = Duration(milliseconds: 3200);

  @override
  ConsumerState<WelcomeSplashScreen> createState() => _WelcomeSplashScreenState();
}

class _WelcomeSplashScreenState extends ConsumerState<WelcomeSplashScreen> {
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSplash());
  }

  Future<void> _warmUp() async {
    ref.read(dashboardLayoutProvider);
    ref.read(calendarProvider);
    await ref.read(documentsProvider.notifier).refresh();
    final auth = ref.read(authStateProvider);
    if (!auth.isDemoSession && await ref.read(authStateProvider.notifier).isFirstLoginPending()) {
      ref.read(guidedTourProvider.notifier).arm();
    }
  }

  Future<void> _runSplash() async {
    await Future.wait([
      Future.delayed(WelcomeSplashScreen.splashDuration),
      _warmUp(),
    ]);
    if (!mounted) return;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return WelcomeAmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            LogoAuthTransition(
              active: _active,
              profile: LogoTransitionProfile.welcome,
              loopUntilInactive: false,
              subtitle: 'Chargement de votre espace…',
              onComplete: () {
                if (mounted) setState(() => _active = false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
