import 'package:confidia/core/theme/palette.dart';
import 'package:confidia/core/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ThemeData instances are cached per palette and brightness', () {
    final a = ConfidiaTheme.dark(ConfidiaPalette.blue);
    final b = ConfidiaTheme.dark(ConfidiaPalette.blue);
    final c = ConfidiaTheme.light(ConfidiaPalette.blue);
    final d = ConfidiaTheme.dark(ConfidiaPalette.rose);

    expect(identical(a, b), isTrue);
    expect(identical(a, c), isFalse);
    expect(identical(a, d), isFalse);
    expect(a.colorScheme.primary, ConfidiaPalette.blue.primary);
    expect(d.colorScheme.primary, ConfidiaPalette.rose.primary);
  });
}
