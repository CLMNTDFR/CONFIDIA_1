import 'package:confidia/core/theme/palette.dart';
import 'package:confidia/shared/models/serenity_briefing_model.dart';
import 'package:confidia/shared/utils/serenity_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SerenityPalette.forScore', () {
    test('maps score bands to semantic colors', () {
      expect(SerenityPalette.forScore(90), SerenityPalette.excellent);
      expect(SerenityPalette.forScore(70), SerenityPalette.good);
      expect(SerenityPalette.forScore(55), SerenityPalette.moderate);
      expect(SerenityPalette.forScore(20), SerenityPalette.attention);
    });

    test('uses brand primary for the good band when palette is provided', () {
      expect(
        SerenityPalette.forScore(70, palette: ConfidiaPalette.rose),
        ConfidiaPalette.rose.primary,
      );
    });
  });

  group('SerenityPalette helpers', () {
    test('forLevel follows score semantics', () {
      expect(SerenityPalette.forLevel(SerenityLevel.excellent, ConfidiaPalette.blue), SerenityPalette.excellent);
      expect(SerenityPalette.forLevel(SerenityLevel.good, ConfidiaPalette.blue), ConfidiaPalette.blue.primary);
      expect(SerenityPalette.forLevel(SerenityLevel.moderate, ConfidiaPalette.blue), SerenityPalette.moderate);
      expect(SerenityPalette.forLevel(SerenityLevel.attention, ConfidiaPalette.blue), SerenityPalette.attention);
    });

    test('serenityHeadline includes score and optional priorities', () {
      expect(
        SerenityPalette.serenityHeadline(SerenityLevel.good, 72, 0),
        'Bonne sérénité administrative (72/100)',
      );
      expect(
        SerenityPalette.serenityHeadline(SerenityLevel.attention, 40, 2),
        'Sérénité fragile (40/100) · 2 action(s) prioritaire(s)',
      );
    });

    test('calendarLoadLabel reflects busy days', () {
      expect(SerenityPalette.calendarLoadLabel(0), 'agenda plutôt calme');
      expect(SerenityPalette.calendarLoadLabel(2), 'agenda modérément chargé');
      expect(SerenityPalette.calendarLoadLabel(4), 'agenda chargé');
    });
  });
}
