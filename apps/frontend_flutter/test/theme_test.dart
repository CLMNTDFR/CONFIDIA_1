import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:confidia/core/theme/palette.dart';

void main() {
  test('blue palette is the default brand theme', () {
    expect(ConfidiaPalette.blue.primary, const Color(0xFF015AAB));
    expect(ConfidiaPalette.blue.secondary, const Color(0xFF06E5EF));
    expect(ConfidiaPalette.blue.accent, const Color(0xFF3B9AE8));
  });

  test('rose palette preserves legacy brand colors', () {
    expect(ConfidiaPalette.rose.primary, const Color(0xFFD20050));
    expect(ConfidiaPalette.rose.secondary, const Color(0xFFAF73F7));
    expect(ConfidiaPalette.rose.accent, const Color(0xFF4B96B4));
  });
}
