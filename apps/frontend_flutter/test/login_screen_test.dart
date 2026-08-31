import 'package:confidia/core/theme/palette.dart';
import 'package:confidia/core/theme/theme.dart';
import 'package:confidia/features/auth/login_screen.dart';
import 'package:confidia/shared/widgets/confidia_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('create-account action uses the same outlined ConfidiaButton as demo actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ConfidiaTheme.dark(ConfidiaPalette.blue),
          home: const Scaffold(body: LoginScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final createAccount = tester.widget<ConfidiaButton>(
      find.byWidgetPredicate(
        (widget) => widget is ConfidiaButton && widget.label.contains('Pas encore de compte'),
      ),
    );
    final demo = tester.widget<ConfidiaButton>(
      find.byWidgetPredicate(
        (widget) => widget is ConfidiaButton && widget.label == 'Mode démo',
      ),
    );

    expect(createAccount.outlined, isTrue);
    expect(demo.outlined, isTrue);
  });
}
