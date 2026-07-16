import 'package:confidia/core/theme/palette.dart';
import 'package:confidia/features/calendar/event_type_config.dart';
import 'package:confidia/shared/models/calendar_event_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each EventType has a config for blue and rose palettes', () {
    for (final palette in [ConfidiaPalette.blue, ConfidiaPalette.rose]) {
      for (final type in EventType.values) {
        final config = configFor(type, palette);
        expect(config.type, type);
        expect(config.label, isNotEmpty);
        expect(colorForEventType(type, palette), config.color);
      }
    }
  });

  test('deadline uses brand primary', () {
    expect(colorForEventType(EventType.deadline, ConfidiaPalette.blue), ConfidiaPalette.blue.primary);
    expect(colorForEventType(EventType.deadline, ConfidiaPalette.rose), ConfidiaPalette.rose.primary);
  });
}
