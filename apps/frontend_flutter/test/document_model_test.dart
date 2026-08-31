import 'package:confidia/shared/models/document_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson accepts UUID string ids from the API', () {
    final doc = DocumentModel.fromJson({
      'id': '11111111-1111-1111-1111-111111111111',
      'title': 'Facture',
      'created': '2026-03-01T00:00:00.000Z',
      'modified': '2026-03-01T00:00:00.000Z',
      'category': 'Énergie',
      'file_size': 12,
    });
    expect(doc.id, '11111111-1111-1111-1111-111111111111');
    expect(doc.fileSize, 12);
  });

  test('fromJson stringifies numeric ids from older payloads', () {
    final doc = DocumentModel.fromJson({
      'id': 7,
      'title': 'Scan',
      'created': '2026-03-01T00:00:00.000Z',
      'modified': '2026-03-01T00:00:00.000Z',
    });
    expect(doc.id, '7');
  });

  test('suggestedFilename adds an extension from the mime type', () {
    final doc = DocumentModel(
      id: '1',
      title: 'Facture EDF',
      created: DateTime(2026, 3, 1),
      modified: DateTime(2026, 3, 1),
      mimeType: 'application/pdf',
    );
    expect(doc.suggestedFilename, 'Facture EDF.pdf');
    expect(doc.isImagePreviewable, isFalse);
    expect(doc.isPdfPreviewable, isTrue);
  });

  test('image mime types are previewable', () {
    final doc = DocumentModel(
      id: '2',
      title: 'Scan',
      created: DateTime(2026, 3, 1),
      modified: DateTime(2026, 3, 1),
      mimeType: 'image/png',
    );
    expect(doc.isImagePreviewable, isTrue);
    expect(doc.suggestedFilename, 'Scan.png');
  });
}
