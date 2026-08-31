import 'package:confidia/core/theme/palette.dart';
import 'package:confidia/core/theme/theme.dart';
import 'package:confidia/features/auth/register_screen.dart';
import 'package:confidia/shared/widgets/confidia_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('register form blocks submit when email and password are invalid', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ConfidiaTheme.dark(ConfidiaPalette.blue),
          home: const Scaffold(body: RegisterScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Créer un compte'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ada@confidia.local');
    await tester.enterText(fields.at(1), 'other@confidia.local');
    await tester.enterText(fields.at(2), 'ada');
    await tester.enterText(fields.at(3), 'Ada');
    await tester.enterText(fields.at(4), 'Lovelace');
    await tester.enterText(fields.at(5), 'weak');
    await tester.enterText(fields.at(6), 'weak');

    await tester.ensureVisible(find.text('Créer mon compte'));
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('Les adresses e-mail ne correspondent pas'), findsWidgets);
    expect(find.textContaining('trop court'), findsWidgets);
  });

  testWidgets('register password fields start empty without admin autofill', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ConfidiaTheme.dark(ConfidiaPalette.blue),
          home: const Scaffold(body: RegisterScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(fields.length, 7);
    expect(fields[5].controller?.text, isEmpty);
    expect(fields[6].controller?.text, isEmpty);
    expect(find.text('admin'), findsNothing);
  });

  testWidgets('register uses the same outlined button style to go back to login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ConfidiaTheme.dark(ConfidiaPalette.blue),
          home: const Scaffold(body: RegisterScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is ConfidiaButton && widget.outlined && widget.label.contains('Se connecter'),
      ),
      findsOneWidget,
    );
  });
}
