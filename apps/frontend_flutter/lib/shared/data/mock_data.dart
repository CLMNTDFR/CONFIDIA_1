import 'mock_ecosystem.dart';

export 'mock_ecosystem.dart';

/// Alias rétrocompatible — toutes les données proviennent de [MockEcosystem].
abstract final class MockData {
  static get documents => MockEcosystem.documents;
  static get calendarEvents => MockEcosystem.calendarEvents;
  static get notifications => MockEcosystem.notifications;
  static get categories => MockEcosystem.categories;
  static get allTags => MockEcosystem.allTags;
}
