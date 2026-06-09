import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:confidia/core/theme/colors.dart';

void main() {
  test('brand colors are defined correctly', () {
    expect(ConfidiaColors.primary, const Color(0xFFD20050));
    expect(ConfidiaColors.secondary, const Color(0xFFAF73F7));
    expect(ConfidiaColors.accent, const Color(0xFF4B96B4));
  });
}
