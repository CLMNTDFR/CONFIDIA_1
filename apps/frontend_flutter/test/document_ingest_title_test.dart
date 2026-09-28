import 'package:confidia/core/theme/palette.dart';
import 'package:confidia/core/theme/theme.dart';
import 'package:confidia/features/documents/widgets/document_ingest_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('document title drops a known file extension', () {
    expect(documentTitleFromFilename('(FR) Fiche Technique.pdf'), '(FR) Fiche Technique');
    expect(documentTitleFromFilename('scan.JPG'), 'scan');
    expect(documentTitleFromFilename('notes'), 'notes');
  });

  testWidgets('import title field is prefilled and required', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: documentTitleFromFilename('(FR) Fiche Technique.pdf'));
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ConfidiaTheme.dark(ConfidiaPalette.blue),
        home: Scaffold(
          body: Form(
            key: formKey,
            child: DocumentIngestTitleFields(
              controllers: [controller],
              filenames: const ['(FR) Fiche Technique.pdf'],
              enabled: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Titre'), findsOneWidget);
    expect(find.text('(FR) Fiche Technique'), findsOneWidget);
    expect(formKey.currentState!.validate(), isTrue);

    controller.clear();
    await tester.pump();
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Le titre est requis'), findsOneWidget);
  });
}
