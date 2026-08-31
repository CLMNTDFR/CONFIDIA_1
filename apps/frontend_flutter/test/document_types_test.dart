import 'package:confidia/features/documents/document_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('choiceFor maps empty, preset and custom types', () {
    expect(DocumentTypes.choiceFor(null), DocumentTypes.unspecifiedKey);
    expect(DocumentTypes.choiceFor('  '), DocumentTypes.unspecifiedKey);
    expect(DocumentTypes.choiceFor('Facture'), 'Facture');
    expect(DocumentTypes.choiceFor('Permis de conduire'), DocumentTypes.otherKey);
  });

  test('resolve keeps optional empty and custom text', () {
    expect(DocumentTypes.resolve(choice: DocumentTypes.unspecifiedKey), isNull);
    expect(DocumentTypes.resolve(choice: 'Contrat'), 'Contrat');
    expect(DocumentTypes.resolve(choice: DocumentTypes.otherKey, custom: '  '), isNull);
    expect(
      DocumentTypes.resolve(choice: DocumentTypes.otherKey, custom: 'Permis de conduire'),
      'Permis de conduire',
    );
  });
}
