import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/data/mock_data.dart';
import '../../shared/widgets/logo_auth_transition.dart';
import '../../shared/widgets/welcome_ambient_background.dart';
import '../calendar/calendar_provider.dart';
import '../dashboard/dashboard_provider.dart';

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
    MockData.documents.length;
    MockData.notifications.length;
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
