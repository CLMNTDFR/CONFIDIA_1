import 'package:flutter/material.dart';

import 'palette.dart';

/// Access the current brand palette from any [BuildContext].
extension ConfidiaThemeContext on BuildContext {
  ConfidiaPalette get palette =>
      Theme.of(this).extension<ConfidiaPaletteTheme>()?.palette ?? ConfidiaPalette.blue;
}
