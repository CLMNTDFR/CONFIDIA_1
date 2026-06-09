import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:confidia/app.dart';

void main() {
  testWidgets('CONFIDIA app renders login screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ConfidiaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CONFIDIA'), findsWidgets);
    expect(find.text('Connexion'), findsOneWidget);
  });
}
