import '../models/calendar_event_model.dart';
import '../models/document_model.dart';
import '../models/notification_model.dart';
import 'mock_ecosystem.dart';

export 'mock_ecosystem.dart';

/// Alias rétrocompatible  -  toutes les données proviennent de [MockEcosystem].
abstract final class MockData {
  static List<DocumentModel> get documents => MockEcosystem.documents;
  static List<CalendarEventModel> get calendarEvents => MockEcosystem.calendarEvents;
  static List<NotificationModel> get notifications => MockEcosystem.notifications;
  static List<String> get categories => MockEcosystem.categories;
  static List<String> get allTags => MockEcosystem.allTags;
}
