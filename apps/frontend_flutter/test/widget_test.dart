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

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Mode démo'), findsOneWidget);
    expect(find.textContaining('CONFIDIA'), findsWidgets);
  });
}
