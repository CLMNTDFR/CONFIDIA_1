import 'package:confidia/core/auth/auth_provider.dart';
import 'package:confidia/core/theme/palette.dart';
import 'package:confidia/core/theme/theme.dart';
import 'package:confidia/features/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'helpers/session_containers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets('live empty dashboard keeps widgets after layout', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/documents', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/calendar', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/payments', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/settings', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/notifications', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/messaging', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => liveAuthNotifier()),
        ],
        child: MaterialApp.router(
          theme: ConfidiaTheme.dark(ConfidiaPalette.blue),
          locale: const Locale('fr', 'FR'),
          supportedLocales: const [Locale('fr', 'FR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Indice de sérénité'), findsOneWidget);
    expect(find.text('Commencer ma journée'), findsOneWidget);
    expect(find.text('Pas encore d\'historique'), findsOneWidget);
    final error = tester.takeException();
    if (error != null) {
      expect('$error', isNot(contains('was not laid out')));
      expect('$error', isNot(contains('Unexpected null value')));
    }
  });
}
