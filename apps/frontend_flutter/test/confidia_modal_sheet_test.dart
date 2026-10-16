import 'package:confidia/core/theme/palette.dart';
import 'package:confidia/core/theme/theme.dart';
import 'package:confidia/shared/widgets/confidia_modal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sheet content fits the height that used to overflow by 1 px', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ConfidiaTheme.dark(ConfidiaPalette.blue),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 476,
              height: 594,
              child: ConfidiaSheet(
                title: 'Modifier le document',
                actions: [
                  SizedBox(height: 40, child: Text('Enregistrer')),
                ],
                child: SizedBox(height: 900, child: Text('contenu')),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Modifier le document'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
  });
}
