import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_provider.dart';

class ConfidiaApp extends ConsumerWidget {
  const ConfidiaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isDark = ref.watch(themeModeProvider);
    final palette = watchPalette(ref);

    return MaterialApp.router(
      title: 'CONFIDIA',
      debugShowCheckedModeBanner: false,
      theme: ConfidiaTheme.light(palette),
      darkTheme: ConfidiaTheme.dark(palette),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
